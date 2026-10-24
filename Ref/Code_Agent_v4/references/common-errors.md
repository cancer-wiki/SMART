# Common Errors in Code Generation

---

### 1. Score column name off by one ⚠️

`AddModuleScore` with `name = "EMT_score"` creates column `EMT_score1` (appends "1").

Wrong: `value_name = "EMT_score"` or `feature_B_name = "EMT"`
Right: `value_name = "EMT_score1"` or `feature_B_name = "EMT_score1"`

The `add_pathway_score` function uses `name = paste0(pathway_name, "_score")`,
so the final column is always `{pathway_name}_score1`.

---

### 2. Group column vs group value ⚠️

The column created by `create_gene_based_groups(gene_name = "MYC")` is
`MYC_group`. The values inside are `MYC_high` and `MYC_low`.

Wrong: `group_col = "MYC_high"` (value, not column)
Right: `group_col = "MYC_group"` (column name)

For `run_de_analysis`:
- `condition_col = "MYC_group"` ← column
- `condition1 = "MYC_high"` ← value
- `condition2 = "MYC_low"` ← value

---

### 3. Forgetting to source function files ⚠️

preprocess.R must source: `source("~/.claude/agents/Ref/Code_Agent_v4/references/preprocess.R")`
analysis.R must source: `source("~/.claude/agents/Ref/Code_Agent_v4/references/function_v2.R")`

Without sourcing, none of the custom functions exist.

---

### 4. Wrong data file loaded ⚠️

preprocess.R loads: `readRDS("Inputs/data.rds")` and writes `write.csv(seurat_obj@meta.data, "Working/processed_meta.csv", row.names = TRUE)`
analysis.R loads: `readRDS("Inputs/data.rds")` AGAIN, then merges `read.csv("Working/processed_meta.csv", row.names = 1)` via `AddMetaData()`

There is NO `data_processed.rds` in this workflow. The metadata CSV is the
only handoff between the two scripts.

If analysis.R skips the `AddMetaData()` step, every preprocessing column
(scores, groups, gated cell types) will be missing and downstream tasks will
fail with "column not found" errors.

---

### 5. DE result column name varies ⚠️

Libra's output may use `avg_logFC` or `logFC` depending on version.
Always check: `colnames(result_4_1_c$de_results)`

If you need to operate on the logFC column directly, adapt:
```r
# Safe approach
if ("avg_logFC" %in% colnames(de_res)) {
  logfc_col <- "avg_logFC"
} else {
  logfc_col <- "logFC"
}
```

Similarly, the gene column may be `gene`, `Gene`, or stored as rownames.

---

### 6. Missing tryCatch ⚠️

Every analysis function call MUST be wrapped in tryCatch. A single error
(e.g., too few cells for DE) should not crash the entire script.

Wrong:
```r
result <- correlate_celltype_features(...)
ggsave(...)
```

Right:
```r
result <- tryCatch({
  correlate_celltype_features(...)
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
  NULL
})
if (!is.null(result)) {
  ggsave(...)
}
```

---

### 7. Stratification subset syntax ⚠️

Wrong: `subset(seurat_obj, condition = "Primary")` (single equals = assignment)
Right: `subset(seurat_obj, condition == "Primary")` (double equals = comparison)

---

### 8. Reusing a variable that doesn't exist ⚠️

If plan2 says "Reuse DE from Task 4.1.c" but Task 4.1.c failed (returned NULL),
later code referencing `result_4_1_c$de_results` will crash.

Always null-check:
```r
if (!is.null(result_4_1_c)) {
  # proceed with downstream task
}
```

---

### 9. Hardcoded sample column ⚠️

Wrong: `sample_col = "ID"` (from a different dataset's example)
Right: `sample_col = "sample"` (from actual data_pre.txt for this dataset)

Always use the column name specified in plan2.txt, which came from data_pre.txt.

---

### 10. Not creating output directories ⚠️

If `Outputs/plots/` doesn't exist, `ggsave` will fail silently or error.

Always at the top of analysis.R:
```r
dir.create("Outputs/plots", recursive = TRUE, showWarnings = FALSE)
dir.create("Outputs/results", recursive = TRUE, showWarnings = FALSE)
```

---

### 11. Gene symbol mismatch ⚠️

When plan2 uses a protein/alias name, translate to the official HGNC gene symbol
before passing it to any function. Add a comment noting the translation.

```r
feature_B_name = "LDHA"  # gene symbol; corresponds to lactate dehydrogenase A protein
```

If uncertain, add a verification step:
```r
# Verify gene exists in the data
if (!"LDHA" %in% rownames(seurat_obj)) {
  cat("WARNING: LDHA not found in object — check symbol\n")
}
```

---

### 12. msigdbr query errors ⚠️

**Species:**
- Wrong: `msigdbr(species = "human")`
- Right: `msigdbr(species = "Homo sapiens")`

**Set name:**
- Wrong: `filter(gs_name == "GLYCOLYSIS")`
- Right: `filter(gs_name == "HALLMARK_GLYCOLYSIS")` — use exact set name

**Argument names (msigdbr ≥ 10.0 API change):**
The `category` and `subcategory` arguments are deprecated. Use `collection`
and `subcollection` instead.
- Wrong: `msigdbr(species = "Homo sapiens", category = "C2", subcategory = "CP:KEGG")`
- Right: `msigdbr(species = "Homo sapiens", collection = "C2", subcollection = "CP:KEGG_LEGACY")`

**KEGG split:** the plain `"CP:KEGG"` subcollection no longer exists. It was
split into:
- `"CP:KEGG_LEGACY"`  — the classic ~186 KEGG sets (e.g. `KEGG_GLYCOLYSIS_GLUCONEOGENESIS`, `KEGG_MAPK_SIGNALING_PATHWAY`)
- `"CP:KEGG_MEDICUS"` — newer, larger ~658-set Medicus collection

Using `subcollection = "CP:KEGG"` will fail with `Error: Unknown subcollection`.
For the standard "KEGG_*" set names from older code, you almost always want
`"CP:KEGG_LEGACY"`.

```r
# CORRECT — modern msigdbr ≥ 10.0:
glycolysis_genes <- msigdbr(species = "Homo sapiens",
                            collection    = "C2",
                            subcollection = "CP:KEGG_LEGACY") %>%
  filter(gs_name == "KEGG_GLYCOLYSIS_GLUCONEOGENESIS") %>%
  pull(gene_symbol) %>% unique()
```

---

### 12b. AddMetaData "No cell overlap" — never inline a per-sample broadcast ⚠️

If you ever feel tempted to write something like

```r
seurat_obj$new_col <- per_sample_vec[as.character(seurat_obj$sample_col)]
```

**STOP.** That triggers `Error: No cell overlap between new meta data and
Seurat object` because Seurat's `$<-` routes through `AddMetaData()`, which
expects vector names to be cell barcodes — they are sample IDs here.

**Use `add_per_sample_summary()` instead** (preprocess-code-rules.md → Type 6).
It handles the per-sample aggregation AND the broadcast in one call, writes
directly to `@meta.data`, and skips the barcode check.

For sample-level group labels (`X_high` / `X_low`), use
`create_groups_from_per_sample_summary()` (Type 7) — it wraps the same
broadcast logic plus a median / threshold / quantile split.

There is no remaining situation where the agent should write the broadcast
inline. If you find yourself reaching for `left_join` on `@meta.data` or for
`seurat_obj$col <- vec[...]`, switch to one of the two functions above.

---

### 13. Overwriting variables in loops ⚠️

Wrong:
```r
for (gene in genes) {
  result <- correlate_celltype_features(...)
  # result gets overwritten each iteration
}
```

Right (when you only need a summary):
```r
corr_summary <- data.frame(gene = character(), rho = numeric(), pval = numeric())
for (gene in genes) {
  .tmp <- correlate_celltype_features(...)
  corr_summary <- rbind(corr_summary, data.frame(
    gene = gene,
    rho  = .tmp$correlation$estimate,
    pval = .tmp$correlation$p.value
  ))
  rm(.tmp); gc()
}
```

---

### 14. Wrong parameter name on create_gene_based_groups ⚠️

The function signature uses `sample_column` (NOT `patient_column`):

Wrong: `create_gene_based_groups(..., patient_column = "sample")`
Right: `create_gene_based_groups(..., sample_column = "sample")`

---

## Pre-Flight Checklist

Before writing the final scripts, verify:

| # | Check |
|---|-------|
| 1 | preprocess.R sources `~/.claude/agents/Ref/Code_Agent_v4/references/preprocess.R` |
| 2 | analysis.R sources `~/.claude/agents/Ref/Code_Agent_v4/references/function_v2.R` |
| 3 | preprocess.R loads `Inputs/data.rds` |
| 4 | preprocess.R writes `Working/processed_meta.csv` via `write.csv(..., row.names = TRUE)` (NO `.rds` saved) |
| 5 | analysis.R loads `Inputs/data.rds` AGAIN (NOT a `data_processed.rds`) |
| 6 | analysis.R reads `Working/processed_meta.csv` with `row.names = 1` and merges via `AddMetaData()` |
| 7 | All score columns use `_score1` suffix consistently |
| 8 | All group columns use `_group` suffix consistently |
| 9 | Every task from plan2.txt has a code block |
| 10 | Every function call has tryCatch |
| 11 | Every plot save has null-check |
| 12 | Output directories created at top of analysis.R |
| 13 | Gene symbols are HGNC standard (not protein names) |
| 14 | msigdbr uses `collection`/`subcollection` (NOT deprecated `category`/`subcategory`) and exact set names with "Homo sapiens" |
| 14b | KEGG queries use `subcollection = "CP:KEGG_LEGACY"` (NOT `"CP:KEGG"`, which no longer exists) |
| 15 | Stratified loops use `==` not `=` in subset |
| 16 | DE reuse variables actually exist earlier in script |
| 17 | `create_gene_based_groups` uses `sample_column`, not `patient_column` |
| 18 | Per-sample numeric broadcasts use `add_per_sample_summary()` (Type 6) — NOT inline `seurat_obj$col <- vec[...]` or `left_join` |
| 19 | Per-sample group labels use `create_groups_from_per_sample_summary()` (Type 7) — NOT inline `left_join` + rownames-restore |
