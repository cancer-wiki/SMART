# Preprocessing Code Rules

## Goal
Translate every preprocessing step from plan2.txt into executable R code in
a single preprocess.R script.

---

## Script Structure

```r
# === PREPROCESSING SCRIPT ===
# Generated from plan2.txt
# Run this BEFORE analysis.R

# --- Libraries ---
library(Seurat)
library(ggplot2)
library(dplyr)
library(tidyverse)
# Add msigdbr ONLY if any step uses MSigDB gene sets:
library(msigdbr)

# --- Source preprocessing functions ---
source("~/.claude/agents/Ref/Code_Agent_v4/references/preprocess.R")

# --- Load data ---
cat("Loading Seurat object...\n")
seurat_obj <- readRDS("Inputs/data.rds")
cat("Loaded:", ncol(seurat_obj), "cells,", nrow(seurat_obj), "genes\n")

# Record existing columns for validation
existing_cols <- colnames(seurat_obj@meta.data)

# ===================================================================
# PREPROCESSING STEPS
# ===================================================================

# --- Preprocessing #1: ... ---
# [code block]

# --- Preprocessing #2: ... ---
# [code block]

# ...

# --- Save metadata only (CSV; NO .rds saved) ---
dir.create("Working", recursive = TRUE, showWarnings = FALSE)
write.csv(seurat_obj@meta.data, "Working/processed_meta.csv", row.names = TRUE)

cat("\nPreprocessing complete. Metadata written to Working/processed_meta.csv\n")
cat("New columns added:", setdiff(colnames(seurat_obj@meta.data), existing_cols), "\n")
```

**Why CSV (and not RDS)?** The Seurat object itself does not need to be re-saved
— only the new metadata columns produced by preprocessing matter for the
downstream analysis. `analysis.R` will re-load the original `Inputs/data.rds`
and merge this CSV back in via `AddMetaData()`. This keeps the handoff small
and avoids round-tripping the full expression matrix.

---

## Translating Each Preprocessing Type

### Type 1: add_pathway_score

**If plan2 gives explicit gene list:**
```r
# --- Preprocessing #N: [pathway_name] module score ---
[pathway]_genes <- c("GENE1", "GENE2", "GENE3", ...)
seurat_obj <- add_pathway_score(seurat_obj, [pathway]_genes, "[pathway_name]")
# New column: [pathway_name]_score1
```

**If plan2 references MSigDB set:**
```r
# --- Preprocessing #N: [pathway_name] module score (MSigDB) ---
# msigdbr ≥ 10.0: use `collection` / `subcollection`. The old `category` /
# `subcategory` arguments are deprecated and the KEGG subcollection has been
# split into "CP:KEGG_LEGACY" (classic ~186 sets) and "CP:KEGG_MEDICUS".
[pathway]_genes <- msigdbr(species = "Homo sapiens", collection = "[H/C2/C5/...]") %>%
  filter(gs_name == "[EXACT_SET_NAME]") %>%
  pull(gene_symbol) %>%
  unique()
cat("[pathway_name] gene set:", length([pathway]_genes), "genes\n")
seurat_obj <- add_pathway_score(seurat_obj, [pathway]_genes, "[pathway_name]")
# New column: [pathway_name]_score1
```

**MSigDB collection reference (msigdbr ≥ 10.0):**
| Set type | collection | subcollection |
|----------|------------|---------------|
| Hallmark      | "H"  | —                  |
| KEGG (legacy) | "C2" | "CP:KEGG_LEGACY"   |
| KEGG (Medicus)| "C2" | "CP:KEGG_MEDICUS"  |
| Reactome      | "C2" | "CP:REACTOME"      |
| WikiPathways  | "C2" | "CP:WIKIPATHWAYS"  |
| BioCarta      | "C2" | "CP:BIOCARTA"      |
| GO BP         | "C5" | "GO:BP"            |
| GO MF         | "C5" | "GO:MF"            |
| GO CC         | "C5" | "GO:CC"            |

> Do NOT use `subcollection = "CP:KEGG"` — that subcollection no longer exists
> in msigdbr ≥ 10.0 and will throw `Error: Unknown subcollection`. For classic
> KEGG sets like `KEGG_GLYCOLYSIS_GLUCONEOGENESIS`, use `"CP:KEGG_LEGACY"`.

Example for KEGG (legacy):
```r
glycolysis_genes <- msigdbr(species = "Homo sapiens",
                            collection    = "C2",
                            subcollection = "CP:KEGG_LEGACY") %>%
  filter(gs_name == "KEGG_GLYCOLYSIS_GLUCONEOGENESIS") %>%
  pull(gene_symbol) %>% unique()
```

**Note:** when plan2 says "use this gene list" it should already include the
explicit genes inline. If a referenced gene list is missing, fail loudly rather
than guessing — do not invent gene names.

### Type 2: create_gene_based_groups

**Function signature (from `preprocess.R`):**
```r
create_gene_based_groups(seurat_obj,
                         gene_name,
                         celltype_column = "refine_celltype",
                         sample_column = "sample",
                         target_celltype = "Tumor")
```

**Usage:**
```r
# --- Preprocessing #N: [GENE] high/low groups ---
seurat_obj <- create_gene_based_groups(
  seurat_obj,
  gene_name = "[GENE]",
  celltype_column = "[celltype_col]",
  sample_column = "[sample_col]",
  target_celltype = "[cell_type]"
)
# New column: [GENE]_group (values: [GENE]_high, [GENE]_low)
cat("[GENE] group distribution:\n")
print(table(seurat_obj@meta.data$[GENE]_group, useNA = "ifany"))
```

**Note:** the parameter is `sample_column` (not `patient_column`). Pass the actual
sample column name from plan2.txt — typically `"sample"` for this dataset.

### Type 3: pull_out_gene_list_from_GO

```r
# --- Preprocessing #N: Gene list from GO term ---
[name]_genes <- pull_out_gene_list_from_GO("[GO:XXXXXXX]")
cat("GO term [GO:XXXXXXX]:", length([name]_genes), "genes\n")
# Then use this gene list in a subsequent add_pathway_score call
seurat_obj <- add_pathway_score(seurat_obj, [name]_genes, "[name]")
```

### Type 4: add_extra_meta

```r
# --- Preprocessing #N: Add extra metadata from CSV ---
seurat_obj <- add_extra_meta(seurat_obj, annot_path = "Inputs/extra_meta.csv")
```

The CSV must have cell barcodes as row names (first column). Matching is by
barcode, order-independent.

### Type 5: gate_cells_composite

For composite cell-type gating defined by mixed high/mid/low markers
(e.g., "KRT8+ VIM+ CDH1-low partial-EMT epithelial cells"). Do NOT collapse such
gating into a module score — sign-flipping breaks the scoring assumption.

```r
# --- Preprocessing #N: Gate composite subtype ---
seurat_obj <- gate_cells_composite(
  seurat_obj,
  gene_criteria = list(
    list(gene = "KRT8", direction = "high"),
    list(gene = "VIM",  direction = "mid"),
    list(gene = "CDH1", direction = "low")
  ),
  celltype_column = "refine_celltype",
  parent_celltype = "Epithelial",
  member_name     = "KRT8_VIM_CDH1low_Epithelial",
  new_column      = "refine_celltype_gated"   # or NULL to overwrite in place
)
```

Threshold logic (per gene): if any criterion uses "mid" for that gene, quartile
split (high > Q3, low < Q1, mid in [Q1, Q3]); otherwise median split.

### Type 6: add_per_sample_summary — per-sample stat broadcast to every cell

Use whenever plan2 asks for **a numeric per-sample value broadcast to every
cell**: percentage of cells matching some condition per sample, count of cells
per sample, or mean / median / sum of a per-cell numeric column per sample.

> **DO NOT inline this with `seurat_obj$col <- per_sample_vec[meta$sample]`.**
> That triggers `Error: No cell overlap between new meta data and Seurat object`
> because Seurat's `$<-` routes through `AddMetaData()`, which checks the
> vector's names against cell barcodes (they are sample IDs here). The function
> below writes directly to `@meta.data` and bypasses that check.

**Function signature:**
```r
add_per_sample_summary(seurat_obj,
                       sample_column,
                       new_column,
                       summary_type    = c("percentage", "count",
                                           "mean", "median", "sum"),
                       celltype_column = NULL,
                       target_celltype = NULL,
                       feature_column  = NULL,
                       target_value    = NULL)
```

**Form A — percentage of cells matching a categorical condition per sample**
(within an optional cell-type filter). Denominator = cells of `target_celltype`
in that sample; numerator = those whose `feature_column` value is in `target_value`.

```r
# --- Preprocessing #N: % of <target_celltype> cells with <feature_column>==<target_value>, per sample ---
seurat_obj <- add_per_sample_summary(
  seurat_obj,
  sample_column   = "[sample_col]",
  new_column      = "[new_col]",
  summary_type    = "percentage",
  celltype_column = "[celltype_col]",
  target_celltype = "[target_celltype]",
  feature_column  = "[categorical_col]",
  target_value    = "[matching_value]"
)
```

**Form B — mean / median / sum of a per-cell numeric column per sample**
(within an optional cell-type filter):

```r
# --- Preprocessing #N: Mean of <feature_column> per sample, restricted to <target_celltype> ---
seurat_obj <- add_per_sample_summary(
  seurat_obj,
  sample_column   = "[sample_col]",
  new_column      = "avg_[feature_column]_in_[target_celltype]",
  summary_type    = "mean",
  celltype_column = "[celltype_col]",
  target_celltype = "[target_celltype]",
  feature_column  = "[numeric_col]"
  # target_value not needed for mean/median/sum
)
```

**Form C — count of cells matching a condition per sample** (or just count of
cells per sample if `feature_column`/`target_value` are omitted):

```r
seurat_obj <- add_per_sample_summary(
  seurat_obj,
  sample_column   = "[sample_col]",
  new_column      = "[new_col]",
  summary_type    = "count",
  celltype_column = "[celltype_col]",
  target_celltype = "[target_celltype]",
  feature_column  = "[categorical_col]",   # optional
  target_value    = "[matching_value]"      # optional
)
```

The new column has the **same numeric value for every cell from the same
sample**, including cells outside `target_celltype` — that's the standard
"sample-level covariate" use case.

### Type 7: create_groups_from_per_sample_summary — per-sample group label broadcast

Use when plan2 asks for a **categorical sample-level group label** like
`X_high` / `X_low` derived from a per-sample summary (e.g., median split on the
mean of a score per sample). The label is broadcast to every cell from each
sample.

> Replaces the inline `dplyr::left_join` + `rownames(...) <- orig_rn` pattern.
> Internally calls `add_per_sample_summary()`, so all the same arguments apply
> to control how the per-sample value is computed; `split` then controls the
> binning.

**Function signature:**
```r
create_groups_from_per_sample_summary(seurat_obj,
                                      sample_column,
                                      new_column,
                                      summary_type    = c("percentage", "count",
                                                          "mean", "median", "sum"),
                                      celltype_column = NULL,
                                      target_celltype = NULL,
                                      feature_column  = NULL,
                                      target_value    = NULL,
                                      split           = "median",
                                      high_label      = NULL,
                                      low_label       = NULL,
                                      mid_label       = NULL)
```

`split` accepts:
- `"median"` (default) — median split → 2 groups
- a single number — fixed threshold → 2 groups
- a length-2 quantile vector like `c(0.25, 0.75)` → 3 groups (low / mid / high)

**Example — sample-level median split on the mean of a score within a cell type:**
```r
# --- Preprocessing #N: <feature_column>_high / _low groups (median split on per-sample mean within <target_celltype>) ---
seurat_obj <- create_groups_from_per_sample_summary(
  seurat_obj,
  sample_column   = "[sample_col]",
  new_column      = "[feature_column]_group",
  summary_type    = "mean",
  celltype_column = "[celltype_col]",
  target_celltype = "[target_celltype]",
  feature_column  = "[numeric_col]",
  split           = "median"
)
# New column: [feature_column]_group (values: [feature_column]_high, [feature_column]_low)
```

**Example — tercile split on a per-sample percentage:**
```r
seurat_obj <- create_groups_from_per_sample_summary(
  seurat_obj,
  sample_column   = "[sample_col]",
  new_column      = "[new_col]",
  summary_type    = "percentage",
  celltype_column = "[celltype_col]",
  target_celltype = "[target_celltype]",
  feature_column  = "[categorical_col]",
  target_value    = "[matching_value]",
  split           = c(0.33, 0.66)
)
# New column: [new_col] (values: [matching_value]_low, [matching_value]_mid, [matching_value]_high)
```

#### Decision: Type 2 vs Type 7

| Plan2 says | Use |
|------------|-----|
| "Split samples by avg expression of GENE in target cell type" | **Type 2** (`create_gene_based_groups`) — convenience wrapper for a gene |
| "Split samples by mean of a SCORE / module / feature column per sample" | **Type 7** (`create_groups_from_per_sample_summary`, `summary_type = "mean"`) |
| "Split samples by % of cells matching some condition per sample" | **Type 7** (`summary_type = "percentage"`) |
| "Add the per-sample percentage / mean as a numeric covariate (NOT a group)" | **Type 6** (`add_per_sample_summary`) |

---

## Ordering Rules

1. **Gene lists first** — if a GO term is used to create a gene list that feeds into
   add_pathway_score, fetch the gene list before calling add_pathway_score.
2. **Module scores before per-sample summaries that use them** — Type 6 / Type 7
   often summarise a score column (e.g., mean of `EMT_score1` per sample), so
   add the score first, then the summary.
3. **Module scores before gene groups** — if a gene group depends on a score
   (unlikely but possible), add the score first.
4. **Extra metadata before anything that uses it** — if `add_extra_meta` brings in
   columns referenced by later steps (e.g., a new cell-type column), call it first.
5. **Composite gating before gene groups / per-sample summaries that target the
   new label** — if `gate_cells_composite` creates a new cell-type label that a
   downstream step uses as `target_celltype`, gate first.
6. **Follow plan2.txt order** — the plan2 already has the correct order.

---

## Validation

After each step, verify the column was created:
```r
stopifnot("[pathway]_score1" %in% colnames(seurat_obj@meta.data))
```

Or softer:
```r
if (!"[pathway]_score1" %in% colnames(seurat_obj@meta.data)) {
  warning("Expected column [pathway]_score1 not found after preprocessing step #N")
}
```

Prefer the soft check — don't crash the whole script if one step fails.

---

## Common Errors

| Wrong | Right |
|-------|-------|
| `library(MSigDB)` | `library(msigdbr)` — lowercase |
| `msigdbr(category = "H")` (deprecated in ≥10.0) | `msigdbr(collection = "H")` — `category`/`subcategory` are deprecated |
| `subcollection = "CP:KEGG"` (no longer exists) | `subcollection = "CP:KEGG_LEGACY"` for classic KEGG sets |
| `msigdbr(category = "hallmark")` | `msigdbr(collection = "H")` — use code letters |
| `filter(gs_name == "Glycolysis")` | `filter(gs_name == "HALLMARK_GLYCOLYSIS")` — exact MSigDB name |
| Not calling `unique()` on msigdbr genes | Always `%>% unique()` — msigdbr has duplicate gene entries |
| `pathway_name = "EMT_score"` | `pathway_name = "EMT"` — the function appends `_score1` |
| `patient_column = "sample"` | `sample_column = "sample"` — the parameter is `sample_column` |
| Using `$MYC_group` without backticks | `seurat_obj@meta.data[["MYC_group"]]` — safer |
| Forgetting to save metadata to CSV | Always end with `write.csv(seurat_obj@meta.data, "Working/processed_meta.csv", row.names = TRUE)` |
| Saving an .rds file at the end | Don't — only the metadata CSV is needed for the analysis script |
| Inlining per-sample broadcast with `seurat_obj$col <- vec[...]` | Use `add_per_sample_summary()` (Type 6) — handles the `@meta.data` write internally |
| Inlining `left_join` for sample-level group labels | Use `create_groups_from_per_sample_summary()` (Type 7) — handles rownames safely |
