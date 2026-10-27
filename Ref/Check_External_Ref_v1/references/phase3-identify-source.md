# Phase 3: Identify Where the Gene List Lives

## Check order (stop at first success)

### Step 1: Paper main text
Some papers enumerate gene lists directly in the text or methods.
```bash
paperclip bash 'grep -i "gene_keyword\|signature\|module" /papers/{PMC_ID}/content.lines'
```
If you find a comma-separated or newline-separated gene list → extract directly (Phase 4a).

### Step 2: PDF/docx supplements
These are reliably readable as text.
```bash
# List supplements to find PDF/docx files
paperclip bash 'ls /papers/{PMC_ID}/supplements/'

# Read full content of a PDF supplement
paperclip bash 'cat --full /papers/{PMC_ID}/supplements/{file}.pdf.md.lines'

# Read full content of a docx supplement
paperclip bash 'cat --full /papers/{PMC_ID}/supplements/{file}.docx.md.lines'

# Search within a supplement for specific terms
paperclip bash 'grep -i "CRIS-B\|basal\|classical\|gene list" /papers/{PMC_ID}/supplements/{file}.pdf.md.lines'
```
If gene list is found in the text → extract directly (Phase 4a).

### Step 3: xlsx supplements (metadata only)
xlsx files cannot be read directly by paperclip. The `.md.lines` file provides metadata ONLY.
```bash
paperclip bash 'cat /papers/{PMC_ID}/supplements/{file}.xlsx.md.lines'
```

This returns:
- Sheet name(s)
- Number of rows and columns per table
- Column names with dtypes
- 3 sample values per column

**Use this metadata to understand the table structure**, then write a download manifest (Phase 4b).

### How to interpret .md.lines column info

| What you see | What it means |
|---|---|
| Column name looks like a gene (e.g., "REG4") | The header row is likely missing; first data value became the header |
| Column name is descriptive (e.g., "Gene", "Symbol") | Normal header; data starts from row 2 |
| Sample values are gene names (e.g., "MUC2, FCGBP, ZG16") | This column contains gene names |
| Sample values are categories (e.g., "CRIS-A, CRIS-A, CRIS-A") | This column contains class/group labels |
| Dtype is "str" or "object" | Text column (gene names or labels) |
| Dtype is "float64" or "int64" | Numeric column (scores, counts, etc.) |

### Step 4: R package check
If the citing paper says "we used the X R package" or "gene lists from X package":
- Flag as ROUTE_B
- Record: package name, what to extract, any version info
- Do NOT attempt to extract yourself
