"""
Download a paper from PubMed Central (PMC) for the SMART pipeline.

Uses the PMC Article Datasets on AWS (https://pmc.ncbi.nlm.nih.gov/tools/pmcaws/):
no login, no browser, no API key. Works for papers in the PMC Open Access
subset and NIH author manuscripts. Writes the same layout as download_nature.py:

    output_folder/
        Inputs/
            paper1.xml            # full JATS XML from PMC
            paper1.pdf            # article PDF, when PMC has one
            paper1_text.txt       # title, abstract and main text (no methods/refs)
            paper1_method.txt     # methods section
            paper1_ref.txt        # references, one per entry
            figures/              # Fig1.jpg, ...
            Captions/             # Fig1.txt, ...
            Supp/                 # supplementary files + index.txt (file -> label)
        Outputs/
        Working/

Usage:
    python3 download_pubmed.py <PMCID> <output_folder>

Normally called by download_paper.py, which turns a DOI / PMID / URL into a PMCID.
"""

import os
import re
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

import requests

BUCKET = "https://pmc-oa-opendata.s3.amazonaws.com"
XLINK = "{http://www.w3.org/1999/xlink}href"
UA = f"SMART-downloader/1.0 (academic TDM; mailto:{os.environ.get('SMART_CONTACT_EMAIL', 'unset')})"

# Elements whose text should not appear inside running text
_SKIP_IN_TEXT = {"fig", "table-wrap", "supplementary-material", "fig-group",
                 "table-wrap-group", "ref-list", "disp-formula-group"}

_METHODS_TITLE = re.compile(
    r"^\s*(online\s+)?(star\W*\s*methods|materials?\s+and\s+methods|methods?\s+and\s+materials?"
    r"|methods?|experimental\s+procedures|methodology)\b", re.I)


# ─────────────────────────────────────────────────────────────
# PMC bucket access
# ─────────────────────────────────────────────────────────────

def _get(url, **kw):
    r = requests.get(url, headers={"User-Agent": UA}, timeout=kw.pop("timeout", 60), **kw)
    r.raise_for_status()
    return r


def _s3_to_https(url):
    """s3://pmc-oa-opendata/KEY?md5=... -> https://pmc-oa-opendata.s3.amazonaws.com/KEY"""
    return re.sub(r"^s3://pmc-oa-opendata/", BUCKET + "/", url.split("?")[0])


def find_latest_version(pmcid):
    """Return the newest version prefix for a PMCID, e.g. 'PMC5499209.2', or None."""
    pmcid = pmcid.upper()
    r = _get(f"{BUCKET}/?list-type=2&prefix={pmcid}.&delimiter=/")
    prefixes = re.findall(r"<Prefix>(PMC\d+\.(\d+))/</Prefix>", r.text)
    prefixes = [(p, int(v)) for p, v in prefixes if p.split(".")[0] == pmcid]
    if not prefixes:
        return None
    return max(prefixes, key=lambda x: x[1])[0]


# ─────────────────────────────────────────────────────────────
# JATS XML helpers
# ─────────────────────────────────────────────────────────────

def _text(el):
    """All text inside an element, skipping figures/tables/supp blocks, whitespace-collapsed."""
    if el is None:
        return ""
    parts = []

    def walk(e):
        if e.tag in _SKIP_IN_TEXT:
            if e.tail:
                parts.append(e.tail)
            return
        if e.text:
            parts.append(e.text)
        for c in e:
            walk(c)
        if e.tail and e is not el:
            parts.append(e.tail)

    walk(el)
    return re.sub(r"\s+", " ", "".join(parts)).strip()


def _sec_title(sec):
    return _text(sec.find("title"))


def _is_methods(sec):
    if "method" in (sec.get("sec-type") or "").lower():
        return True
    return bool(_METHODS_TITLE.match(_sec_title(sec)))


def _render_sec(sec, depth, out):
    """Append a section's headings and paragraphs (recursively) to out."""
    title = _sec_title(sec)
    if title:
        out.append("#" * min(depth, 4) + " " + title)
    for child in sec:
        if child.tag == "p":
            t = _text(child)
            if t:
                out.append(t)
        elif child.tag == "sec":
            _render_sec(child, depth + 1, out)
        elif child.tag == "list":
            for item in child.iter("list-item"):
                t = _text(item)
                if t:
                    out.append("- " + t)


# ─────────────────────────────────────────────────────────────
# Extraction
# ─────────────────────────────────────────────────────────────

def extract_text_and_methods(root):
    """Return (main_text, methods_text)."""
    main, methods = [], []

    title = _text(root.find(".//front/article-meta/title-group/article-title"))
    if title:
        main.append("# " + title)

    for abstract in root.findall(".//front/article-meta/abstract"):
        if abstract.get("abstract-type") in ("graphical", "teaser", "toc"):
            continue
        kind = abstract.get("abstract-type")
        default = {"web-summary": "Summary", "summary": "Summary",
                   "key-points": "Key points"}.get(kind, "Abstract")
        label = _text(abstract.find("title")) or default
        main.append("## " + label)
        for child in abstract:
            if child.tag == "p":
                main.append(_text(child))
            elif child.tag == "sec":
                _render_sec(child, 3, main)

    body = root.find(".//body")
    if body is not None:
        for child in body:
            if child.tag == "sec" and child.get("sec-type") == "supplementary-material":
                continue  # listed in Supp/index.txt instead
            if child.tag == "sec":
                _render_sec(child, 2, methods if _is_methods(child) else main)
            elif child.tag == "p":
                t = _text(child)
                if t:
                    main.append(t)

    # Some journals put the methods in <back>
    back = root.find(".//back")
    if back is not None:
        for sec in back.findall("sec"):
            if _is_methods(sec):
                _render_sec(sec, 2, methods)

    return "\n\n".join(p for p in main if p), "\n\n".join(p for p in methods if p)


def _format_ref(ref):
    """Format one <ref> as 'Authors. Title. Journal Volume, Pages (Year). DOI: ... PMID: ...'."""
    cit = ref.find("element-citation")
    if cit is None:
        cit = ref.find("mixed-citation")
    if cit is None:
        cit = ref.find("nlm-citation")
    if cit is None:
        return _text(ref)

    names = []
    for name in cit.iter("name"):
        surname = _text(name.find("surname"))
        given = _text(name.find("given-names"))
        if surname:
            names.append(f"{surname} {given}".strip())
    for collab in cit.iter("collab"):
        names.append(_text(collab))

    title = _text(cit.find("article-title")) or _text(cit.find("chapter-title"))
    source = _text(cit.find("source"))
    year = _text(cit.find("year"))
    volume = _text(cit.find("volume"))
    fpage = _text(cit.find("fpage")) or _text(cit.find("elocation-id"))
    lpage = _text(cit.find("lpage"))
    ids = {p.get("pub-id-type"): _text(p) for p in cit.iter("pub-id")}

    if not (names or title or source):
        # Unstructured mixed-citation: keep its plain text
        line = _text(cit)
    else:
        authors = ", ".join(names[:10]) + (" et al." if len(names) > 10 else "")
        pages = f"{fpage}-{lpage}" if fpage and lpage else fpage
        where = " ".join(x for x in [source, volume] if x)
        if pages:
            where = f"{where}, {pages}" if where else pages
        if year:
            where = f"{where} ({year})" if where else f"({year})"
        line = ". ".join(x.rstrip(".") for x in [authors, title, where] if x) + "."

    if ids.get("doi") and "doi" not in line.lower():
        line += f" DOI: {ids['doi']}"
    if ids.get("pmid"):
        line += f" PMID: {ids['pmid']}"
    return line


def extract_references(root):
    refs = root.findall(".//back//ref-list/ref")
    lines = []
    for i, ref in enumerate(refs, 1):
        label = _text(ref.find("label")).rstrip(".") or str(i)
        if not label.isdigit():
            label = str(i)
        lines.append(f"{label}. {_format_ref(ref)}")
    return "\n\n".join(lines), len(lines)


def _fig_name(label):
    """'Figure 1' -> 'Fig1', 'Extended Data Fig. 3' -> 'ExtFig3', 'Figure S2' -> 'SuppFig2'."""
    m = re.search(r"(extended\s+data\s+)?fig(?:ure)?\.?\s*(s)?\s*(\d+)", label, re.I)
    if not m:
        return None
    if m.group(1):
        return f"ExtFig{m.group(3)}"
    if m.group(2):
        return f"SuppFig{m.group(3)}"
    return f"Fig{m.group(3)}"


def extract_figures(root):
    """Return a list of {name, caption_lines, href} for every labelled figure."""
    figs, seen = [], set()
    for fig in root.iter("fig"):
        label = _text(fig.find("label"))
        name = _fig_name(label) if label else None
        if not name or name in seen:
            continue
        seen.add(name)
        caption = fig.find("caption")
        cap_title = _text(caption.find("title")) if caption is not None else ""
        heading = f"{label} {cap_title}".strip() if cap_title else label
        lines = [f"**{heading}**"]
        if caption is not None:
            for p in caption.findall("p"):
                t = _text(p)
                if t:
                    lines.append(t)
        graphic = fig.find(".//graphic")
        href = graphic.get(XLINK) if graphic is not None else None
        figs.append({"name": name, "caption_lines": lines, "href": href})
    return figs


def extract_supplements(root):
    """Return a list of {href, label} for each supplementary file named in the XML."""
    items, seen = [], set()
    for supp in root.iter("supplementary-material"):
        label = " ".join(x for x in [_text(supp.find("label")),
                                     _text(supp.find("caption/title"))] if x)
        hrefs = [supp.get(XLINK)] + [m.get(XLINK) for m in supp.iter("media")]
        for href in hrefs:
            if href and href not in seen:
                seen.add(href)
                items.append({"href": href, "label": label or _text(supp.find("caption"))[:150]})
    return items


# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────

def _match_media(href, media_by_name):
    """Find the bucket URL for an XML href; hrefs often omit the file extension."""
    base = os.path.basename(href)
    if base in media_by_name:
        return media_by_name[base]
    stem = os.path.splitext(base)[0]
    for ext in (".jpg", ".png", ".gif", ".tif", ".tiff"):
        if stem + ext in media_by_name:
            return media_by_name[stem + ext]
    return None


def download(pmcid, output_dir):
    """
    Download one PMC paper into output_dir.

    Returns "ok", or "not_in_pmc" when PMC has no copy in its open dataset.
    """
    pmcid = pmcid.upper() if pmcid.upper().startswith("PMC") else f"PMC{pmcid}"
    out = Path(output_dir)
    print(f"{'=' * 60}\n  PMC: {pmcid}\n  Output: {out}\n{'=' * 60}")

    print("\n  [1/6] Finding the article in PMC...")
    prefix = find_latest_version(pmcid)
    if not prefix:
        print(f"    {pmcid} is not in the PMC open dataset (open access or author manuscript).")
        return "not_in_pmc"
    meta = _get(f"{BUCKET}/{prefix}/{prefix}.json").json()
    print(f"    OK {prefix}  license={meta.get('license_code')}  "
          f"manuscript={meta.get('is_manuscript')}")
    if meta.get("is_retracted"):
        print("    WARNING: PMC marks this article as RETRACTED.")

    inputs = out / "Inputs"
    inputs.mkdir(parents=True, exist_ok=True)
    (out / "Outputs").mkdir(exist_ok=True)
    (out / "Working").mkdir(exist_ok=True)

    print("  [2/6] Downloading XML...")
    xml_bytes = _get(_s3_to_https(meta["xml_url"])).content
    (inputs / "paper1.xml").write_bytes(xml_bytes)
    root = ET.fromstring(xml_bytes)
    if meta.get("pdf_url"):
        try:
            (inputs / "paper1.pdf").write_bytes(_get(_s3_to_https(meta["pdf_url"])).content)
        except requests.RequestException as e:
            print(f"    WARN: PDF not downloaded ({e})")

    print("  [3/6] Extracting text, methods and references...")
    main_text, methods = extract_text_and_methods(root)
    (inputs / "paper1_text.txt").write_text(main_text, encoding="utf-8")
    print(f"    OK paper1_text.txt ({len(main_text.split())} words)")
    if methods:
        (inputs / "paper1_method.txt").write_text(methods, encoding="utf-8")
        print(f"    OK paper1_method.txt ({len(methods.split())} words)")
    else:
        print("    WARN: no Methods section found (it may be in the supplement)")
    refs, n_refs = extract_references(root)
    if refs:
        (inputs / "paper1_ref.txt").write_text(refs, encoding="utf-8")
        print(f"    OK paper1_ref.txt ({n_refs} references)")
    else:
        print("    WARN: no references found")

    media_by_name = {os.path.basename(_s3_to_https(u)): _s3_to_https(u)
                     for u in meta.get("media_urls", [])}

    print("  [4/6] Writing figure captions...")
    figs = extract_figures(root)
    cap_dir = inputs / "Captions"
    if figs:
        cap_dir.mkdir(exist_ok=True)
    for f in figs:
        (cap_dir / f"{f['name']}.txt").write_text("\n".join(f["caption_lines"]), encoding="utf-8")
    print(f"    OK {len(figs)} captions")

    print("  [5/6] Downloading figures...")
    fig_dir = inputs / "figures"
    n_figs = 0
    for f in figs:
        url = _match_media(f["href"], media_by_name) if f["href"] else None
        if not url:
            continue
        fig_dir.mkdir(exist_ok=True)
        ext = os.path.splitext(url)[1] or ".jpg"
        (fig_dir / f"{f['name']}{ext}").write_bytes(_get(url).content)
        n_figs += 1
        time.sleep(0.2)
    print(f"    OK {n_figs} figures" + ("" if n_figs or not figs else
                                       " (PMC has no images for this article's license)"))

    print("  [6/6] Downloading supplementary files...")
    supp_dir = inputs / "Supp"
    index = []
    for item in extract_supplements(root):
        url = media_by_name.get(os.path.basename(item["href"]))
        if not url:
            continue
        supp_dir.mkdir(exist_ok=True)
        fname = os.path.basename(url)
        (supp_dir / fname).write_bytes(_get(url, timeout=300).content)
        index.append(f"{fname}\t{item['label']}")
        print(f"    OK {fname}  {item['label'][:60]}")
        time.sleep(0.2)
    if index:
        (supp_dir / "index.txt").write_text("\n".join(index) + "\n", encoding="utf-8")
    print(f"    OK {len(index)} supplementary files")

    print(f"\n  Done: text=Y  method={'Y' if methods else 'N'}  refs={n_refs}  "
          f"figures={n_figs}  captions={len(figs)}  supplements={len(index)}\n")
    return "ok"


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    status = download(sys.argv[1], sys.argv[2])
    sys.exit(0 if status == "ok" else 2)
