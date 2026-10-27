# Task Plan Step 1 Skill - Quick Reference

## Purpose
Convert `plan0.txt` (categorized validation plan from step 0) into a unified
execution plan with concrete preprocessing steps and concrete function calls
for every analysis task.

## Files

| Type      | Path                                                                                          |
|-----------|-----------------------------------------------------------------------------------------------|
| Input     | `Working/plan0.txt` (categorized plan from step 0)                                            |
| Input     | `Working/definitions_final.txt` (term definitions + recommended gene lists)                   |
| Input     | `Outputs/data_pre.txt` (native metadata summary)                                              |
| Input     | `Working/data_pre_add.txt` (added annotation columns — **optional**, may or may not exist)    |
| Reference | `~/.claude/agents/Ref/Task_Plan_step1_v3/references/preprocess.R`          |
| Reference | `~/.claude/agents/Ref/Task_Plan_step1_v3/references/function_v2.R`         |
| Output    | `Working/plan2.txt`                                                                           |

`Working/data_pre_add.txt` may or may not exist. If it does, read it — its
columns are already integrated into the Metadata Index of `plan0.txt`. This
file is the upstream pair of the `add_extra_meta` preprocessing function:
columns that live here (rather than in the Seurat object) need an
`add_extra_meta` step at the top of `plan2.txt` so the columns are merged in
before any analysis uses them.

The R reference files (`preprocess.R`, `function_v2.R`) live **inside the
agent folder**.

## Workflow

```
Read plan0.txt + definitions + data_pre + data_pre_add (if present) + function docs
  -> Stage 1: Extract preprocessing steps (deduplicated)
  -> Stage 2: Map each Section 2 piece + Extra Test to concrete function calls
  -> Working/plan2.txt
```

## Top-Level Rules

- **Use the Metadata Index from `plan0.txt`** for every column name (sample
  column, condition columns, celltype columns, stratification columns).
  Do not invent column names from `data_pre.txt` directly — step 0 already
  resolved which columns to use.
- **Deduplicate** preprocessing: same score / same gene group / same gated
  subtype = listed once.
- **Deduplicate** DE: same gene split + same cell type = one `run_de_analysis`
  call; other pieces say "Reuse DE from Task X."
- **One bullet = one function call** (or one GO enrichment step).
- **Every parameter must be filled in** with a real value — no `TBD`, no
  vague placeholders.
- **Gene lists** for scores: check `definitions_final.txt` first, then
  MSigDB / KEGG.
- **Correlations auto-stratify** via `condition_col` — do NOT create separate
  stratified correlation tasks.
- **Stratified subsetting** is only needed for boxplots and DE.
- **DE direction (V2)** — pass `de_result$up_condition` /
  `down_condition` into `run_go_enrichment`'s `label` so direction is
  recorded correctly.
- **Assume preprocessing is done** when writing analysis tasks (reference
  the output columns directly, e.g., `value_name = "hypoxia_score1"`).
- **Reuse preprocessing across pieces.** When `plan0.txt` notes "(reuse)"
  for a score or gene group, point at the earlier preprocessing entry — do
  not duplicate.

## Preprocessing Functions

| Need                              | Function                                          | Output                              |
|-----------------------------------|---------------------------------------------------|-------------------------------------|
| Pathway / signature score         | `add_pathway_score(obj, genes, name)`             | `{name}_score1` metadata column     |
| Gene-high / gene-low sample split | `create_gene_based_groups(...)`                   | `{gene}_group` metadata column      |
| Gene list from a GO term          | `pull_out_gene_list_from_GO(GO_term)`             | character vector                    |
| Composite gated subtype           | `gate_cells_composite(...)`                       | new cell-type annotation column     |
| External metadata from CSV        | `add_extra_meta(obj, csv_path)`                   | new metadata columns (from CSV)     |
| Combined group column             | inline base-R: `seurat_obj$col1_col2 <- paste(seurat_obj$col1, seurat_obj$col2, sep="_")` (no `preprocess.R` function) | `{col1}_{col2}` metadata column     |

**Prefer existing annotation proportions over module scores.** If the
Metadata Index in `plan0.txt` already encodes the concept (e.g., a `Phase`
column with `G1`/`S`/`G2M` categories, or a refined-subtype column from
`data_pre_add.txt`), use the per-sample proportion of the relevant category
in the analysis instead of computing a new module score. Step 0 already
flagged this; step 1 just respects the choice.

## Analysis Function Mapping

| plan0 describes                                           | Function                                                            |
|-----------------------------------------------------------|---------------------------------------------------------------------|
| Correlation (gene vs gene, or gene vs score)              | `correlate_celltype_features`                                       |
| Correlation (gene vs cell subtype proportion)             | `correlate_celltype_features` with `feature_B_type = "percentage"`  |
| Boxplot: GENE-high vs GENE-low, compare Y                 | `compare_features_boxplot` with `group_col = "{GENE}_group"`         |
| Boxplot: gene across cell types (no condition split)      | `compare_features_boxplot`, `group_col = celltype_col`, `celltype = NULL` |
| Boxplot: gene between conditions                          | `compare_features_boxplot`, `group_col = condition_col`             |
| Boxplot: gene across combined groups                      | `compare_features_boxplot`, `group_col = combined_col` (e.g., `gender_condition`) |
| DE + Enrichment                                           | `run_de_analysis` + `run_go_enrichment` (up and down separately)    |
| Cell-type proportion comparison                           | `compare_celltype_by_group`                                         |

## Mapping Detail Rules

- Correlations auto-stratify by `condition_col` -> no separate stratified
  correlation tasks.
- `run_de_analysis` returns `up_condition` and `down_condition` (V2). Thread
  them into the matching `run_go_enrichment` `label` argument.
- Stratified subsetting is only for boxplots and DE.
- Cell-type comparisons (gene across cell types) pool all samples — no
  condition split.
- **≤5 target genes**: individual correlation plots + combined score plot.
- **>5 target genes**: combined score only; individual correlations stored
  as values (no plots).
- Combine similar boxplots -> create a combined group column
  (e.g., `gender_condition`) and produce ONE boxplot rather than several.
- Extra tests stay high-level: ONE simple analysis each, no per-gene
  breakdowns.
- Each analysis bullet should also include a `From plan0:` link back to
  the originating piece, mirroring the `From brainstorm:` link that step 0
  used to connect plan0 back to the brainstorm.

## Output Structure of plan2.txt

1. Header (paper / dataset info pulled from the top of `plan0.txt`)
2. PREPROCESSING (deduplicated, numbered, with function + inputs + output +
   gene list + used-by)
3. ANALYSIS TASKS (organized by piece; each bullet = one function call with
   all parameters filled in)
4. EXTRA TESTS
5. SUMMARY COUNTS
