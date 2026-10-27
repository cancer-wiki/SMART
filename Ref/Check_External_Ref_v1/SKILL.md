# check-external-ref-v1 — Quick Reference

## Purpose
Find referenced papers via paperclip, extract gene lists from text/PDF/docx directly, and for xlsx supplements download locally + parse with openpyxl.

## Files
```
Inputs/paper1_ref.txt           # [N] Author. Title. Journal (Year). DOI:...
Working/definitions_detail.txt  # Input: Route A terms with ref numbers
Working/definitions_final.txt   # READ ONLY — do not write
Working/extra/                  # Downloaded xlsx files + extracted gene lists
```

## Key Rules
1. NEVER use `paperclip map` on xlsx — it hallucinates gene lists
2. Text/PDF/docx extraction = reliable, use paperclip grep/cat directly
3. xlsx extraction = download locally + parse with openpyxl (Phase 4b)
4. R package definitions = flag as ROUTE_B for use-extra-function-agent

## Paperclip Commands (for finding papers + reading metadata)

### Find paper by DOI (fastest)
```bash
paperclip lookup doi 10.1038/ncomms15107
```

### Find paper by title
```bash
paperclip search -s pmc "Isella cancer-cell intrinsic CRIS colorectal" -n 3
```

### List supplements
```bash
paperclip bash 'ls /papers/PMC5499209/supplements/'
```

### Read xlsx structure (metadata only — NOT full data)
```bash
paperclip bash 'cat /papers/PMC5499209/supplements/file.xlsx.md.lines'
```
Returns: sheet name, column names, dtypes, 3 sample values, row count.

### Read PDF/docx supplement text (full content — reliable)
```bash
paperclip bash 'cat --full /papers/PMC5499209/supplements/file.pdf.md.lines'
```

### Search paper text
```bash
paperclip bash 'grep -i "GENE1\|GENE2" /papers/PMC5499209/content.lines'
```

## xlsx Download + Parse (Phase 4b — runs LOCALLY, not in paperclip)

### Download
```python
python3 -c "
import urllib.request, urllib.parse
pmc_id = 'PMC5499209'; filename = 'ncomms15107-s9.xlsx'
doi = '10.1038/ncomms15107'; doi_enc = urllib.parse.quote(doi, safe='')
urls = [
    f'https://pmc.ncbi.nlm.nih.gov/articles/{pmc_id}/bin/{filename}',
    f'https://www.ncbi.nlm.nih.gov/pmc/articles/{pmc_id}/bin/{filename}',
    f'https://static-content.springer.com/esm/art%3A{doi_enc}/MediaObjects/{filename}',
]
for url in urls:
    try:
        req = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
        data = urllib.request.urlopen(req, timeout=30).read()
        if len(data) > 1000 and not data[:20].startswith(b'<!DOCTYPE'):
            open(f'Working/extra/{filename}','wb').write(data)
            print(f'OK: {len(data)} bytes'); break
        else: print(f'HTML/small: {url}')
    except Exception as e: print(f'Fail: {url} {e}')
"
```

### Parse
```python
python3 -c "
import openpyxl
wb = openpyxl.load_workbook('Working/extra/FILE.xlsx', read_only=True)
ws = wb.active
genes = [str(row[0]) for row in ws.iter_rows(values_only=True) if row[1] == 'CRIS-B']
print(f'{len(genes)} genes: {', '.join(genes)}')
open('Working/extra/extracted_TERM.txt','w').write('\n'.join(genes))
"
```

## Output
- RESOLVED: gene list appended to definitions_detail.txt Section 3
- DOWNLOAD_FAILED: manifest at Working/extra/download_manifest.json
- NOT_IN_PMC: logged with DOI
- ROUTE_B: flagged for use-extra-function-agent
