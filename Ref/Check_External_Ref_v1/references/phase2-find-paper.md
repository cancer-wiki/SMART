# Phase 2: Find the Reference Paper via Paperclip

## Strategy (try in order, stop when found)

### Step 1: Direct lookup by DOI (fastest)
If DOI is available from paper1_ref.txt (appears after "DOI:" at end of line):
```bash
paperclip lookup doi {DOI}
```
This is the most reliable method — direct hit by identifier.

### Step 2: Search PMC by title keywords
```bash
paperclip search -s pmc "FirstAuthor ShortTitle Journal Year" -n 3
```
- Use 4-6 distinctive keywords from the title
- Include first author surname, journal name, year
- If the first result matches (same authors, same title), proceed

### Step 3: Search broader if not found in PMC
```bash
paperclip search -s pmc,biorxiv,medrxiv "Title" -n 5
```

### Step 4: Try abstracts corpus
```bash
paperclip search -s abstracts "Title" -n 3
```
Abstract-only entries have no full text or supplements — but confirm the paper exists and give us metadata.

## When you find the paper
1. Note the PMC ID (e.g., PMC5499209)
2. List supplements:
```bash
paperclip bash 'ls /papers/{PMC_ID}/supplements/'
```
3. Identify supplement file types: xlsx, pdf, docx, txt, csv, zip
4. Proceed to Phase 3 to determine where the gene list is

## When paper is NOT in PMC
Record status as NOT_IN_PMC with:
- The DOI (for potential manual download later)
- The paper title and journal
- Any information about where the gene list might be (e.g., "Supplementary Table 6" mentioned in citing paper)

Do NOT fabricate gene lists. If the paper is not accessible, say so.
