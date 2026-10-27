# Analysis Code Rules

## Goal
Translate every analysis task from plan2.txt into executable R code in a single
analysis.R script. Includes direction-aware DE/enrichment labels and RAM-efficient
result handling.

---

## Plot Dimensions

| Plot type | Width | Height |
|-----------|-------|--------|
| Correlation | 8 | 6 |
| Boxplot (few groups) | 6 | 6 |
| Boxplot (many groups / cell types) | 10 | 6 |
| Volcano (DE) | 10 | 8 |
| **GO enrichment dotplot** | **10** | **12** |

**IMPORTANT:** GO enrichment dotplots MUST use `height = 12` (not 8). GO term
names are long (e.g., "antigen processing and presentation of exogenous peptide
antigen via MHC class II") and overlap badly at smaller heights.

---

## Script Structure

```r
# === ANALYSIS SCRIPT ===
# Generated from plan2.txt
# Run AFTER preprocess.R

# --- Libraries ---
library(Seurat)
library(ggplot2)
library(dplyr)
library(tidyverse)
library(msigdbr)     # for pathway gene sets in enrichment

# --- Source analysis functions ---
source("~/.claude/agents/Ref/Code_Agent_v4/references/function_v2.R")

# --- Load raw data and merge processed metadata ---
cat("Loading raw Seurat object...\n")
seurat_obj <- readRDS("Inputs/data.rds")
cat("Loaded:", ncol(seurat_obj), "cells\n")

cat("Loading processed metadata from preprocess.R...\n")
processed_meta <- read.csv("Working/processed_meta.csv", row.names = 1,
                           stringsAsFactors = FALSE)

# Merge in only the NEW columns (those created by preprocess.R)
new_cols <- setdiff(colnames(processed_meta), colnames(seurat_obj@meta.data))
cat("Adding", length(new_cols), "new metadata columns:",
    paste(new_cols, collapse = ", "), "\n")
seurat_obj <- AddMetaData(seurat_obj, metadata = processed_meta[, new_cols, drop = FALSE])

# --- Create output directories ---
dir.create("Outputs/plots", recursive = TRUE, showWarnings = FALSE)
dir.create("Outputs/results", recursive = TRUE, showWarnings = FALSE)

# ===================================================================
# ANALYSIS TASKS
# ===================================================================

# [task code blocks here]

# ===================================================================
# COMPLETE
# ===================================================================
cat("\n\n========== ANALYSIS COMPLETE ==========\n")
```

**Why this load pattern?** `preprocess.R` does not save an .rds file — only a
metadata CSV (`Working/processed_meta.csv`). To recover the full Seurat object
with the preprocessing additions, `analysis.R` reloads the original
`Inputs/data.rds` and uses `AddMetaData()` to merge in the new columns by cell
barcode (the CSV's row names).

We restrict the merge to columns NOT already present so that the standard
Seurat columns (`nCount_RNA`, `nFeature_RNA`, etc.) are not overwritten by
their stringified CSV versions.

---

## Translating Each Function Type

### correlate_celltype_features (Pattern A — rm immediately)

```r
# --- Task 4.1.a: MYC ~ MKI67 correlation in Tumor ---
tryCatch({
  .tmp <- correlate_celltype_features(
    seurat_obj = seurat_obj,
    celltype_A = "Tumor",
    celltype_B = "Tumor",
    feature_A_type = "gene",
    feature_B_type = "gene",
    feature_A_name = "MYC",
    feature_B_name = "MKI67",
    sample_col = "sample",
    condition_col = "condition",
    celltype_A_col = "celltype",
    celltype_B_col = "celltype"
  )
  ggsave("Outputs/plots/piece4.1_corr_MYC_MKI67_Tumor.pdf",
         .tmp$plot, width = 8, height = 6)
  cat("=== Task 4.1.a: MYC ~ MKI67 correlation ===\n")
  print(.tmp$correlation)
  rm(.tmp); gc()
}, error = function(e) {
  cat("ERROR in Task 4.1.a:", conditionMessage(e), "\n")
})
```

**Note on percentage_mode:** if either feature is a cell-type percentage, also pass
`percentage_mode_A` / `percentage_mode_B` ("total" or "broad") and, if "broad",
`broad_cell_A` / `broad_cell_B` and `broad_cell_col`.

### compare_features_boxplot (Pattern A — rm immediately)

```r
# --- Task 2.1.a: MYC across cell types ---
tryCatch({
  .tmp <- compare_features_boxplot(
    seurat_obj = seurat_obj,
    value_type = "gene",
    value_name = "MYC",
    group_col = "celltype",
    celltype = NULL,
    celltype_col = "celltype",
    sample_col = "sample"
  )
  ggsave("Outputs/plots/piece2.1_boxplot_MYC_across_celltypes.pdf",
         .tmp$plot, width = 10, height = 6)
  cat("=== Task 2.1.a: MYC across cell types ===\n")
  print(.tmp$pairwise_tests)
  rm(.tmp); gc()
}, error = function(e) {
  cat("ERROR in Task 2.1.a:", conditionMessage(e), "\n")
})
```

### run_de_analysis + GO enrichment (Pattern B — keep for enrichment, then rm)

**RULE: Always save DE significant genes to CSV** after saving the volcano plot,
before GO enrichment. Use the same naming convention as the volcano plot:
`de_{GENE}_high_vs_low_{CELLTYPE}_posLogFC_meanUP_in_{up_condition}.csv`

```r
# ===================================================================
# Piece 4.1: DE and enrichment
# ===================================================================

# --- Task 4.1.c: DE — MYC-high vs MYC-low in Tumor ---
result_4_1_c <- tryCatch({
  run_de_analysis(
    seurat_obj = seurat_obj,
    celltype = "Tumor",
    celltype_col = "celltype",
    condition_col = "MYC_group",
    condition1 = "MYC_high",
    condition2 = "MYC_low",
    sample_col = "sample",
    title = "Tumor: MYC-high vs MYC-low"
  )
}, error = function(e) {
  cat("ERROR in Task 4.1.c:", conditionMessage(e), "\n")
  NULL
})



if (!is.null(result_4_1_c)) {
  up_4_1   <- result_4_1_c$up_condition
  down_4_1 <- result_4_1_c$down_condition
  ggsave(paste0("Outputs/plots/piece4.1_volcano_MYC_high_vs_low_Tumor_posLogFC_meanUP_in_", up_4_1, ".pdf"),result_4_1_c$volcano_plot, width = 10, height = 8)
  write.csv(result_4_1_c$significant_genes,
            paste0("Outputs/results/de_MYC_high_vs_low_Tumor_posLogFC_meanUP_in_", up_4_1, ".csv"),
            row.names = FALSE)

  cat("=== Task 4.1.c: DE MYC-high vs low in Tumor ===\n")
  cat("Sig up in", result_4_1_c$up_condition, ":", result_4_1_c$n_sig_up, "\n")
  cat("Sig up in", result_4_1_c$down_condition, ":", result_4_1_c$n_sig_down, "\n")

  # --- Task 4.1.d: GO enrichment — upregulated genes ---
  tryCatch({
    up_genes_4_1 <- result_4_1_c$significant_genes %>%
      filter(avg_logFC > 0) %>% pull(gene)
    .go_up <- run_go_enrichment(
      gene_list = up_genes_4_1,
      organism = "human",
      ont = "BP",
      label = paste("Upregulated in", result_4_1_c$up_condition, "- Tumor")
    )
    if (!is.null(.go_up$plot)) {
      ggsave(paste0("Outputs/plots/piece4.1_go_MYC_high_vs_low_Tumor_UP_in_", up_4_1, ".pdf"), .go_up$plot, width = 10, height = 12)
    }
    if (is.data.frame(.go_up$result)) {
      write.csv(.go_up$result, paste0("Outputs/results/go_MYC_high_vs_low_Tumor_UP_in_", up_4_1, ".csv"), row.names = FALSE)
    }
    rm(.go_up, up_genes_4_1); gc()
  }, error = function(e) {
    cat("ERROR in GO enrichment (up) 4.1.d:", conditionMessage(e), "\n")
  })

  # --- Task 4.1.e: GO enrichment — downregulated genes ---
  tryCatch({
    down_genes_4_1 <- result_4_1_c$significant_genes %>%
      filter(avg_logFC < 0) %>% pull(gene)
    .go_down <- run_go_enrichment(
      gene_list = down_genes_4_1,
      organism = "human",
      ont = "BP",
      label = paste("Upregulated in", result_4_1_c$down_condition, "- Tumor")
    )
    if (!is.null(.go_down$plot)) {
      ggsave(paste0("Outputs/plots/piece4.1_go_MYC_high_vs_low_Tumor_UP_in_", down_4_1, ".pdf"), .go_down$plot, width = 10, height = 12)
    }
    if (is.data.frame(.go_down$result)) {
      write.csv(.go_down$result, paste0("Outputs/results/go_MYC_high_vs_low_Tumor_UP_in_", down_4_1, ".csv"), row.names = FALSE)
    }
    rm(.go_down, down_genes_4_1); gc()
  }, error = function(e) {
    cat("ERROR in GO enrichment (down) 4.1.e:", conditionMessage(e), "\n")
  })

  # If NO later task says "Reuse DE from 4.1.c", rm now:
  rm(result_4_1_c); gc()
  # If a later task DOES reuse this, move the rm() to after that task.
}
```

### DE Reuse

When plan2 says "Reuse DE from Task X":
```r
# --- Task 5.2.c: Reuse DE from Task 4.1.c ---
# DE results already stored in result_4_1_c
# Do NOT rm result_4_1_c until after this block
cat("Task 5.2.c: Reusing DE results from Task 4.1.c\n")
cat("Direction: positive logFC = up in", result_4_1_c$up_condition, "\n")

# [any additional enrichment using result_4_1_c here]

# NOW safe to rm if no more reuse:
rm(result_4_1_c); gc()
```

### Stratified Analysis (Pattern A)

```r
# --- Task 4.1.a-strat-condition: Stratified MYC ~ MKI67 by condition ---
for (cond_val in c("Primary", "Recurrent")) {
  cat(paste0("\n--- Stratified: ", cond_val, " ---\n"))
  tryCatch({
    sub_obj <- subset(seurat_obj, condition == cond_val)
    .tmp <- correlate_celltype_features(
      seurat_obj = sub_obj,
      celltype_A = "Tumor",
      celltype_B = "Tumor",
      feature_A_type = "gene",
      feature_B_type = "gene",
      feature_A_name = "MYC",
      feature_B_name = "MKI67",
      sample_col = "sample",
      condition_col = "condition",
      celltype_A_col = "celltype",
      celltype_B_col = "celltype"
    )
    safe_name <- gsub(" ", "_", cond_val)
    ggsave(paste0("Outputs/plots/piece4.1_corr_MYC_MKI67_", safe_name, ".pdf"),
           .tmp$plot, width = 8, height = 6)
    print(.tmp$correlation)
    rm(.tmp, sub_obj); gc()
  }, error = function(e) {
    cat("ERROR in stratified 4.1.a (", cond_val, "):", conditionMessage(e), "\n")
  })
}
```

### Looped Correlations (collect summary only)

```r
# --- Task 5.2.d: Individual MYC vs MAPK pathway genes ---
mapk_targets <- c("MAPK1", "MAPK3", "MAP2K1", "MAP2K2", "RAF1",
                  "BRAF", "KRAS", "HRAS", "NRAS", "DUSP1",
                  "DUSP6", "FOS", "JUN", "EGR1")

corr_summary_5_2_d <- data.frame(gene = character(), rho = numeric(), pval = numeric())

for (gene in mapk_targets) {
  cat(paste0("Correlating MYC vs ", gene, "...\n"))
  tryCatch({
    .tmp <- correlate_celltype_features(
      seurat_obj = seurat_obj,
      celltype_A = "Tumor",
      celltype_B = "Tumor",
      feature_A_type = "gene",
      feature_B_type = "gene",
      feature_A_name = "MYC",
      feature_B_name = gene,
      sample_col = "sample",
      condition_col = "condition",
      celltype_A_col = "celltype",
      celltype_B_col = "celltype"
    )
    ggsave(paste0("Outputs/plots/piece5.2_corr_MYC_vs_", gene, ".pdf"),
           .tmp$plot, width = 8, height = 6)
    corr_summary_5_2_d <- rbind(corr_summary_5_2_d, data.frame(
      gene = gene,
      rho = .tmp$correlation$estimate,
      pval = .tmp$correlation$p.value
    ))
    rm(.tmp); gc()
  }, error = function(e) {
    cat("  ERROR for", gene, ":", conditionMessage(e), "\n")
  })
}

cat("=== Individual MAPK gene correlations with MYC ===\n")
print(corr_summary_5_2_d)
rm(corr_summary_5_2_d); gc()
```

### compare_celltype_by_group (Pattern A)

```r
tryCatch({
  .tmp <- compare_celltype_by_group(
    seurat_obj = seurat_obj,
    group_col = "MYC_group",
    sample_col = "sample",
    celltype = "CD8 TCells",
    celltype_col = "refine_celltype",
    percentage_mode = "total"
  )
  ggsave("Outputs/plots/pieceX_celltype_CD8T_by_MYC.pdf",
         .tmp$plot, width = 6, height = 6)
  cat("=== Cell type comparison ===\n")
  print(.tmp$test)
  rm(.tmp); gc()
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
})
```

If percentage should be relative to a broader category (e.g., CD8 T cells as a
fraction of all T cells), pass `percentage_mode = "broad"` together with
`broad_cell` and `broad_cell_col`.

---

## Plot Dimensions Guide

| Plot type | Width | Height |
|-----------|-------|--------|
| Scatter (correlation) | 8 | 6 |
| Boxplot (2 groups) | 6 | 6 |
| Boxplot (many groups) | 10 | 6 |
| Volcano plot | 10 | 8 |
| Violin plot | 6 | 6 |
| GO dotplot | 10 | 12 |

---

## Common Errors

| Wrong | Right |
|-------|-------|
| `cat("Up:", result$n_sig_up)` (no direction) | `cat("Up in", result$up_condition, ":", result$n_sig_up)` |
| `run_go_enrichment(..., label = "Upregulated")` | `run_go_enrichment(..., label = paste("Upregulated in", de_result$up_condition))` |
| Keeping all results in memory | `rm(.tmp); gc()` after saving |
| `all_results[["task_X"]] <- result` | Don't collect — just print and rm |
| Forgetting `gc()` after `rm()` | Always pair: `rm(...); gc()` |
| rm'ing a DE result before its "Reuse DE" task | Check dependency map first |


---

## Verification Checklist

| # | Check |
|---|-------|
| 1 | analysis.R sources `~/.claude/agents/Ref/Code_Agent_v4/references/function_v2.R`? |
| 2 | preprocess.R sources `~/.claude/agents/Ref/Code_Agent_v4/references/preprocess.R`? |
| 3 | preprocess.R writes `Working/processed_meta.csv` (no .rds)? |
| 4 | analysis.R reads `Inputs/data.rds` and merges the CSV via `AddMetaData()`? |
| 5 | Every plan2 task has a code block? |
| 6 | Every DE volcano has direction in subtitle? |
| 7 | Every GO enrichment label includes direction? |
| 8 | Every one-off result uses Pattern A (tryCatch + rm + gc)? |
| 9 | DE results kept only until downstream enrichment/reuse is done? |
| 10 | No `all_results` list accumulating objects? |
| 11 | Score column names consistent (`_score1` suffix)? |
| 12 | Group column names consistent (`_group` suffix)? |
| 13 | Every DE analysis has `write.csv(result$significant_genes, ...)` after volcano ggsave? |
| 14 | "Reuse DE" variables not rm'd too early? |
| 15 | `gc()` follows every `rm()`? |
| 16 | Output directories created at top? |
| 17 | All plots saved with null guards? |
