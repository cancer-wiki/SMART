# Function Mapping Rules (Stage 2)

## Goal
For each Section 2 piece and each Extra Test in `plan0.txt`, decompose the
analysis into individual function calls. **One bullet = one function call**
(or one GO enrichment step).

---

## Before Starting Stage 2

1. Stage 1 must already be complete — the preprocessing section is written.
2. Read `plan0.txt`'s **Metadata Index** to know the resolved column names.
   Use those names in every parameter — do not invent new ones.
3. Read `function_v2.R` for analysis function signatures.
4. Each analysis task should record a `From plan0:` link back to the
   originating piece (mirroring step 0's `From brainstorm:` convention).

**CRITICAL — Choosing the right celltype column:**
If `data_pre_add.txt` contains a `paper_cell_type` column, you MUST check
whether each target cell type name exists in `paper_cell_type` or in the
original cell type column (e.g., `"Cell Types"`). If a cell type was
alias-resolved (e.g., renamed from a different label to match the paper's
terminology), it will ONLY exist in `paper_cell_type` — using the original
column will match zero cells. **For every `celltype_A_col`, `celltype_B_col`,
and `celltype_col` parameter, verify which column actually contains the
target cell type name and use that column.** When in doubt, use
`paper_cell_type` for any cell type mentioned in the paper's findings.

---

## The Analysis Functions

### Function 1: `correlate_celltype_features`
**Use when:** the plan0 piece's Type contains "Correlation" (or "
correlation").

This function correlates two features across samples. Both features can be
from the same cell type or different cell types.

**Key mapping decisions:**

| What to correlate                    | `feature_type`  | `feature_name`                       |
|--------------------------------------|-----------------|--------------------------------------|
| A gene's expression                  | `"gene"`        | gene symbol (e.g., `"SRSF3"`)        |
| A metadata score (module score)      | `"metadata"`    | column name (e.g., `"hypoxia_score1"`) |
| Cell type / category percentage      | `"percentage"`  | `NULL`                               |

**Same-cell-type correlation** (most common):
- `celltype_A == celltype_B` (e.g., both `"Tumor"`)
- `celltype_A_col == celltype_B_col` (the celltype column from plan0's
  Metadata Index)

**Proportion correlation** (gene vs cell subtype proportion):
- When correlating a gene with the proportion of a subtype:
  - `feature_B_type = "percentage"`
  - `feature_B_name = NULL`
  - `percentage_mode_B = "total"` or `"broad"`
  - `celltype_B` = the subtype whose proportion you want
    (e.g., `"Apoptotic"` from a `CellState` column)
  - `celltype_B_col` = the column containing that subtype
    (e.g., `"CellState"`)
- This is what plan0 picks when an existing annotation column captures the
  concept.

**Cross-cell-type correlation:**
- `celltype_A != celltype_B`
- May use different celltype columns if needed.

**`condition_col`**: the stratification-relevant column from plan0's
Metadata Index. The function colors the scatter plot by this column and
populates `correlation_by_condition` automatically.

**Template:**

```
Task [X].[a]: [description]
- From plan0: Piece [X], analysis (a)
- Function: correlate_celltype_features
- Inputs:
    seurat_obj      = seurat_obj
    celltype_A      = "[cell type]"
    celltype_B      = "[cell type]"
    feature_A_type  = "[gene/metadata/percentage]"
    feature_B_type  = "[gene/metadata/percentage]"
    feature_A_name  = "[name or NULL]"
    feature_B_name  = "[name or NULL]"
    sample_col      = "<sample col from plan0 Metadata Index>"
    condition_col   = "<condition col from plan0 Metadata Index>"
    celltype_A_col  = "<celltype col from plan0 Metadata Index>"
    celltype_B_col  = "<celltype col from plan0 Metadata Index>"
- Output: scatter plot + correlation (overall + by condition)
```

### Function 2: `compare_features_boxplot`
**Use when:** the plan0 piece's Type contains "Boxplot", "compare X between
groups", or "X-high vs X-low compare Y".

This function makes a boxplot comparing a feature across groups at the
sample level.

**Key mapping decisions:**

| What to compare                      | `value_type` | `value_name`                          |
|--------------------------------------|--------------|---------------------------------------|
| A gene's expression                  | `"gene"`     | gene symbol                           |
| A metadata score                     | `"metadata"` | column name (e.g., `"OXPHOS_score1"`) |

| Groups to compare                    | `group_col`                                  | `celltype`           |
|--------------------------------------|----------------------------------------------|----------------------|
| Gene-high vs gene-low                | `"{GENE}_group"`                              | specific cell type   |
| Across cell types (Pattern 4)        | celltype column from plan0 Metadata Index    | `NULL`               |
| Between conditions                   | condition column from plan0 Metadata Index   | specific cell type   |
| Across combined groups               | combined column (e.g., `"gender_condition"`) | specific cell type   |

**Template:**

```
Task [X].[b]: [description]
- From plan0: Piece [X], analysis (b)
- Function: compare_features_boxplot
- Inputs:
    seurat_obj   = seurat_obj
    value_type   = "[gene/metadata]"
    value_name   = "[name]"
    group_col    = "[grouping column]"
    celltype     = "[cell type or NULL]"
    celltype_col = "<celltype col from plan0 Metadata Index>"
    sample_col   = "<sample col from plan0 Metadata Index>"
- Output: boxplot + statistical test
```

### Function 3: `run_de_analysis`
**Use when:** the plan0 piece's Type contains "DE", "differential
expression", or "DE+Enrichment".

**V2 direction convention.** `run_de_analysis` returns `up_condition` and
`down_condition` (alphabetical — the alphabetically FIRST condition is the
reference; positive logFC = upregulated in the alphabetically SECOND
condition). Thread these direction labels into the downstream
`run_go_enrichment` call so outputs are labelled correctly.

**Deduplication rule.** If multiple pieces need DE on the same gene split
in the same cell type, that is ONE `run_de_analysis` call. Later pieces
reference "Reuse DE from Task X."

**Template:**

```
Task [X].[c]: DE analysis — [GENE]-high vs [GENE]-low in [cell type]
- From plan0: Piece [X], analysis (e) [or whichever letter the DE step has]
- Function: run_de_analysis
- Inputs:
    seurat_obj    = seurat_obj
    celltype      = "[cell type]"
    celltype_col  = "<celltype col from plan0 Metadata Index>"
    condition_col = "[GENE]_group"
    condition1    = "[GENE]_high"
    condition2    = "[GENE]_low"
    sample_col    = "<sample col from plan0 Metadata Index>"
    title         = "[descriptive title]"
- Output: DE results (de_result) including up_condition and down_condition
```

**GO enrichment is always a separate bullet.** Use `de_result$up_condition`
/ `de_result$down_condition` inside the `label` argument so the output is
labeled with the correct biological direction.

```
Task [X].[d]: GO enrichment on upregulated genes from Task [X].[c]
- Function: run_go_enrichment
- Inputs:
    gene_list = de_result$significant_genes %>% filter(avg_logFC > 0) %>% pull(gene)
    organism  = "human"
    ont       = "BP"
    label     = paste("Upregulated in", de_result$up_condition)
- Output: GO enrichment results (data frame or "No significant GO enrichment found")

Task [X].[e]: GO enrichment on downregulated genes from Task [X].[c]
- Function: run_go_enrichment
- Inputs:
    gene_list = de_result$significant_genes %>% filter(avg_logFC < 0) %>% pull(gene)
    organism  = "human"
    ont       = "BP"
    label     = paste("Upregulated in", de_result$down_condition)
- Output: GO enrichment results
```

### Function 4: `compare_celltype_by_group`
**Use when:** the plan0 piece compares cell-type proportions between groups.

**Template:**

```
Task [X].[a]: [description]
- From plan0: Piece [X], analysis (a)
- Function: compare_celltype_by_group
- Inputs:
    seurat_obj      = seurat_obj
    group_col       = "[grouping column]"
    sample_col      = "<sample col from plan0 Metadata Index>"
    celltype        = "[cell type to measure]"
    celltype_col    = "<celltype col from plan0 Metadata Index>"
    percentage_mode = "[total/broad]"
- Output: violin plot + statistical test
```

---

## Handling Stratified Analyses

### Correlations — automatic, no subsetting needed

`correlate_celltype_features` already returns `correlation_by_condition`
based on `condition_col`. When you set `condition_col` to the stratification
column from plan0's Metadata Index, the function automatically computes
separate correlations for each value of that column and puts them in the
plot title.

**Therefore: do NOT create separate stratified correlation tasks.** Just
set `condition_col` to the relevant stratification column, and note:

```
Note: Per-condition correlations automatically computed via
condition_col = "<condition col>" (returns correlation_by_condition in output)
```

If plan0 calls for stratification by a SECOND variable, you can either:
- Re-run with `condition_col = "<other column>"` as a separate task, OR
- Subset and re-run (only if you need both stratifications simultaneously).

### Boxplots and DE — subsetting still required

Boxplot and DE functions do NOT auto-stratify. To stratify:

1. Subset the Seurat object to one stratum.
2. Re-run the same function call on the subset.

**Format:**

```
Task [X].[b]-strat-condition: Stratified repeat of Task [X].[b] — by condition
- Subset: seurat_obj to condition == "primary",    re-run Task [X].[b]
- Subset: seurat_obj to condition == "metastatic", re-run Task [X].[b]
```

Group stratified tasks right after the main task they repeat.

---

## Handling Repeated Correlations (individual gene correlations)

**Size-based rule** (mirroring step 0):

When a piece says "individual correlations of GENE vs each of [list of
targets]":

**≤5 target genes — individual plots + combined score.**
Each target gets its own `correlate_celltype_features` call (producing a
plot), plus one call for the combined score. List each as a separate
bullet.

```
Task 8.1.a: Correlation — TMSB10 vs TMSB10_mitotic_targets_score1 in Tumor (combined)
- Function: correlate_celltype_features
- [standard params with feature_B_type = "metadata",
   feature_B_name = "TMSB10_mitotic_targets_score1"]

Task 8.1.a2: Correlation — TMSB10 vs CDK1 in Tumor
- Function: correlate_celltype_features
- [standard params with feature_B_type = "gene", feature_B_name = "CDK1"]

Task 8.1.a3: Correlation — TMSB10 vs CCNB2 in Tumor
...
```

**>5 target genes — combined score only, store individual correlations:**
One call for the combined score (producing a plot). For individual
correlations, note as a loop that stores only correlation values (no
plots):

```
Task 5.2.a: Correlation — SRSF3 vs MTOR_signaling_score1 in Tumor (combined)
- Function: correlate_celltype_features
- [standard params]

Task 5.2.a2: Individual correlations — SRSF3 vs each MTOR signaling gene (values only)
- Function: correlate_celltype_features (loop over ~14 genes; store correlations only, no plots)
- Loop over feature_B_name = each of: [gene list]
- Output: correlation values stored (no individual scatter plots generated)
```

---

## Handling DE Deduplication

Multiple pieces may need DE on the same split. Common pattern:

- Piece 4.1 needs DE + enrichment for proliferation pathways.
- Piece 5.2 needs DE + enrichment for MTOR signaling.
- Piece 6.1 needs DE + enrichment for OXPHOS.

All three split Tumor cells by SRSF3-high vs SRSF3-low. This is ONE
`run_de_analysis` call. Enrichment can be listed with a note that it
covers the pathways asked about by multiple pieces.

**Preferred pattern:** one DE call, then GO enrichment on the sig genes
(V2 direction labels):

```
Task 4.1.c: DE analysis — SRSF3-high vs SRSF3-low in Tumor
- From plan0: Piece 4.1, analysis (e)
- Function: run_de_analysis
- ...
- Output: DE results (de_result) including up_condition and down_condition

Task 4.1.d: GO enrichment — upregulated genes from Task 4.1.c
- Function: run_go_enrichment
- Inputs:
    gene_list = de_result$significant_genes %>% filter(avg_logFC > 0) %>% pull(gene)
    organism  = "human"
    ont       = "BP"
    label     = paste("Upregulated in", de_result$up_condition)
- Output: GO enrichment results

Task 4.1.e: GO enrichment — downregulated genes from Task 4.1.c
- Function: run_go_enrichment
- Inputs:
    gene_list = de_result$significant_genes %>% filter(avg_logFC < 0) %>% pull(gene)
    organism  = "human"
    ont       = "BP"
    label     = paste("Upregulated in", de_result$down_condition)
- Output: GO enrichment results
- Note: this single DE + GO enrichment covers pathway checks for
  Pieces 4.1, 5.2, and 6.1

Task 5.2.c: [Reuse DE from Task 4.1.c — same SRSF3 split in Tumor]
Task 6.1.c: [Reuse DE from Task 4.1.c — same SRSF3 split in Tumor]
```

---

## Handling Combined Group Boxplots

When plan0 proposes comparing the same feature across multiple metadata
groupings (e.g., TMSB10 by gender AND TMSB10 by condition), combine into a
single boxplot:

1. In preprocessing: create a combined column (e.g., `gender_condition`)
   by pasting the two source columns. This is inline base-R, not a
   `preprocess.R` function — the preprocessing entry just records the
   `paste()` line.
2. In analysis: use `group_col = "gender_condition"` with all combined
   values displayed.

This avoids generating redundant plots. Example:

```
Task ExAB.a: Boxplot — TMSB10 by gender x condition in Tumor
- From plan0: Extra Test ExA + ExB (combined)
- Function: compare_features_boxplot
- Inputs:
    value_type   = "gene"
    value_name   = "TMSB10"
    group_col    = "gender_condition"
    celltype     = "Tumor"
    celltype_col = "<celltype col from plan0 Metadata Index>"
    sample_col   = "<sample col from plan0 Metadata Index>"
- Output: boxplot showing male_primary, male_metastatic, female_primary,
  female_metastatic
```

---

## Handling Cell Type Comparisons (gene across cell types)

When comparing a gene across cell types (Pattern 4 from step 0):
- `group_col` = the celltype column from plan0's Metadata Index
- `celltype` = `NULL`
- Do NOT create stratified repeats by condition.
- Pool all samples — this is a basic characterization question.

```
Task 12.1.a: Boxplot — TMSB10 across all cell types (all samples pooled)
- From plan0: Piece 12.1
- Function: compare_features_boxplot
- Inputs:
    value_type   = "gene"
    value_name   = "TMSB10"
    group_col    = "<celltype col from plan0 Metadata Index>"
    celltype     = NULL
    celltype_col = "<celltype col from plan0 Metadata Index>"
    sample_col   = "<sample col from plan0 Metadata Index>"
- Output: boxplot + pairwise statistical tests
- Note: all samples pooled; no condition stratification
```

---

## Common Errors

| Wrong                                                                   | Right                                                                                  |
|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| Inventing column names from `data_pre.txt` directly                     | Use the column names from plan0's Metadata Index — step 0 already chose them            |
| Missing `condition_col` in `correlate_celltype_features`                | Always specify (the condition column from plan0's Metadata Index)                       |
| Using `"SRSF3_high"` as `group_col`                                      | `group_col = "SRSF3_group"`; values are `"SRSF3_high"` / `"SRSF3_low"`                  |
| Combining correlation + boxplot in one bullet                           | Separate bullets: one `correlate_celltype_features`, one `compare_features_boxplot`    |
| DE listed 3 times for the same split                                    | List once; other pieces say "Reuse DE from Task X"                                      |
| GO enrichment in the same bullet as DE                                  | Separate bullet for GO enrichment (one for up, one for down)                            |
| GO enrichment `label` hardcoded (ignoring V2 direction fields)          | Use `paste("Upregulated in", de_result$up_condition)` so labels match the data         |
| "Stratify by condition" without specifying subset values                | State: "subset to condition == 'primary'" AND "subset to condition == 'metastatic'"    |
| Score column named `"hypoxia"` instead of `"hypoxia_score1"`            | `AddModuleScore` appends `_score1` — use the actual output name                         |
| Vague parameter like `celltype = "tumor cells"`                         | Use the exact value from metadata: `celltype = "Tumor"`                                 |
| Missing `sample_col`                                                    | Always specify (use the sample column from plan0's Metadata Index)                      |
| Computing a score when plan0 says "use existing annotation proportion"  | Respect plan0 — use `feature_B_type = "percentage"` instead                             |
| Creating stratified cell-type comparison by condition                   | Pool all samples — no condition split                                                   |
| Separate boxplots for same feature by gender and by condition           | Create combined `gender_condition` column; make one boxplot                             |
| Individual gene plots for >5 targets                                    | >5 targets: combined score only; store individual correlations as values               |
| Extra tests with individual gene breakdowns                             | Keep extras high-level: ONE analysis each                                               |
| Using CSV-only annotations without calling `add_extra_meta` first       | Run `add_extra_meta` in preprocessing so downstream columns exist                      |
| Forcing a paper-defined "A-high B-mid C-low" subtype into a module score| Use `gate_cells_composite` — directional thresholds can't be collapsed into a score    |
| Forgetting `From plan0:` link on each task                              | Every analysis bullet records its originating piece (mirrors step 0's `From brainstorm:`) |

---

## Output Format

```
===============================================================================
ANALYSIS TASKS
===============================================================================

-------------------------------------------------------------------------------
Piece [X]: [short description from plan0]
From plan0: [piece reference]
-------------------------------------------------------------------------------

Task [X].[a]: [description]
- From plan0: Piece [X], analysis (a)
- Function: [function name]
- Inputs:
    [param] = [value]
    ...
- Output: [what it returns]

Task [X].[b]: [description]
- From plan0: Piece [X], analysis (b)
- Function: [function name]
- Inputs:
    [param] = [value]
    ...
- Output: [what it returns]

Task [X].[a]-strat-condition: Stratified repeat — by condition
- Subset: seurat_obj to condition == "primary",    re-run Task [X].[a]
- Subset: seurat_obj to condition == "metastatic", re-run Task [X].[a]

...

===============================================================================
EXTRA TESTS
===============================================================================

[Same format as above for each extra test]
```
