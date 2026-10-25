"""
Download a paper for the SMART pipeline, picking the right downloader from its DOI.

    Nature journals (DOI 10.1038/...)  -> download_nature.py  (browser, your login)
    Everything else                    -> download_pubmed.py  (PubMed Central, no login)

If a Nature paper is paywalled for you, it falls back to PubMed Central when
the paper is there.

Accepted inputs:
    10.1016/j.cell.2024.01.001            bare DOI (or doi:10.xxx)
    https://doi.org/10.1016/...           doi.org / dx.doi.org URL
    https://www.nature.com/articles/...   nature.com URL
    38654105  /  PMID:38654105            PMID
    https://pubmed.ncbi.nlm.nih.gov/...   PubMed URL
    PMC5499209                            PMCID
    https://pmc.ncbi.nlm.nih.gov/articles/PMC5499209/   PMC URL

Usage:
    python3 download_paper.py <paper> <output_folder>

Exit code 0 when the paper was downloaded, 1 otherwise.
"""

import re
import shutil
import sys
from pathlib import Path
from urllib.parse import unquote

import requests

import download_pubmed

IDCONV = "https://pmc.ncbi.nlm.nih.gov/tools/idconv/api/v1/articles/"
CTXP = "https://api.ncbi.nlm.nih.gov/lit/ctxp/v1/pubmed/"


# ─────────────────────────────────────────────────────────────
# Input parsing
# ─────────────────────────────────────────────────────────────

def parse_input(raw):
    """Return (kind, value): kind is 'doi', 'pmid' or 'pmcid'."""
    raw = unquote(str(raw).strip())

    m = re.search(r"\b(PMC\d+)\b", raw, re.I)
    if m:
        return "pmcid", m.group(1).upper()

    m = re.search(r"pubmed\.ncbi\.nlm\.nih\.gov/(\d+)", raw)
    if m:
        return "pmid", m.group(1)
    m = re.match(r"PMID\s*:?\s*(\d+)$", raw, re.I)
    if m:
        return "pmid", m.group(1)
    if re.match(r"^\d{5,9}$", raw):
        return "pmid", raw

    m = re.search(r"nature\.com/articles/([\w.-]+)", raw)
    if m:
        return "doi", "10.1038/" + m.group(1)

    m = re.search(r"(10\.\d{4,9}/\S+)", raw)
    if m:
        return "doi", m.group(1).rstrip(".")

    raise ValueError(
        f"Cannot read the paper input: {raw}\n"
        "Give a DOI, PMID, PMCID, or a doi.org / PubMed / PMC / nature.com URL.")


# ─────────────────────────────────────────────────────────────
# ID resolution
# ─────────────────────────────────────────────────────────────

def _idconv(id_):
    """Look up {doi, pmid, pmcid} for any one of them with the NCBI ID converter."""
    try:
        r = requests.get(IDCONV, params={"ids": id_, "format": "json", "tool": "SMART"},
                         headers={"User-Agent": download_pubmed.UA}, timeout=20)
        r.raise_for_status()
        recs = r.json().get("records", [])
    except (requests.RequestException, ValueError) as e:
        print(f"    WARN NCBI ID converter failed: {e}")
        return {}
    if not recs or recs[0].get("status") == "error":
        return {}
    return {k: str(recs[0][k]) for k in ("doi", "pmid", "pmcid") if recs[0].get(k)}


def _pmid_to_doi(pmid):
    """Fallback for PMIDs the ID converter doesn't know (papers not in PMC)."""
    try:
        r = requests.get(CTXP, params={"format": "csl", "id": pmid},
                         headers={"User-Agent": download_pubmed.UA}, timeout=20)
        r.raise_for_status()
        return r.json().get("DOI")
    except (requests.RequestException, ValueError):
        return None


def _pmcid_meta(pmcid):
    """DOI and PMID from the PMC dataset itself (works without the NCBI API)."""
    version = download_pubmed.find_latest_version(pmcid)
    if not version:
        return {}
    try:
        meta = download_pubmed._get(f"{download_pubmed.BUCKET}/{version}/{version}.json").json()
    except (requests.RequestException, ValueError):
        return {}
    ids = {"pmcid": pmcid}
    if meta.get("doi"):
        ids["doi"] = meta["doi"]
    if meta.get("pmid"):
        ids["pmid"] = str(meta["pmid"])
    return ids


def resolve(kind, value):
    """Return a dict with whatever of doi / pmid / pmcid we can find."""
    ids = {kind: value}
    if kind == "pmcid":
        ids.update(_pmcid_meta(value))
    if "doi" not in ids or "pmcid" not in ids:
        ids.update({k: v for k, v in _idconv(value).items() if k not in ids})
    if "doi" not in ids and "pmid" in ids:
        doi = _pmid_to_doi(ids["pmid"])
        if doi:
            ids["doi"] = doi
    return ids


def is_nature(doi):
    return bool(doi) and doi.lower().startswith("10.1038/")


# ─────────────────────────────────────────────────────────────
# Downloaders
# ─────────────────────────────────────────────────────────────

def _download_nature(doi, out):
    """
    Run download_nature.py into a staging folder, then move Inputs/ into out.
    Staging matters: on a paywall download_nature.py deletes its whole output folder.
    """
    import download_nature

    stage = out / "Working" / "_nature_download"
    if stage.exists():
        shutil.rmtree(stage)
    dl = download_nature.NatureDownloader()
    try:
        dl.login()
        status = dl.download(doi, stage)
    finally:
        dl.close()
    if status != "ok":
        shutil.rmtree(stage, ignore_errors=True)
        return status

    inputs = out / "Inputs"
    inputs.mkdir(parents=True, exist_ok=True)
    for item in (stage / "Inputs").iterdir():
        target = inputs / item.name
        if target.is_dir():
            shutil.rmtree(target)
        elif target.exists():
            target.unlink()
        shutil.move(str(item), str(target))
    shutil.rmtree(stage, ignore_errors=True)
    return "ok"


def _download_pmc(ids, out):
    if "pmcid" not in ids:
        return "not_in_pmc"
    return download_pubmed.download(ids["pmcid"], out)


def download(raw, output_dir):
    out = Path(output_dir)
    (out / "Working").mkdir(parents=True, exist_ok=True)

    kind, value = parse_input(raw)
    print(f"  Paper input: {raw}  ->  {kind} {value}")
    ids = resolve(kind, value)
    print("  IDs: " + "  ".join(f"{k}={v}" for k, v in sorted(ids.items())))

    if is_nature(ids.get("doi")):
        print("  Nature journal: using download_nature.py (browser login)\n")
        status = _download_nature(ids["doi"], out)
        if status == "ok":
            return True
        if status == "paywalled":
            print("\n  No access on nature.com. Trying PubMed Central instead...\n")
            if "pmcid" not in ids:
                ids.update({k: v for k, v in _idconv(ids["doi"]).items() if k not in ids})
            if _download_pmc(ids, out) == "ok":
                return True
            print("\n  ERROR: paper is paywalled for you and not in PubMed Central.")
            print("  Log in with an account that has access, or put the files in Inputs/ yourself.")
        else:
            print(f"\n  ERROR: Nature download failed ({status}).")
        return False

    print("  Not a Nature journal: using PubMed Central\n")
    if _download_pmc(ids, out) == "ok":
        return True
    print("\n  ERROR: this paper is not in the PubMed Central open dataset")
    print("  (only open-access papers and NIH author manuscripts are).")
    print("  Put the paper text in Inputs/paper1_text.txt yourself, or use another paper.")
    return False


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    try:
        ok = download(sys.argv[1], sys.argv[2])
    except ValueError as e:
        print(f"  ERROR: {e}")
        ok = False
    sys.exit(0 if ok else 1)
