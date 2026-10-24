# definitions_final.txt — Required Output Template

## Format Rule

**definitions_final.txt MUST follow this exact template.** The file has two parts:
1. **Summary table** — one row per term, pipe-delimited, comes FIRST
2. **Detailed notes** — per-term explanations, comes AFTER the table

The summary table is the primary output. Downstream agents parse it programmatically. If the table is missing or malformed, the pipeline breaks.

---

## Template

The table has **exactly 5 columns**: `#`, `Term`, `Definition Type`, `Final Definition`, `Note`. All detailed evidence and reasoning goes in `definitions_detail.txt`.

The `Final Definition` cell contains **exactly one value** — one pathway name, or one gene list, or "general cell type". Never "option A or option B". Never explanatory text. Never "for scRNA-seq application, use...".

The `Note` cell contains a **very brief** one-line reason or clarification (e.g., source figure, proxy explanation, validation method). Keep it short — one sentence max.

**If a single row would contain two or more values representing different biological processes, split it into separate rows (e.g., `3a`, `3b`).** Each row must have exactly one pathway or one gene list.

```
# Final Definitions

| # | Term | Definition Type | Final Definition | Note |
|---|------|----------------|------------------|------|
| 1 | <term name> | <type> | <definition> | <brief reason> |
| 2 | <term name> | <type> | <definition> | <brief reason> |
| ... | ... | ... | ... | ... |
```

---

## Allowed Definition Types

Use ONLY these values in the Definition Type column:

| Definition Type | Final Definition format |
|----------------|------------------------|
| `general cell type` | Literally `general cell type` — nothing else |
| `gene list from paper` | Comma-separated gene symbols |
| `gene list from supp` | Comma-separated gene symbols |
| `KEGG/MSigDB` | A single pathway name (e.g., `HALLMARK_GLYCOLYSIS`) |
| `single gene` | One gene symbol |
| `external ref (pending)` | Placeholder — Route A agent will resolve |
| `external package (pending)` | Placeholder — Route B agent will resolve |

---

## Example (illustrative only — do not copy content)

```
# Final Definitions

| # | Term | Definition Type | Final Definition | Note |
|---|------|----------------|------------------|------|
| 1 | Normal epithelial cells | general cell type | general cell type | |
| 2 | Tumor cells | general cell type | general cell type | |
| 3 | Pathway X target genes | gene list from paper | GENE_A, GENE_B, GENE_C, GENE_D | N genes validated by experiment (Fig. N) |
| 4 | Biological process Y | KEGG/MSigDB | KEGG_PATHWAY_Y | enrichment analysis (Fig. N) |
| 5a | Functional phenotype Q: Component A | KEGG/MSigDB | HALLMARK_PROCESS_A (proxy) | measured by functional assay only |
| 5b | Functional phenotype Q: Component B | KEGG/MSigDB | HALLMARK_PROCESS_B (proxy) | measured by functional assay only |
| 6 | Marker gene W | single gene | GENE_W | |
| 7 | Gene Z | single gene | GENE_Z (proxy for unannotated ncRNA) | ncRNA not in standard scRNA-seq |
| 8 | Subtype classifier | external package (pending) | SubtypeClassifier R package | |
| 9 | Signature from ref 22 | external ref (pending) | gene list from ref 22 | |
```
