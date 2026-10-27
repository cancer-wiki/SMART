"""
Download Nature journal articles for downstream scRNA-seq transfer analysis.

Supports all Nature sub-journals (Nature, Nature Medicine, Nature Cancer,
Nature Communications, Nature Genetics, etc.).

Accepted input formats:
    - DOI:          10.1038/s41586-024-07238-z
    - doi.org URL:  https://doi.org/10.1038/s41586-024-07238-z
    - nature.com:   https://www.nature.com/articles/s41586-024-07238-z
    - PMID:         38654105
    - PubMed URL:   https://pubmed.ncbi.nlm.nih.gov/38654105/

Usage:
    from download_nature import NatureDownloader

    # Single paper (any format)
    dl = NatureDownloader(browser="firefox")
    dl.login()
    dl.download("10.1038/s41586-024-07238-z", "/path/to/output_folder")
    dl.download("38654105", "/path/to/output_folder2")       # PMID
    dl.close()

    # Batch
    dl = NatureDownloader(browser="firefox")
    dl.login()
    papers = [
        ("10.1038/s41586-024-07238-z", "/path/to/paper1"),
        ("https://pubmed.ncbi.nlm.nih.gov/38654105/", "/path/to/paper2"),
    ]
    dl.batch_download(papers)
    dl.close()

Output folder structure:
    output_folder/
        Inputs/
            article.html          # full HTML
            paper1_text.txt       # main text (no methods/refs)
            paper1_method.txt     # methods section
            paper1_ref.txt        # references
            figures/              # Fig1.png, ExtFig1.jpg, ...
            Captions/             # Fig1.txt, ExtFig1.txt, ...
            Supp/                 # supplementary files
        Outputs/                  # empty, for downstream analysis
        Working/                  # empty, for downstream analysis

Requirements:
    pip install selenium requests beautifulsoup4 webdriver-manager pillow
    # Plus one of: Firefox, Chrome, or Chromium installed

Terms of use:
    - Requires legitimate access (institutional/personal subscription or open access)
    - Non-commercial academic research only
    - Do not redistribute downloaded content
    - Do not remove or reduce built-in rate limits
    - See README.md for full terms
"""

import os
import re
import io
import time
import requests
from pathlib import Path
from urllib.parse import urlparse

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

_UA = f"SMART-downloader/1.0 (academic TDM; mailto:{os.environ.get('SMART_CONTACT_EMAIL', 'unset')})"


# ─────────────────────────────────────────────────────────────
# PMID resolution
# ─────────────────────────────────────────────────────────────

def _pmid_to_doi(pmid):
    """Resolve a PubMed ID to a DOI using the NCBI literature citation API."""
    pmid = str(pmid).strip()
    url = f"https://api.ncbi.nlm.nih.gov/lit/ctxp/v1/pubmed/?format=csl&id={pmid}"
    try:
        resp = requests.get(url, headers={"User-Agent": _UA}, timeout=15)
        resp.raise_for_status()
        data = resp.json()
        doi = data.get("DOI", "")
        if not doi:
            raise ValueError(f"PMID {pmid}: no DOI found in PubMed record")
        return doi
    except requests.exceptions.RequestException as e:
        raise ValueError(f"PMID {pmid}: NCBI API request failed: {e}")
    except (KeyError, ValueError) as e:
        raise ValueError(str(e))


def _extract_pmid(raw):
    """Extract a PMID from various PubMed formats. Returns None if not PubMed."""
    raw = raw.strip()
    # PubMed URL: https://pubmed.ncbi.nlm.nih.gov/38654105/
    m = re.search(r"pubmed\.ncbi\.nlm\.nih\.gov/(\d+)", raw)
    if m:
        return m.group(1)
    # Explicit PMID prefix: PMID: 38654105 or PMID:38654105
    m = re.match(r"PMID\s*:?\s*(\d+)$", raw, re.I)
    if m:
        return m.group(1)
    # Bare number (5-9 digits, typical PMID range)
    if re.match(r"^\d{5,9}$", raw):
        return raw
    return None


# ─────────────────────────────────────────────────────────────
# Input parsing
# ─────────────────────────────────────────────────────────────

def _parse_input(raw):
    """
    Accept DOI, doi.org URL, nature.com URL, PMID, or PubMed URL.
    Return (doi, nature_url).
    Raises ValueError if the paper is not from a Nature journal.
    """
    raw = str(raw).strip()

    # Try PubMed formats first
    pmid = _extract_pmid(raw)
    if pmid:
        print(f"    Resolving PMID {pmid} via NCBI API...")
        doi = _pmid_to_doi(pmid)
        print(f"    -> DOI: {doi}")
        if not doi.startswith("10.1038/"):
            raise ValueError(
                f"PMID {pmid} resolves to DOI {doi} which is NOT a Nature journal. "
                f"This downloader only supports Nature sub-journals (10.1038/*).")
        return doi, _resolve_doi(doi)

    # nature.com URL
    if "nature.com/articles/" in raw:
        url = raw if raw.startswith("http") else f"https://{raw}"
        m = re.search(r"articles/(s\d+-\d+-\d+-[\w.-]+)", raw)
        doi = f"10.1038/{m.group(1)}" if m else None
        return doi, url

    # doi.org URL
    if "doi.org/" in raw:
        doi = re.sub(r"^https?://doi\.org/", "", raw)
        if not doi.startswith("10.1038/"):
            raise ValueError(
                f"DOI {doi} is NOT a Nature journal. "
                f"This downloader only supports Nature sub-journals (10.1038/*).")
        return doi, _resolve_doi(doi)

    # Bare DOI
    if raw.startswith("10."):
        if not raw.startswith("10.1038/"):
            raise ValueError(
                f"DOI {raw} is NOT a Nature journal. "
                f"This downloader only supports Nature sub-journals (10.1038/*).")
        return raw, _resolve_doi(raw)

    raise ValueError(
        f"Cannot parse input: {raw}\n"
        f"Accepted formats: DOI, doi.org URL, nature.com URL, PMID, PubMed URL")


def _resolve_doi(doi):
    try:
        r = requests.head(f"https://doi.org/{doi}", allow_redirects=True,
                          timeout=15, headers={"User-Agent": _UA})
        return r.url
    except Exception:
        return f"https://doi.org/{doi}"


# ─────────────────────────────────────────────────────────────
# Browser setup
# ─────────────────────────────────────────────────────────────

def _find_firefox_profile():
    """Find the default Firefox profile directory."""
    fdir = os.path.expanduser("~/.mozilla/firefox")
    if not os.path.isdir(fdir):
        return None
    for entry in sorted(os.listdir(fdir)):
        full = os.path.join(fdir, entry)
        if os.path.isdir(full) and ("default-release" in entry or "default" in entry):
            return full
    return None


def _build_driver(browser="firefox", use_profile=True):
    """Create a Selenium WebDriver for the specified browser."""
    browser = browser.lower().strip()

    if browser == "firefox":
        from selenium.webdriver.firefox.service import Service as FfService
        from selenium.webdriver.firefox.options import Options as FfOptions
        from webdriver_manager.firefox import GeckoDriverManager

        svc = FfService(GeckoDriverManager().install())

        # Try with existing profile first (carries over cookies/logins)
        if use_profile:
            profile = _find_firefox_profile()
            if profile:
                try:
                    opts = FfOptions()
                    print(f"  Using Firefox profile: {profile}")
                    opts.add_argument("-profile")
                    opts.add_argument(profile)
                    return webdriver.Firefox(service=svc, options=opts)
                except Exception as e:
                    print(f"  Could not use existing profile ({e})")
                    print(f"  Starting with a fresh profile instead.")
                    print(f"  (Close Firefox if you want to reuse your existing profile.)")
                    svc = FfService(GeckoDriverManager().install())

        # Fallback: fresh profile
        opts = FfOptions()
        return webdriver.Firefox(service=svc, options=opts)

    elif browser in ("chrome", "chromium"):
        from selenium.webdriver.chrome.service import Service as CrService
        from selenium.webdriver.chrome.options import Options as CrOptions
        from webdriver_manager.chrome import ChromeDriverManager

        opts = CrOptions()
        opts.add_argument("--start-maximized")
        if use_profile:
            home = os.path.expanduser("~")
            chrome_data = os.path.join(home, ".config", "google-chrome")
            if os.path.isdir(chrome_data):
                print(f"  Using Chrome profile: {chrome_data}")
                opts.add_argument(f"--user-data-dir={chrome_data}")
        svc = CrService(ChromeDriverManager().install())
        return webdriver.Chrome(service=svc, options=opts)

    elif browser == "edge":
        from selenium.webdriver.edge.service import Service as EdService
        from selenium.webdriver.edge.options import Options as EdOptions
        from webdriver_manager.microsoft import EdgeChromiumDriverManager

        opts = EdOptions()
        opts.add_argument("--start-maximized")
        svc = EdService(EdgeChromiumDriverManager().install())
        return webdriver.Edge(service=svc, options=opts)

    else:
        raise ValueError(f"Unsupported browser: {browser}. Use 'firefox', 'chrome', or 'edge'.")


# ─────────────────────────────────────────────────────────────
# Figure helpers
# ─────────────────────────────────────────────────────────────

def _norm_fig_url(u):
    """Upgrade Nature image URL to full resolution."""
    u = re.sub(r"[?&]w=\d+", "", u)
    u = re.sub(r"[?&]h=\d+", "", u)
    for low in ["/lw400/", "/lw800/", "/lw1200/", "/m685/", "/w400/", "/w800/"]:
        u = u.replace(low, "/full/")
    return u


def _collect_fig_links(driver):
    """Find all main and extended-data figure page links on the article page.

    Nature uses sequential URL numbering: main figs /figures/1..N, extended
    /figures/(N+1)..M. But link text says "Extended Data Fig. 1" etc.
    We use the text-based number for filenames and track which URL numbers
    are extended so we don't also save them as main figures.
    """
    main, ext = [], []
    seen_urls = set()
    ext_url_nums = set()  # URL figure numbers that belong to extended data

    for elem in driver.find_elements(By.CSS_SELECTOR, "a[href*='/figures/']"):
        href = elem.get_attribute("href")
        if not href or href in seen_urls:
            continue
        seen_urls.add(href)

        # URLs with explicit extended-data path (rare but possible)
        em = re.search(r"/figures/extended[-_]?data[-_/]*(?:fig)?(\d+)", href, re.I)
        if em:
            fn = em.group(1)
            if fn not in [f[0] for f in ext]:
                ext.append((fn, href))
            continue

        # Get URL figure number
        m = re.search(r"/figures/(\d+)", href)
        if not m:
            continue
        url_num = m.group(1)

        # Get context text from the link and its parent
        try:
            ctx = (elem.text or "").lower()
            ctx += " " + (elem.find_element(By.XPATH, "..").text or "").lower()
        except Exception:
            ctx = ""

        if "extended" in ctx:
            # Extended data figure — extract display number from text
            ext_m = re.search(r"extended\s+data\s+fig\.?\s*(\d+)", ctx, re.I)
            fn = ext_m.group(1) if ext_m else url_num
            ext_url_nums.add(url_num)
            if fn not in [f[0] for f in ext]:
                ext.append((fn, href))
        else:
            fn = url_num
            if fn not in [f[0] for f in main]:
                main.append((fn, href))

    # Remove from main any figures whose URL number is an extended figure
    # (catches "Full size image" links that lack "extended" in context text)
    main = [(fn, url) for fn, url in main
            if re.search(r"/figures/(\d+)", url).group(1) not in ext_url_nums]

    return main, ext


def _get_cookies(driver):
    jar = requests.cookies.RequestsCookieJar()
    for c in driver.get_cookies():
        jar.set(c["name"], c["value"],
                domain=c.get("domain"), path=c.get("path", "/"))
    return jar


def _download_one_figure(driver, fig_url, out_dir, prefix, fig_num, cookies):
    """Download a single figure image at highest resolution."""
    for e in ("png", "jpg", "jpeg", "gif", "webp"):
        if (out_dir / f"{prefix}{fig_num}.{e}").exists():
            print(f"      skip {prefix}{fig_num} (exists)")
            return True

    try:
        for attempt in range(1, 5):
            driver.set_page_load_timeout(60)
            try:
                driver.get(fig_url)
                break
            except Exception:
                time.sleep(5 * attempt)
        else:
            print(f"      FAIL {prefix}{fig_num}: page load timeout")
            return False

        time.sleep(2)
        try:
            WebDriverWait(driver, 15).until(
                EC.presence_of_element_located((By.TAG_NAME, "img")))
        except Exception:
            print(f"      FAIL {prefix}{fig_num}: no images on page")
            return False

        candidates = []
        for img in driver.find_elements(By.TAG_NAME, "img"):
            src = img.get_attribute("src")
            if not src:
                continue
            if any(x in src.lower() for x in
                   ["logo", "icon", "header", "footer", "banner", "avatar"]):
                continue
            try:
                w, h = img.size["width"], img.size["height"]
                if w < 200 or h < 200:
                    continue
                candidates.append({
                    "src": src, "area": w * h,
                    "srcset": img.get_attribute("srcset")
                })
            except Exception:
                continue

        if not candidates:
            print(f"      FAIL {prefix}{fig_num}: no suitable images")
            return False

        candidates.sort(key=lambda x: x["area"], reverse=True)
        best = candidates[0]
        img_url = best["src"]

        if best["srcset"]:
            srcs = re.findall(r"(https?://[^\s,]+)\s+(\d+)w", best["srcset"])
            if srcs:
                srcs.sort(key=lambda x: int(x[1]), reverse=True)
                img_url = srcs[0][0]
        img_url = _norm_fig_url(img_url)

        headers = {"User-Agent": _UA, "Referer": fig_url}
        resp = None
        for att in range(1, 6):
            try:
                resp = requests.get(img_url, headers=headers,
                                    cookies=cookies, timeout=(15, 120))
                if resp.status_code == 200:
                    break
                if resp.status_code in {500, 502, 503, 504, 408, 429}:
                    time.sleep(5 * att)
                else:
                    break
            except (requests.exceptions.Timeout,
                    requests.exceptions.ConnectionError):
                time.sleep(5 * att)

        if not resp or resp.status_code != 200 or len(resp.content) < 20_000:
            print(f"      FAIL {prefix}{fig_num}: download error")
            return False

        ct = resp.headers.get("content-type", "").lower()
        ext = ("png" if "png" in ct else
               "gif" if "gif" in ct else
               "webp" if "webp" in ct else "jpg")
        fp = out_dir / f"{prefix}{fig_num}.{ext}"
        fp.write_bytes(resp.content)

        dims = ""
        try:
            from PIL import Image
            im = Image.open(io.BytesIO(resp.content))
            dims = f"  {im.width}x{im.height}px"
        except Exception:
            pass
        print(f"      OK {fp.name} ({len(resp.content)/1024:.0f} KB){dims}")
        time.sleep(1)
        return True
    except Exception as e:
        print(f"      FAIL {prefix}{fig_num}: {e}")
        return False


def _download_figures(driver, article_url, fig_dir):
    """Download all main + extended-data figures from the article."""
    fig_dir.mkdir(parents=True, exist_ok=True)

    driver.get(article_url)
    time.sleep(4)
    try:
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(2)
        driver.execute_script("window.scrollTo(0, 0);")
        time.sleep(1)
    except Exception:
        pass

    cookies = _get_cookies(driver)
    main_figs, ext_figs = _collect_fig_links(driver)
    print(f"    Found {len(main_figs)} main + {len(ext_figs)} extended figures")

    for i, (fn, fu) in enumerate(main_figs, 1):
        print(f"    [{i}/{len(main_figs)}] Fig{fn}")
        _download_one_figure(driver, fu, fig_dir, "Fig", fn, cookies)
        time.sleep(2)

    for i, (fn, fu) in enumerate(ext_figs, 1):
        if i % 5 == 1 and i > 1:
            try:
                cookies = _get_cookies(driver)
            except Exception:
                pass
        print(f"    [{i}/{len(ext_figs)}] ExtFig{fn}")
        _download_one_figure(driver, fu, fig_dir, "ExtFig", fn, cookies)
        time.sleep(2)


# ─────────────────────────────────────────────────────────────
# Supplement download
# ─────────────────────────────────────────────────────────────

def _download_supplements(html_path, supp_dir):
    """Parse the article HTML and download all supplementary files."""
    with open(html_path, "r", encoding="utf-8", errors="replace") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    sec = None
    for tag in soup.find_all(["h2", "h3", "h4"]):
        if re.search(r"supplementary\s+information", tag.get_text(), re.I):
            sec = tag.find_parent("section") or tag.find_parent("div")
            break
    if not sec:
        sec = soup.find("section",
                        attrs={"data-title": re.compile(r"supplementary", re.I)})
    if not sec:
        sec = soup.find("div", id=re.compile(r"supplementary", re.I))
    if not sec:
        sec = soup

    items, seen = [], set()
    for a in sec.find_all("a", href=True):
        href = a["href"]
        text = re.sub(r"[\u2193\u2b07\ufe0f]", "",
                      a.get_text(separator=" ", strip=True)).strip()
        text = re.sub(r"\s*\(download.*?\)", "", text, flags=re.I).strip()

        is_supp = bool(re.search(r"MOESM|static-content|ESM\d|supp", href, re.I))
        is_supp = is_supp or bool(
            re.search(r"\.(pdf|xlsx|xls|docx|doc|zip|csv|txt|mp4)\b", href, re.I))
        is_supp = is_supp or "supplement" in (
            a.get("data-track-label") or "").lower()
        if not is_supp:
            continue
        if "/figures/" in href and not re.search(r"MOESM|supp|ESM", href, re.I):
            continue
        if not text or len(text) < 3:
            m = re.search(r"MOESM(\d+)", href, re.I)
            text = f"Supplement_{m.group(1)}" if m else "Supplement"
        if href.startswith("//"):
            href = "https:" + href
        elif href.startswith("/"):
            href = "https://www.nature.com" + href
        if href in seen:
            continue
        seen.add(href)
        items.append({"url": href, "name": text})

    if not items:
        print("    No supplementary files found")
        return 0

    supp_dir.mkdir(parents=True, exist_ok=True)
    print(f"    Found {len(items)} supplementary file(s)")
    saved = 0
    for i, item in enumerate(items, 1):
        print(f"    [{i}/{len(items)}] {item['name'][:70]}")
        try:
            resp = requests.get(item["url"], headers={"User-Agent": _UA},
                                timeout=60, allow_redirects=True)
            resp.raise_for_status()
        except Exception as e:
            print(f"      FAIL: {e}")
            continue

        ext = None
        # 1) Try Content-Disposition filename
        cd = resp.headers.get("Content-Disposition", "")
        if cd:
            m = re.search(r"filename[*]?=[\"']?([^\"';\n]+)", cd)
            if m:
                em = re.search(r"\.(\w+)$", m.group(1))
                if em:
                    ext = em.group(1).lower()
        # 2) Try Content-Type MIME
        if not ext:
            ct = resp.headers.get("Content-Type", "").lower()
            for mime, e in {
                "application/pdf": "pdf",
                "spreadsheetml.sheet": "xlsx", "ms-excel": "xls",
                "wordprocessingml": "docx", "msword": "doc",
                "text/csv": "csv", "text/plain": "txt",
                "application/zip": "zip", "video/mp4": "mp4",
            }.items():
                if mime in ct:
                    ext = e
                    break
        # 3) Try URL extension
        if not ext:
            url_ext_m = re.search(r"\.(\w{2,5})(?:\?|$)", item["url"].split("/")[-1])
            if url_ext_m and url_ext_m.group(1).lower() in {
                "pdf", "xlsx", "xls", "docx", "doc", "csv", "txt",
                "zip", "gz", "tar", "mp4", "png", "jpg", "tif", "tiff"
            }:
                ext = url_ext_m.group(1).lower()
        # 4) Check file magic bytes
        if not ext and len(resp.content) >= 4:
            header = resp.content[:4]
            if header[:4] == b"PK\x03\x04":
                ext = "zip"
            elif header[:4] == b"%PDF":
                ext = "pdf"
            elif header[:2] == b"\x1f\x8b":
                ext = "gz"
        # 5) Final fallback
        if not ext:
            ext = "pdf"

        clean = re.sub(r"[^A-Za-z0-9._-]", "_", item["name"])
        clean = re.sub(r"_+", "_", clean).strip("_") or "Supplement"
        fp = supp_dir / f"{clean}.{ext}"
        c = 1
        while fp.exists():
            fp = supp_dir / f"{clean}_{c}.{ext}"
            c += 1
        ct = resp.headers.get("Content-Type", "").lower()
        if "text/html" in ct and len(resp.content) < 50_000:
            print(f"      SKIP: got HTML redirect instead of file")
            continue

        fp.write_bytes(resp.content)
        kb = len(resp.content) / 1024
        size_str = (f"{kb/1024:.1f} MB" if kb > 1024 else f"{kb:.0f} KB")
        print(f"      OK {fp.name} ({size_str})")
        saved += 1
        time.sleep(1)
    return saved


# ─────────────────────────────────────────────────────────────
# Text extraction from HTML
# ─────────────────────────────────────────────────────────────

_SECTIONS_TO_REMOVE = [
    "Similar content being viewed by others",
    "References", "Acknowledgements", "Author information",
    "Ethics declarations", "Peer review", "Rights and permissions",
    "About this article", "This article is cited by",
    "Associated content", "Extended data figures and tables", "Methods",
]


def _extract_main_text(html_path, output_path):
    """Extract main body text (excluding methods/refs) from article HTML."""
    with open(html_path, "r", encoding="utf-8", errors="replace") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    for name in _SECTIONS_TO_REMOVE:
        h = soup.find(["h1", "h2", "h3", "h4"],
                       string=re.compile(rf"^{re.escape(name)}$", re.I))
        if h:
            p = h.find_parent("section") or h.find_parent("div")
            if p:
                p.decompose()
            else:
                h.decompose()

    article = soup.find("article") or soup.find("div", class_="c-article-body")
    if not article:
        print("    FAIL: no article element found for text extraction")
        return False

    for fig in article.find_all("figure"):
        if fig.find(["img", "picture", "svg"]):
            fig.decompose()

    elements = article.find_all(["h1", "h2", "h3", "h4", "p"])
    parts = []
    for el in elements:
        content = el.get_text().strip()
        if content:
            prefix = {"h1": "# ", "h2": "## ", "h3": "### ",
                       "h4": "#### "}.get(el.name, "")
            parts.append(f"{prefix}{content}")

    text = "\n\n".join(parts)
    if len(text) < 500:
        print(f"    FAIL: extracted text too short ({len(text)} chars)")
        return False

    output_path.write_text(text, encoding="utf-8")
    print(f"    OK paper1_text.txt ({len(text.split())} words)")
    return True


def _extract_methods(html_path, output_path):
    """Extract the Methods section from article HTML."""
    with open(html_path, "r", encoding="utf-8", errors="replace") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    methods_heading = soup.find(
        ["h1", "h2", "h3", "h4"],
        string=re.compile(
            r"^Methods$|^Materials and [Mm]ethods$|^METHODS$|^Online [Mm]ethods$",
            re.I))

    if not methods_heading:
        print("    WARN: no Methods section found")
        return False

    methods_section = (methods_heading.find_parent("section")
                       or methods_heading.find_parent("div"))
    if not methods_section:
        print("    WARN: Methods heading found but no parent section")
        return False

    elements = methods_section.find_all(["h1", "h2", "h3", "h4", "p"])
    parts = []
    for el in elements:
        content = el.get_text().strip()
        if content:
            prefix = {"h1": "# ", "h2": "## ", "h3": "### ",
                       "h4": "#### "}.get(el.name, "")
            parts.append(f"{prefix}{content}")

    text = "\n\n".join(parts)
    if len(text) < 200:
        print(f"    WARN: Methods too short ({len(text)} chars)")
        return False

    output_path.write_text(text, encoding="utf-8")
    print(f"    OK paper1_method.txt ({len(text.split())} words)")
    return True


def _extract_references(html_path, output_path):
    """Extract the References section from article HTML."""
    with open(html_path, "r", encoding="utf-8", errors="replace") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    refs_heading = soup.find(
        ["h1", "h2", "h3", "h4"],
        string=re.compile(r"^References$", re.I))

    if not refs_heading:
        print("    WARN: no References section found")
        return False

    refs_section = (refs_heading.find_parent("section")
                    or refs_heading.find_parent("div"))
    if not refs_section:
        print("    WARN: References heading found but no parent section")
        return False

    parts = []
    for li in refs_section.find_all("li", class_=re.compile(r"c-article-references__item|u-custom-list-number")):
        num_elem = li.find("span", class_=re.compile(r"c-article-references__counter"))
        num = num_elem.get_text(strip=True).rstrip(".") if num_elem else ""

        text = li.get_text(separator=" ", strip=True)
        if num and text.startswith(num):
            text = text[len(num):].lstrip(". ")
        prefix = f"{num}. " if num else ""
        parts.append(f"{prefix}{text}")

    if not parts:
        for li in refs_section.find_all("li"):
            text = li.get_text(separator=" ", strip=True)
            if text:
                parts.append(text)

    if not parts:
        for p in refs_section.find_all("p"):
            text = p.get_text(separator=" ", strip=True)
            if text:
                parts.append(text)

    if not parts:
        print("    WARN: References section found but no entries extracted")
        return False

    text = "\n\n".join(parts)
    output_path.write_text(text, encoding="utf-8")
    print(f"    OK paper1_ref.txt ({len(parts)} references)")
    return True


# ─────────────────────────────────────────────────────────────
# Caption extraction
# ─────────────────────────────────────────────────────────────

def _extract_captions(html_path, captions_dir):
    """Extract individual figure captions into separate text files."""
    with open(html_path, "r", encoding="utf-8", errors="replace") as f:
        soup = BeautifulSoup(f.read(), "html.parser")

    captions_dir.mkdir(parents=True, exist_ok=True)
    n_main, n_ext = 0, 0

    # Main figures
    for fig_div in soup.find_all("div", class_="c-article-section__figure"):
        lines = []
        fig_num = None
        title_elem = fig_div.find("b", class_="c-article-section__figure-caption")
        if title_elem:
            title_text = title_elem.get_text(separator=" ", strip=True)
            lines.append(f"**{title_text}**")
            m = re.search(r"Fig\.?\s*(\d+)|Figure\s*(\d+)", title_text, re.I)
            if m:
                fig_num = m.group(1) or m.group(2)

        desc_div = fig_div.find("div",
                                class_="c-article-section__figure-description")
        if desc_div:
            for p in desc_div.find_all("p"):
                text = p.get_text(separator=" ", strip=True)
                if text and not text.startswith("Source data"):
                    lines.append(text)

        if lines and fig_num:
            (captions_dir / f"Fig{fig_num}.txt").write_text(
                "\n".join(lines), encoding="utf-8")
            n_main += 1

    # Extended data figures
    for supp_item in soup.find_all("div", class_="c-article-supplementary__item"):
        title_link = supp_item.find("a", class_="print-link")
        if not title_link:
            continue
        title_text = title_link.get_text(separator=" ", strip=True)
        if "Extended Data Fig" not in title_text:
            continue
        if title_text.startswith("Source Data"):
            continue

        lines = [f"**{title_text}**"]
        ext_match = re.search(r"Extended Data Fig\.?\s*(\d+)", title_text, re.I)
        ext_num = ext_match.group(1) if ext_match else None

        desc_div = supp_item.find(
            "div", class_="c-article-supplementary__description")
        if desc_div:
            for p in desc_div.find_all("p"):
                text = p.get_text(separator=" ", strip=True)
                if text and not text.startswith("Source data"):
                    lines.append(text)

        if lines and ext_num:
            (captions_dir / f"ExtFig{ext_num}.txt").write_text(
                "\n".join(lines), encoding="utf-8")
            n_ext += 1

    print(f"    OK Captions: {n_main} main + {n_ext} extended")
    return n_main + n_ext


# ─────────────────────────────────────────────────────────────
# Main downloader class
# ─────────────────────────────────────────────────────────────

def _is_paywalled(html_path):
    """Check if a downloaded HTML page is paywalled (no full text access)."""
    with open(html_path, "r", encoding="utf-8", errors="replace") as f:
        html = f.read()

    has_access_wall = "Access options" in html
    has_article = bool(re.search(r'class="c-article-body"', html))
    has_abstract = "Abstract" in html

    if has_access_wall and not has_article:
        return True
    if len(html) < 50_000 and not has_abstract:
        return True

    soup = BeautifulSoup(html, "html.parser")
    article = soup.find("article") or soup.find("div", class_="c-article-body")
    if not article:
        return True

    paragraphs = article.find_all("p")
    total_text = sum(len(p.get_text()) for p in paragraphs)
    if total_text < 2000:
        return True

    return False


class NatureDownloader:
    """
    Download Nature journal articles with a single browser login.

    Accepts: DOI, doi.org URL, nature.com URL, PMID, or PubMed URL.

    Example:
        dl = NatureDownloader(browser="firefox")
        dl.login()
        dl.download("10.1038/s41586-024-07238-z", "my_paper")
        dl.download("38654105", "my_paper2")    # PMID
        dl.close()

    Batch from CSV:
        dl = NatureDownloader(browser="firefox")
        dl.login()
        dl.batch_download_from_csv("papers.csv", output_dir="./downloads")
        dl.close()
    """

    def __init__(self, browser="firefox"):
        self.browser_name = browser
        self.driver = None

    def login(self):
        """Open a browser window for you to log in to nature.com."""
        print(f"\nStarting {self.browser_name}...")
        print("  If you have an existing browser session open with the same")
        print("  profile, please close it first.\n")

        self.driver = _build_driver(self.browser_name, use_profile=True)
        try:
            self.driver.maximize_window()
        except Exception:
            pass

        self.driver.get("https://www.nature.com/")
        time.sleep(2)

        print("=" * 60)
        print("  A browser window has opened at nature.com.")
        print("  Please log in with your institutional or personal account.")
        print("  Once you can see full article text, come back here.")
        print("=" * 60)
        input("\nPress Enter when you are logged in... ")
        print("Ready to download.\n")

    def download(self, doi_or_url, output_dir):
        """
        Download one paper: HTML, text, methods, refs, figures, captions, supplements.

        Args:
            doi_or_url: DOI, doi.org URL, nature.com URL, PMID, or PubMed URL
            output_dir: path where the folder structure will be created

        Returns:
            "ok"        - downloaded successfully
            "paywalled" - no access, skipped
            "error"     - failed for other reasons
        """
        if self.driver is None:
            raise RuntimeError("Call .login() first.")

        doi, article_url = _parse_input(doi_or_url)
        out = Path(output_dir)

        # Create folder structure
        inputs_dir = out / "Inputs"
        inputs_dir.mkdir(parents=True, exist_ok=True)
        (out / "Outputs").mkdir(exist_ok=True)
        (out / "Working").mkdir(exist_ok=True)

        fig_dir = inputs_dir / "figures"
        captions_dir = inputs_dir / "Captions"
        supp_dir = inputs_dir / "Supp"
        html_path = inputs_dir / "paper1.html"

        print(f"{'=' * 60}")
        print(f"  DOI: {doi}")
        print(f"  URL: {article_url}")
        print(f"  Output: {out}")
        print(f"{'=' * 60}")

        # Step 1: Download HTML
        print("\n  [1/7] Downloading HTML...")
        self.driver.get(article_url)
        time.sleep(5)
        html = self.driver.page_source
        html_path.write_text(html, encoding="utf-8")
        print(f"    OK paper1.html ({len(html):,} bytes)")

        # Step 2: Check for paywall
        print("  [2/7] Checking access...")
        if _is_paywalled(html_path):
            print("    PAYWALLED: No full-text access. Skipping this paper.")
            import shutil
            shutil.rmtree(out)
            return "paywalled"
        print("    OK full text accessible")

        # Step 3: Extract main text
        print("  [3/7] Extracting main text...")
        _extract_main_text(html_path, inputs_dir / "paper1_text.txt")

        # Step 4: Extract methods
        print("  [4/7] Extracting methods...")
        _extract_methods(html_path, inputs_dir / "paper1_method.txt")

        # Step 5: Extract references
        print("  [5/7] Extracting references...")
        _extract_references(html_path, inputs_dir / "paper1_ref.txt")

        # Step 6: Download figures
        print("  [6/7] Downloading figures...")
        _download_figures(self.driver, article_url, fig_dir)

        # Step 6b: Extract captions
        print("  [6b/7] Extracting captions...")
        _extract_captions(html_path, captions_dir)

        # Step 7: Download supplements
        print("  [7/7] Downloading supplements...")
        _download_supplements(html_path, supp_dir)

        # Summary
        n_figs = len(list(fig_dir.iterdir())) if fig_dir.exists() else 0
        n_caps = len(list(captions_dir.iterdir())) if captions_dir.exists() else 0
        n_supp = len(list(supp_dir.iterdir())) if supp_dir.exists() else 0
        has_text = (inputs_dir / "paper1_text.txt").exists()
        has_meth = (inputs_dir / "paper1_method.txt").exists()
        has_refs = (inputs_dir / "paper1_ref.txt").exists()

        print(f"\n  Done: text={'Y' if has_text else 'N'}  "
              f"method={'Y' if has_meth else 'N'}  "
              f"refs={'Y' if has_refs else 'N'}  "
              f"figures={n_figs}  captions={n_caps}  supplements={n_supp}")
        print()
        return "ok"

    def batch_download(self, papers):
        """
        Download multiple papers. Log in once, then download all.

        Args:
            papers: list of (doi_or_url, output_dir) tuples

        Returns:
            list of (doi_or_url, output_dir, status) tuples
        """
        print(f"\nBatch downloading {len(papers)} paper(s)...\n")
        results = []
        for i, (doi_or_url, output_dir) in enumerate(papers, 1):
            print(f"\n{'#' * 60}")
            print(f"  Paper {i}/{len(papers)}")
            print(f"{'#' * 60}")
            try:
                status = self.download(doi_or_url, output_dir)
                results.append((doi_or_url, output_dir, status))
            except Exception as e:
                print(f"  ERROR: {e}")
                print("  Skipping to next paper...\n")
                results.append((doi_or_url, output_dir, "error"))
                continue
        print(f"\nBatch complete: {len(papers)} paper(s) processed.")
        return results

    def batch_download_from_csv(self, csv_path, output_dir, column="DOI"):
        """
        Download papers listed in a CSV file.

        Each paper gets its own folder: case1/, case2/, etc.
        A mapping CSV is saved alongside with the case ID appended.

        Args:
            csv_path:   path to CSV file
            output_dir: parent folder where case1/, case2/, ... are created
            column:     name of the column containing DOIs, PMIDs, or URLs
                        (default: "DOI")

        Returns:
            path to the mapping CSV
        """
        import csv

        csv_path = Path(csv_path)
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        with open(csv_path, "r", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            if column not in reader.fieldnames:
                raise ValueError(
                    f"Column '{column}' not found in CSV. "
                    f"Available columns: {reader.fieldnames}\n"
                    f"Use --column to specify the correct column name.")
            rows = list(reader)

        print(f"\nFound {len(rows)} papers in {csv_path.name} (column: {column})")
        print(f"Output: {output_dir}\n")

        results = []
        case_num = 0
        for i, row in enumerate(rows, 1):
            doi = row.get(column, "").strip()
            if not doi:
                print(f"  Row {i}: empty {column}, skipping")
                row["case_id"] = ""
                row["status"] = "skipped_empty"
                results.append(row)
                continue

            case_num += 1
            case_id = f"case{case_num}"
            case_dir = output_dir / case_id

            print(f"\n{'#' * 60}")
            print(f"  Paper {i}/{len(rows)} -> {case_id}")
            print(f"{'#' * 60}")

            try:
                status = self.download(doi, str(case_dir))
            except Exception as e:
                print(f"  ERROR: {e}")
                print("  Skipping to next paper...\n")
                status = "error"

            if status == "paywalled":
                case_num -= 1
                row["case_id"] = ""
                row["status"] = "paywalled"
            else:
                row["case_id"] = case_id
                row["status"] = status
            results.append(row)

        # Save mapping CSV
        mapping_path = output_dir / f"{csv_path.stem}_mapping.csv"
        fieldnames = list(results[0].keys())
        for col in ["status", "case_id"]:
            if col in fieldnames:
                fieldnames.remove(col)
                fieldnames.insert(0, col)

        with open(mapping_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(results)

        n_ok = sum(1 for r in results if r["status"] == "ok")
        n_pay = sum(1 for r in results if r["status"] == "paywalled")
        n_err = sum(1 for r in results if r["status"] == "error")
        n_skip = sum(1 for r in results if r["status"] == "skipped_empty")

        print(f"\n{'=' * 60}")
        print(f"  SUMMARY")
        print(f"  Downloaded: {n_ok}")
        print(f"  Paywalled:  {n_pay} (skipped)")
        print(f"  Errors:     {n_err}")
        if n_skip:
            print(f"  Empty DOI:  {n_skip}")
        print(f"  Mapping:    {mapping_path}")
        print(f"{'=' * 60}")

        return str(mapping_path)

    def close(self):
        """Close the browser."""
        if self.driver:
            self.driver.quit()
            self.driver = None
            print("Browser closed.")


# ─────────────────────────────────────────────────────────────
# CLI entry point
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Download Nature journal articles (HTML, text, methods, refs, figures, captions, supplements).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Single paper — DOI, PMID, or URL:
  python download_nature.py "10.1038/s41586-024-07238-z" ./my_paper
  python download_nature.py 38654105 ./my_paper
  python download_nature.py "https://pubmed.ncbi.nlm.nih.gov/38654105/" ./my_paper

  # Batch from CSV (default column: DOI):
  python download_nature.py papers.csv ./downloads
  python download_nature.py papers.csv ./downloads --column PMID
  python download_nature.py papers.csv ./downloads --column url --browser chrome
""")
    parser.add_argument("input",
                        help="DOI, PMID, PubMed URL, nature.com URL, or path to a CSV file")
    parser.add_argument("output_dir",
                        help="Output directory (single paper) or parent directory (CSV batch)")
    parser.add_argument("--column", default="DOI",
                        help="CSV column name containing DOIs/PMIDs/URLs (default: DOI)")
    parser.add_argument("--browser", default="firefox",
                        help="Browser to use: firefox, chrome, or edge (default: firefox)")

    args = parser.parse_args()

    dl = NatureDownloader(browser=args.browser)
    dl.login()

    if args.input.endswith(".csv"):
        dl.batch_download_from_csv(args.input, args.output_dir, column=args.column)
    else:
        dl.download(args.input, args.output_dir)

    dl.close()
