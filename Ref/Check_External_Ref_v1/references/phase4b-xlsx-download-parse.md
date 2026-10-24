# Phase 4b: XLSX Download + Parse

## Overview
When the gene list is in an xlsx supplement, use the download_supp.py script to download it, then parse with openpyxl. No authentication needed — supplement files are publicly accessible.

## Step 1: Prepare
```bash
mkdir -p Working/extra
```

## Step 2: Download the supplement

Use the download script. It fetches the article HTML page, finds supplement download links, and downloads the files. No login or browser needed.

```bash
python3 ~/.claude/agents/Ref/Check_External_Ref_v1/references/download_supp.py \
  "{DOI}" "Working/extra" --filter "{SUPPLEMENT_NAME}"
```

Examples:
```bash
# Download specific supplement by name
python3 ~/.claude/agents/Ref/Check_External_Ref_v1/references/download_supp.py \
  "10.1038/ncomms15107" "Working/extra" --filter "Supplementary Data 8"

# Download all supplements (omit --filter)
python3 ~/.claude/agents/Ref/Check_External_Ref_v1/references/download_supp.py \
  "10.1038/nm.3559" "Working/extra"
```

The script handles:
- Nature/Springer papers (media.springernature.com URLs)
- Elsevier/Cell papers (resolved via DOI)
- eLife papers
- Correct file extension detection (magic bytes check for xlsx vs pdf)

## Step 3: Find the downloaded file
```bash
ls Working/extra/*.xlsx Working/extra/*.xls 2>/dev/null
```

## Step 4: Parse with openpyxl

First explore the structure:
```python
python3 -c "
import openpyxl
wb = openpyxl.load_workbook('Working/extra/FILE.xlsx', read_only=True)
for name in wb.sheetnames:
    ws = wb[name]
    print(f'Sheet: {name}, rows: {ws.max_row}, cols: {ws.max_column}')
    for i, row in enumerate(ws.iter_rows(values_only=True)):
        if i < 5: print(f'  Row {i}: {list(row)[:6]}')
wb.close()
"
```

Then extract based on the structure learned from paperclip .md.lines + the actual data:

```python
python3 -c "
import openpyxl
wb = openpyxl.load_workbook('Working/extra/FILE.xlsx', read_only=True)
ws = wb['SHEET_NAME']  # or wb.active

# Adapt the extraction logic based on what you see in the data
genes = []
for row in ws.iter_rows(min_row=HEADER_ROW+1, values_only=True):
    # Example: filter by column value
    if row[COL_INDEX] == 'FILTER_VALUE':
        genes.append(str(row[GENE_COL_INDEX]))

print(f'Found {len(genes)} genes')
print(', '.join(sorted(genes)))

with open('Working/extra/extracted_TERMNAME.txt', 'w') as f:
    f.write('\n'.join(sorted(genes)))
wb.close()
"
```

For .xls files (older Excel format), use xlrd:
```python
python3 -c "
import xlrd
wb = xlrd.open_workbook('Working/extra/FILE.xls')
ws = wb.sheet_by_index(0)
for i in range(min(5, ws.nrows)):
    print([ws.cell_value(i, j) for j in range(min(6, ws.ncols))])
"
```

## Step 5: Verify
1. Gene count matches expectation
2. Sample genes from .md.lines appear in extracted list
3. Gene names are valid HUGO symbols

## Step 6: Record
Write extracted genes to `Working/extra/extracted_{TERMNAME}.txt` (one gene per line).
Report as RESOLVED in Section 3 of definitions_detail.txt.
