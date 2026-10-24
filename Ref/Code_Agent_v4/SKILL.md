# Code Agent Skill - Quick Reference

## Purpose
Generate executable R scripts from plan2.txt that perform all preprocessing and analysis tasks using the provided function templates against a Seurat scRNA-seq dataset.


## Files

| Type | Path |
|------|------|
| Input | `Working/plan2.txt` (unified execution plan) |
| Input (function source) | `~/.claude/agents/Ref/Code_Agent_v4/references/function_v2.R` (analysis functions) |
| Input (function source) | `~/.claude/agents/Ref/Code_Agent_v4/references/preprocess.R` (preprocessing functions) |
| Output | `Outputs/preprocess.R` (preprocessing script) |
| Output | `Outputs/analysis.R` (analysis script) |
| Intermediate | `Working/processed_meta.csv` (metadata-only handoff written by preprocess.R, loaded by analysis.R) |

## Workflow
```
Read plan2.txt → Generate Outputs/preprocess.R → Generate Outputs/analysis.R
Run order: preprocess.R first → analysis.R second
```

**Data handoff between scripts (NO RDS saved):**
- `preprocess.R` reads `Inputs/data.rds`, adds new metadata columns (scores, groups, etc.), and writes ONLY the metadata to `Working/processed_meta.csv` via `write.csv(seurat_obj@meta.data, ...)`.
- `analysis.R` reads `Inputs/data.rds` fresh, then uses `AddMetaData()` to merge `Working/processed_meta.csv` back in by cell barcode.

## Quick Rules

- **plan2.txt is the blueprint** — translate every step to code, no more, no less
- **Two scripts**: preprocess.R (data prep) → analysis.R (all tasks)
- **Source `function_v2.R`** in analysis.R (full path above)
- **Source `preprocess.R`** in preprocess.R (full path above)
- **Exact parameter values** from plan2.txt
- **tryCatch every task**
- **rm + gc after each task** — don't accumulate results in memory
- **Label DE direction** — volcano subtitle + GO enrichment label must state which condition is "up"
- **Save every plot** to `Outputs/plots/` as PDF
- **Save DE significant genes** to `Outputs/results/de_*.csv` after each volcano plot
- **Pairwise test p-values** auto-saved by boxplot function to `Outputs/results/all_pairwise_tests.txt`
- **Never save .rds** — metadata is the only thing that crosses between scripts, via CSV
- **Never inline a per-sample broadcast** — use `add_per_sample_summary()` / `create_groups_from_per_sample_summary()` (Types 6 and 7)

## Available Preprocessing Functions

| Type | Function | When to use |
|------|----------|-------------|
| 1 | `add_pathway_score` | Add a module score from a gene list (`X_score1` column) |
| 2 | `create_gene_based_groups` | Sample-level high/low group from avg expression of ONE gene in a cell type |
| 3 | `pull_out_gene_list_from_GO` | Fetch a gene list from a GO term (feeds Type 1) |
| 4 | `add_extra_meta` | Merge a CSV of per-cell annotations |
| 5 | `gate_cells_composite` | Define a cell subtype by mixed high/mid/low gene gating |
| 6 | `add_per_sample_summary` | Compute a per-sample number (%, count, mean, median, sum) and broadcast it as a per-cell numeric column |
| 7 | `create_groups_from_per_sample_summary` | Same per-sample number, then bin into a `_high` / `_low` (or `_high` / `_mid` / `_low`) group label |

## RAM-Efficient Patterns

### Pattern A — One-off results (boxplots, correlations, cell type comparisons)
```r
tryCatch({
  .tmp <- some_function(...)
  ggsave("Outputs/plots/...", .tmp$plot, width = 8, height = 6)
  cat("=== Task X.Y ===\n"); print(.tmp$stats)
  rm(.tmp); gc()
}, error = function(e) cat("ERROR:", conditionMessage(e), "\n"))
```

### Pattern B — DE → Enrichment chains
```r
result_X <- tryCatch({ run_de_analysis(...) }, error = ...)
if (!is.null(result_X)) {
  ggsave("...", result_X$volcano_plot, ...)
  # GO enrichment with direction labels
  up_genes <- result_X$significant_genes %>% filter(avg_logFC > 0) %>% pull(gene)
  .go <- run_go_enrichment(up_genes, label = paste("Upregulated in", result_X$up_condition))
  if (!is.null(.go$plot)) ggsave("...", .go$plot, ...); rm(.go); gc()
  # ... same for down_genes ...
  # rm DE result only after ALL downstream tasks are done
  rm(result_X); gc()
}
```

### Decision: Keep vs rm
- Result used only in this block → rm immediately (Pattern A)
- Result referenced by later "Reuse DE" → keep until all downstream done, then rm (Pattern B)

## DE Direction Convention

Libra sorts conditions alphabetically. First alphabetically = reference.
- **Positive logFC = up in the alphabetically LATER condition**
- `run_de_analysis()` returns `up_condition` (positive logFC) and `down_condition` (negative logFC)
- Use these in GO enrichment labels

Example: condition1 = "MYC_high", condition2 = "MYC_low"
- Sorted: MYC_high < MYC_low
- up_condition = "MYC_low" (positive logFC = up here)
- down_condition = "MYC_high" (negative logFC = up here)

## Variable Naming

| What | Pattern | Example |
|------|---------|---------|
| One-off result (rm immediately) | `.tmp` | `.tmp` |
| DE result (kept for enrichment) | `result_[piece]_[task]` | `result_4_1_c` |
| GO enrichment (rm immediately) | `.go_up`, `.go_down` | `.go_up` |
| Looped summary | `corr_summary` (data.frame) | `corr_summary` |
| Plot file | `piece[ID]_[type]_[feature]_[context].pdf` | `piece4.1_corr_MYC_MKI67.pdf` |

## Gene List Resolution

| plan2 says | Code to write |
|------------|---------------|
| Explicit genes: c("A", "B", "C") | `genes <- c("A", "B", "C")` |
| MSigDB HALLMARK_GLYCOLYSIS | `msigdbr(species = "Homo sapiens", collection = "H") %>% filter(gs_name == "HALLMARK_GLYCOLYSIS") %>% pull(gene_symbol)` |
| MSigDB KEGG (legacy)       | `msigdbr(species = "Homo sapiens", collection = "C2", subcollection = "CP:KEGG_LEGACY") %>% filter(gs_name == "KEGG_GLYCOLYSIS_GLUCONEOGENESIS") %>% pull(gene_symbol)` |
| GO term: GO:XXXXXXX | `pull_out_gene_list_from_GO("GO:XXXXXXX")` |

> **msigdbr ≥ 10.0 API change:** use `collection` / `subcollection` (NOT the deprecated `category` / `subcategory`). The KEGG subcollection has been split into `CP:KEGG_LEGACY` (the classic ~186 sets, including `KEGG_GLYCOLYSIS_GLUCONEOGENESIS`) and `CP:KEGG_MEDICUS`. The plain `"CP:KEGG"` no longer exists and will throw `Unknown subcollection`.

## Per-Sample Stat Resolution

| plan2 says | Code to write |
|------------|---------------|
| "Avg expression of GENE per sample → high/low groups" | `create_gene_based_groups(...)` (Type 2) |
| "Mean of SCORE per sample → high/low groups" | `create_groups_from_per_sample_summary(..., summary_type = "mean", split = "median")` (Type 7) |
| "% of cells matching condition X per sample → high/low groups" | `create_groups_from_per_sample_summary(..., summary_type = "percentage", split = "median")` (Type 7) |
| "Add the per-sample percentage / mean as a numeric covariate (NOT a group)" | `add_per_sample_summary(...)` (Type 6) |

> **Never inline this with `seurat_obj$col <- per_sample_vec[meta$sample]`** — that errors with "No cell overlap between new meta data and Seurat object". The two functions above handle the broadcast safely.

## Critical Checks Before Writing

- Every plan2 preprocessing step → code block in preprocess.R?
- Every plan2 analysis task → code block in analysis.R?
- Score column names match between preprocess.R and analysis.R? (e.g., `EMT_score1`)
- Group column names match? (e.g., `MYC_group`)
- "Reuse DE" references → variable exists AND hasn't been rm'd yet?
- All plots saved? All stats printed?
- **preprocess.R sources `~/.claude/agents/Ref/Code_Agent_v4/references/preprocess.R`?**
- **analysis.R sources `~/.claude/agents/Ref/Code_Agent_v4/references/function_v2.R`?**
- **preprocess.R writes `Working/processed_meta.csv` (NOT a .rds)?**
- **analysis.R re-reads `Inputs/data.rds` and merges the CSV via `AddMetaData()`?**
- **Every GO enrichment label includes direction?** (up_condition / down_condition)
- **Every result rm'd after use?** (except those needed by later tasks)
- **gc() called after every rm()?**
- **msigdbr uses `collection` / `subcollection` (not deprecated `category` / `subcategory`)?**
- **No inline per-sample broadcasts** (always use Types 6 / 7)?
