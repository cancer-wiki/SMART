# Common Errors in Step 1 Execution Plan

---

### 1. Score column name wrong

Wrong: `value_name = "hypoxia_score"` or `value_name = "hypoxia"`
Right: `value_name = "hypoxia_score1"`

Rule: `AddModuleScore` appends `_score1` (with the "1"). The output column
from `add_pathway_score(pathway_name = "hypoxia")` is `hypoxia_score1`.

---

### 2. Group column vs group values confused

Wrong: `group_col = "SRSF3_high"` (this is a value, not a column)
Right: `group_col = "SRSF3_group"` (this is the column name)

The column is `{gene_name}_group`. The values inside are `{gene_name}_high`
and `{gene_name}_low`.

For `run_de_analysis`:
- `condition_col = "SRSF3_group"` (the column)
- `condition1 = "SRSF3_high"` (a value)
- `condition2 = "SRSF3_low"` (a value)

---

### 3. Correlation and boxplot merged into one bullet

Wrong: one bullet that says "correlate + boxplot"
Right: two separate bullets — one `correlate_celltype_features` call and
one `compare_features_boxplot` call.

---

### 4. DE listed multiple times for the same split

Wrong: three separate `run_de_analysis` calls for SRSF3-high vs low in
Tumor.
Right: one `run_de_analysis` call. Other pieces say "Reuse DE from Task X."

---

### 5. GO enrichment merged into the DE bullet

Wrong: one bullet that says "DE + GO enrichment".
Right: `run_de_analysis` is one bullet; `run_go_enrichment` is a separate
bullet. Run enrichment separately for upregulated and downregulated genes
(two bullets).

---

### 5b. GO enrichment label ignores V2 direction fields

Wrong: `label = "Upregulated in SRSF3-high"` (hardcoded; may not match
which direction `run_de_analysis` actually computed as positive logFC).
Right: `label = paste("Upregulated in", de_result$up_condition)` (uses the
V2 direction fields returned by `run_de_analysis`).

Rule: Libra sorts condition labels alphabetically, so the direction that
corresponds to "positive logFC" is set by `run_de_analysis` based on that
sort. Always consume `up_condition` / `down_condition` rather than
re-guessing.

---

### 6. Missing required parameters

Wrong: `correlate_celltype_features(celltype_A = "Tumor", feature_A_name = "SRSF3", ...)`
  — missing `condition_col`, `sample_col`, celltype columns.
Right: all parameters specified with actual values.

---

### 6b. Unnecessary stratified correlation tasks

Wrong: creating separate "Stratified repeat of correlation by condition"
tasks.
Right: `correlate_celltype_features` already computes
`correlation_by_condition` when `condition_col` is set. Just set
`condition_col` properly.

Rule: stratified subsetting is only for boxplots and DE. Correlations
auto-stratify.

---

### 7. Vague cell type names

Wrong: `celltype = "tumor cells"` or `celltype = "malignant"`
Right: `celltype = "Tumor"` (exact value from the metadata)

Always use the exact string as it appears in the metadata column.

---

### 8. Stratification without specifying subset values

Wrong: "Stratify by condition"
Right: "Subset to condition == 'primary', re-run Task X" AND
       "Subset to condition == 'metastatic', re-run Task X"

---

### 9. Preprocessing step listed but not used

Wrong: creating a gene group for a gene that no analysis task uses.
Right: only create preprocessing steps that are actually referenced by
tasks.

---

### 10. Gene symbol mismatch

Wrong: `feature_B_name = "LDHB2"` (a protein isoform name)
Right: `feature_B_name = "LDHB"` (the gene symbol) — but note to verify in
data.

Always note if uncertain: "Note: verify gene symbol in Seurat object".

---

### 11. Forgetting to list the gene list source for scores

Wrong: `pathway_genes = [hypoxia genes]`
Right: `pathway_genes = msigdbr(category = "H") %>% filter(gs_name == "HALLMARK_HYPOXIA")`
  OR an explicit gene list with source noted.

---

### 12. Extra tests not mapped to functions

Wrong: copying the Extra Test text from plan0 without converting to
function calls.
Right: same treatment as Section 2 pieces — each extra test gets concrete
function-call bullets.

---

### 13. `celltype = NULL` when it should be specific

For `compare_features_boxplot`:
- `celltype = NULL` + `group_col` = celltype column → compares across ALL
  cell types.
- `celltype = "Tumor"` + `group_col` = condition column → compares within
  Tumor by condition.

Make sure the combination matches what plan0 describes.

---

### 14. Computing a module score when plan0 says use existing annotation

Wrong: `add_pathway_score` for an apoptosis signature when plan0 says
"use proportion of `CellState == 'Apoptotic'` per sample".
Right: respect plan0 — no preprocessing for the score; use
`correlate_celltype_features` with `feature_B_type = "percentage"`,
       `celltype_B = "Apoptotic"`, `celltype_B_col = "CellState"`.

Rule: step 0 already decided whether to use a module score or an existing
annotation proportion. Step 1 follows that decision.

---

### 15. Stratified cell-type comparison by condition

Wrong: Task 12.1.a (TMSB10 across cell types) +
       Task 12.1.a-strat-condition-primary +
       Task 12.1.a-strat-condition-metastatic.
Right: Task 12.1.a only (pool all samples, no condition split).

Rule: gene-across-cell-types is a basic characterization. Pool all
samples — do NOT stratify by condition.

---

### 16. Separate boxplots for the same feature by different groupings

Wrong: Task ExA (TMSB10 by condition) + Task ExB (TMSB10 by gender) as
separate plots.
Right: preprocessing creates a `gender_condition` combined column; ONE
task: boxplot of TMSB10 grouped by `gender_condition`.

Rule: combine similar metadata groupings into a single combined column.

---

### 17. Individual gene plots for >5 targets

Wrong: 14 individual scatter plots for SRSF3 vs each MTOR signaling gene.
Right: 1 combined-score plot + store 14 individual correlation values
(no plots).

Rule: ≤5 targets → individual plots + combined. >5 targets → combined
only; store individual correlations as values.

---

### 18. Extra tests with detailed breakdowns

Wrong: Extra Test D with 6 individual gene boxplots by cell-cycle phase.
Right: Extra Test: correlation of TMSB10 vs % Apoptotic cells in Tumor
(one simple test).

Rule: extras are high-level taste tests. ONE analysis each.

---

### 19. Composite subtype forced into a module score

Wrong: `add_pathway_score` with `pathway_genes = c("KRT8", "VIM")` while
trying to add "low CDH1" by subtracting CDH1 — module scores cannot encode
negative / low directions.
Right: use `gate_cells_composite` with per-gene directions
(`high` / `mid` / `low`) and a `member_name` that labels cells passing all
gates.

Rule: any paper-defined population that requires a MIX of high/mid/low
markers goes through `gate_cells_composite`. Never shoehorn it into a
score.

---

### 20. Using CSV-only annotations without `add_extra_meta`

Wrong: writing `value_name = "author_subtype"` when `"author_subtype"`
only exists in `data_pre_add.txt`, not in `seurat_obj@meta.data`.
Right: add a preprocessing step that calls `add_extra_meta` on the CSV so
the column is merged into `@meta.data` before any analysis references it.

Rule: every metadata column used in an analysis task must exist in the
Seurat object. If it lives in an external CSV (i.e., listed in
`data_pre_add.txt`), preprocess it in first via `add_extra_meta`.

---

### 21. Inventing column names from `data_pre.txt` instead of using plan0's Metadata Index

Wrong: looking at `data_pre.txt`, picking what looks like the sample
column, and using that name.
Right: use the sample / condition / celltype column names that step 0
already chose and recorded in plan0's Metadata Index.

Rule: step 0 has already resolved column ambiguity (e.g., chose `sample`
over `patient`, picked the celltype column with fewest NAs, integrated
columns from `data_pre_add.txt`). Step 1 reads those decisions out of
`plan0.txt`'s Metadata Index — it does not re-derive them.

---

### 22. Forgetting the `From plan0:` link

Wrong: a Task bullet with no traceability back to which piece in plan0 it
came from.
Right: every Task bullet includes a `From plan0: Piece [X], analysis ([letter])`
line, mirroring step 0's `From brainstorm:` convention.

---

## Verification Checklist

| Check                       | Question                                                                              |
|-----------------------------|---------------------------------------------------------------------------------------|
| Score columns               | All score references use the `_score1` suffix?                                         |
| Group columns               | `group_col` is a column name, not a value?                                             |
| One bullet per call         | Each bullet has exactly one function call (or one GO enrichment step)?                 |
| DE deduplication            | Same gene-split + cell-type DE listed only once?                                       |
| GO enrichment separate      | GO enrichment in its own bullet (one for up, one for down)?                            |
| V2 direction labels         | `run_go_enrichment` `label` uses `de_result$up_condition` / `down_condition`?          |
| No stratified correlations  | Correlation tasks do NOT have stratified-subset repeats?                               |
| Strat for boxplot/DE only   | Subsetting only used for boxplots and DE, not correlations?                            |
| All params filled           | No "TBD", no vague values, all use real column names?                                  |
| Column names from plan0     | Sample / condition / celltype columns come from plan0's Metadata Index, not invented?  |
| Gene lists explicit         | Every `add_pathway_score` has explicit genes or an exact set name?                     |
| Preprocessing used          | Every preprocessing step is referenced by at least one task?                           |
| Strat values stated         | Stratified tasks specify exact subset conditions?                                      |
| Extra tests mapped          | Extra tests have function calls, not just prose?                                       |
| Gene symbols correct        | Gene names match standard HGNC symbols?                                                |
| Existing annotation         | Used proportion when plan0 chose an existing annotation over a module score?           |
| Cell type comparison        | gene-across-cell-types boxplots pool all samples (no condition split)?                  |
| Combined groups             | Similar boxplots combined into a single group column?                                  |
| Individual gene rule        | ≤5: individual plots + combined; >5: combined only, values stored?                     |
| Extra test scope            | Each extra test is ONE simple analysis?                                                |
| Composite subtypes          | Paper-defined high/mid/low subtypes routed to `gate_cells_composite`?                  |
| External CSV annotations    | `add_extra_meta` called before any task references columns from `data_pre_add.txt`?     |
| `From plan0:` link          | Every Task bullet links back to its originating plan0 piece?                            |
