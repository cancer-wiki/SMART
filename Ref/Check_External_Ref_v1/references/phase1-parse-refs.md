# Phase 1: Parse Which References Are Needed

## Input
- `Working/definitions_detail.txt` — look for terms tagged as Route A, "external ref", "companion paper", "gene list from other paper", "referenced paper", or similar
- `Working/definitions_final.txt` — cross-check for terms with definition type containing "external", "companion", "other paper", "unavailable", or "external classifier"

## What to extract per term
For each term needing an external reference:
1. **Term name** — the biological term (e.g., "MYC target genes", "CRIS-B subtype")
2. **Ref number** — the reference number in the citing paper (e.g., "ref 26", "ref 38")
3. **What to look for** — what specific data we need (e.g., "gene list", "classifier gene set", "scoring coefficients")
4. **Context** — any hints about where the data lives (e.g., "Supplementary Table 5", "Table S6")

## How to find the ref paper identity
Read `Inputs/paper1_ref.txt` and grep for the ref number:
```bash
grep "^\[26\]" Inputs/paper1_ref.txt
```
This returns: `[26] Kim, J. et al. Title. Journal Vol, Pages (Year). DOI:10.xxxx/...`

Extract:
- **Title** — for paperclip search query
- **DOI** — after "DOI:" at end of line (if present)
- **First author** — for search refinement
- **Journal + Year** — for search refinement

## Route B detection
Flag as ROUTE_B (do not attempt extraction) if the definition comes from:
- An R package that bundles gene lists or implements a classifier
- A computational tool or classifier that is not a gene list
- An external database query (GEO, TCGA, etc.)

Record the package/tool name for the `use-extra-function-agent`.

## Output
Create a work plan as a table:
```
| # | Term | Ref # | DOI | Search Query | What to Find | Route |
|---|------|-------|-----|-------------|--------------|-------|
| 1 | immune signature | 22 | 10.1038/s41586-020-1234-5 | Smith et al. immune profiling | immune gene list | A |
| 2 | tumor subtype | 15 | ... | Jones et al. subtype classifier | subtype labels | B (R package) |
```
