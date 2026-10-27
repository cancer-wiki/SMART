"""
Download supplementary files from Nature/Springer/Elsevier articles.
No authentication needed — supplement files are publicly accessible via the article HTML page.

Usage:
    python3 download_supp.py <DOI> <output_dir> [--filter KEYWORD]

Examples:
    python3 download_supp.py 10.1038/ncomms15107 Working/extra/
    python3 download_supp.py 10.1038/ncomms15107 Working/extra/ --filter "Supplementary Data 8"
    python3 download_supp.py 10.1038/nm.3559 Working/extra/ --filter "Table 5"
"""

import os
import re
import sys
import time
import requests
from pathlib import Path
from bs4 import BeautifulSoup

UA = f"SMART-downloader/1.0 (academic TDM; mailto:{os.environ.get('SMART_CONTACT_EMAIL', 'unset')})"


def get_article_url(doi):
    """Convert DOI to article URL."""
    if "10.1038/" in doi:
        suffix = doi.replace("10.1038/", "")
        return f"https://www.nature.com/articles/{suffix}"
    elif "10.1016/" in doi:
        # Elsevier/Cell — need to resolve DOI
        try:
            r = requests.head(f"https://doi.org/{doi}", allow_redirects=True, timeout=15, headers={"User-Agent": UA})
            return r.url
        except:
            return f"https://doi.org/{doi}"
    elif "10.7554/" in doi:
        # eLife
        suffix = doi.replace("10.7554/eLife.", "")
        return f"https://elifesciences.org/articles/{suffix}"
    else:
        try:
            r = requests.head(f"https://doi.org/{doi}", allow_redirects=True, timeout=15, headers={"User-Agent": UA})
            return r.url
        except:
            return f"https://doi.org/{doi}"


def find_supplement_links(html_text, base_url=""):
    """Parse article HTML for supplement download links."""
    soup = BeautifulSoup(html_text, "html.parser")
    items = []
    seen = set()

    for a in soup.find_all("a", href=True):
        href = a["href"]
        text = a.get_text(separator=" ", strip=True)

        # Check if it's a supplement download link
        is_supp = bool(re.search(r"MOESM|static-content|MediaObjects|ESM\d|supp", href, re.I))
        is_supp = is_supp or bool(re.search(r"\.(xlsx|xls|pdf|docx|doc|csv|zip|txt)\b", href, re.I))
        is_supp = is_supp or "supplement" in (a.get("data-track-label") or "").lower()
        is_supp = is_supp and "download" in text.lower()

        if not is_supp:
            continue

        # Normalize URL
        if href.startswith("//"):
            href = "https:" + href
        elif href.startswith("/"):
            from urllib.parse import urlparse
            parsed = urlparse(base_url)
            href = f"{parsed.scheme}://{parsed.netloc}{href}"

        if href in seen:
            continue
        seen.add(href)

        # Clean up text
        clean_text = re.sub(r"\s*\(download.*?\)", "", text, flags=re.I).strip()
        clean_text = re.sub(r"[↓⬇️]", "", clean_text).strip()

        items.append({"url": href, "name": clean_text})

    return items


def download_supplements(doi, output_dir, filter_keyword=None):
    """Download supplement files for a paper given its DOI."""
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    # Step 1: Get article page
    article_url = get_article_url(doi)
    print(f"Article URL: {article_url}")

    resp = requests.get(article_url, headers={"User-Agent": UA}, timeout=30)
    if resp.status_code != 200:
        print(f"ERROR: Could not fetch article page (status {resp.status_code})")
        return []

    # Step 2: Find supplement links
    items = find_supplement_links(resp.text, article_url)
    if not items:
        print("No supplement download links found on article page.")
        return []

    # Step 3: Filter if requested
    if filter_keyword:
        items = [i for i in items if filter_keyword.lower() in i["name"].lower()]
        if not items:
            print(f"No supplements matching '{filter_keyword}' found.")
            return []

    print(f"Found {len(items)} supplement(s)")

    # Step 4: Download each
    downloaded = []
    for i, item in enumerate(items, 1):
        print(f"  [{i}/{len(items)}] {item['name'][:70]}")
        try:
            r = requests.get(item["url"], headers={"User-Agent": UA}, timeout=120, allow_redirects=True)
            r.raise_for_status()
        except Exception as e:
            print(f"    FAIL: {e}")
            continue

        # Detect file extension from Content-Disposition, Content-Type, and magic bytes
        ext = None
        cd = r.headers.get("Content-Disposition", "")
        if cd:
            m = re.search(r"filename[*]?=[\"']?([^\"';\n]+)", cd)
            if m:
                em = re.search(r"\.(\w+)$", m.group(1))
                if em:
                    ext = em.group(1).lower()

        if not ext:
            ct = r.headers.get("Content-Type", "").lower()
            for mime, e in {
                "spreadsheetml.sheet": "xlsx", "ms-excel": "xls",
                "wordprocessingml": "docx", "msword": "doc",
                "text/csv": "csv", "text/plain": "txt",
                "application/zip": "zip", "application/pdf": "pdf",
            }.items():
                if mime in ct:
                    ext = e
                    break

        # Magic bytes check: xlsx/docx/zip all start with PK (ZIP header)
        if not ext or ext == "pdf":
            magic = r.content[:4]
            if magic == b"PK\x03\x04":
                # ZIP-based format — check if xlsx or docx
                if b"xl/" in r.content[:2000]:
                    ext = "xlsx"
                elif b"word/" in r.content[:2000]:
                    ext = "docx"
                else:
                    ext = "zip"
            elif magic == b"%PDF":
                ext = "pdf"
            elif magic[:2] == b"\xd0\xcf":
                ext = "xls"  # OLE2 format (old Excel)

        if not ext:
            ext = "pdf"  # fallback

        # Save
        clean = re.sub(r"[^A-Za-z0-9._-]", "_", item["name"])
        clean = re.sub(r"_+", "_", clean).strip("_") or "Supplement"
        fp = out / f"{clean}.{ext}"
        c = 1
        while fp.exists():
            fp = out / f"{clean}_{c}.{ext}"
            c += 1

        fp.write_bytes(r.content)
        kb = len(r.content) / 1024
        size_str = f"{kb/1024:.1f} MB" if kb > 1024 else f"{kb:.1f} KB"
        print(f"    OK: {fp.name} ({size_str})")
        downloaded.append(str(fp))
        time.sleep(0.5)

    return downloaded


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    doi = sys.argv[1]
    output_dir = sys.argv[2]
    filter_kw = None
    if "--filter" in sys.argv:
        idx = sys.argv.index("--filter")
        if idx + 1 < len(sys.argv):
            filter_kw = sys.argv[idx + 1]

    files = download_supplements(doi, output_dir, filter_kw)
    print(f"\nDownloaded {len(files)} file(s)")
