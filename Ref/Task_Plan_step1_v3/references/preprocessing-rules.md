# Preprocessing Rules (Stage 1)

## Goal
Scan all Section 2 pieces and Extra Tests in `plan0.txt` and collect every
preprocessing step needed before analysis functions can run. Deduplicate
across pieces and output a clean, numbered list.

---

## Before Starting Stage 1

1. Read `Working/plan0.txt` completely — pay special attention to the
   **Metadata Index** at the top, which gives the resolved column names
   (sample column, condition columns, celltype columns) used throughout the
   rest of the file.
2. Read `Working/definitions_final.txt` for gene lists referenced by
   pieces.
3. Read `Outputs/data_pre.txt` for native metadata details.
4. If `Working/data_pre_add.txt` exists, read it for added annotation
   columns. If it does not exist, skip — the Metadata Index in `plan0.txt`
   already accounts for this.
5. Read `preprocess.R` for function signatures.

---

## Process

### Step 1: Scan plan0.txt for preprocessing needs

For each Section 2 piece AND each Extra Test, ask:

1. **Does it use a pathway / signature score?**
   - Keywords in plan0: "module score", "pathway score", "signature score",
     "add_module_score", "{something}_score".
   - Step 0 already decided whether a score is appropriate; if it's listed
     as "Required processing: add_module_score with genes: …" or similar,
     step 1 needs an `add_pathway_score` step.
   - If `plan0.txt` instead specifies "use proportion from existing
     annotation" → no preprocessing needed for that piece; the analysis
     uses `feature_B_type = "percentage"` directly.
   - Collect: pathway name, gene list (or source).

   **Weighted sum signatures**: When `definitions_final.txt` specifies a
   scoring method as "weighted sum" with explicit coefficients, do NOT
   use `add_pathway_score` (which calls AddModuleScore and ignores
   weights). Instead, emit inline R code that computes the weighted sum
   using the provided coefficients. The threshold for dichotomization
   (if provided) should also use the weighted sum, not the module score.
   Example inline R:
   ```
   genes <- c("GENE1", "GENE2", ...)
   coefficients <- c(0.05, 0.12, ...)
   names(coefficients) <- genes
   present <- genes[genes %in% rownames(seurat_obj)]
   cat("Weighted sum:", length(present), "/", length(genes), "genes present\n")
   expr <- GetAssayData(seurat_obj, layer="data")[present, ]
   seurat_obj$SCORE_NAME <- as.numeric(
     t(coefficients[present]) %*% as.matrix(expr)
   )
   ```

2. **Does it split samples into GENE-high vs GENE-low?**
   - Keywords: "Split samples by GENE level (median)", "GENE-high vs
     GENE-low", "Group by expression".
   - -> `create_gene_based_groups`
   - Collect: gene name, target cell type, celltype column, sample column.

3. **Does it need a gene list from a GO term?**
   - Keywords: "GO:", "Gene Ontology".
   - -> `pull_out_gene_list_from_GO`
   - Collect: GO term ID.

4. **Does it define a subtype by a mix of high/mid/low markers?**
   - Keywords: "GatingProportion", "X+ Y+ Z-low", "gate cells", a paper-
     defined population that needs simultaneous thresholds on several
     markers.
   - -> `gate_cells_composite`
   - Never force this into a module score. Subtraction / inversion /
     sign-flipping breaks the module-score assumption.
   - Collect: gene criteria (each with a direction), parent cell type,
     member name (new label), cell-type column, and whether to overwrite
     the existing column or write to a new one.

5. **Does the piece reference a column that lives in `data_pre_add.txt`?**
   - Step 0 has already integrated `data_pre_add.txt` columns into the
     Metadata Index of `plan0.txt`. If a piece references such a column
     (look for "Metadata used: <col> (added)" or notes pointing at the
     `data_pre_add.txt` file), the columns are not yet inside the Seurat
     object — they need to be merged in.
   - -> `add_extra_meta` (run early, before any other preprocessing /
     analysis that depends on those columns)
   - If `data_pre_add.txt` does not exist or no piece references its
     columns, skip this preprocessing entirely.
   - Collect: path to the CSV and a note about which columns will appear
     in `@meta.data` after this step.

6. **Does it compare the same feature across multiple metadata groupings?**
   - Keywords in plan0: "by sex AND by Type", "stratified boxplot by
     multiple columns", or step 0's "combined group column" suggestion.
   - -> create a combined group column (e.g., `gender_condition`) by
     pasting two metadata columns.
   - Output column: `{col1}_{col2}`.
   - **Note:** there is no function in `preprocess.R` for this — the
     combined column is created with inline base-R (`paste()` directly on
     the metadata). In `plan2.txt`, emit it as an inline R expression, not
     as a function-call bullet (see template in Step 4 below).

### Step 2: Deduplicate

Two preprocessing steps are the same if:
- Same function AND same key parameters (same `pathway_name`, same
  `gene_name` + same `target_celltype`, same gated `member_name`, same CSV
  path, etc.).
- For combined group columns (no function): same pair of source columns
  (deduplicate by output column name, e.g., `gender_condition`).

Examples:
- Pieces 4.2 and 6.1 both need the OXPHOS score -> ONE `add_pathway_score`
  call. Other pieces in plan0 may already say "(reuse)" — respect that.
- Pieces 4.1, 5.1, 5.2, 6.1, 6.2 all need SRSF3-high/low groups in the same
  target cell type -> ONE `create_gene_based_groups` call.
- Pieces 7.1 and 7.2 both need the same composite gated subtype
  (e.g., `A_high_B_mid_C_low_Epithelial`) -> ONE `gate_cells_composite`
  call.
- If multiple pieces reference columns from the same external CSV ->
  ONE `add_extra_meta` call (run first so the new columns are available
  to everything else).

### Step 3: Resolve gene lists

For each `add_pathway_score` step:

1. Check `Working/definitions_final.txt` first.
   - If the list is given explicitly: use it and note
     `Source: definitions_final.txt`.
   - If `definitions_final.txt` just names a standard set
     (e.g., "use HALLMARK_HYPOXIA"): record the set name.
2. If not in `definitions_final.txt`: use the exact MSigDB set name or
   KEGG pathway name.
3. If it is a paper-specific list: list every gene explicitly.

**You MUST provide either explicit gene names or an exact database set
name.** Never write "hypoxia genes" without specifying which ones.

### Step 4: Fill in all parameters

Use the column names from the Metadata Index in `plan0.txt` (sample
column, celltype column, etc.). Do not re-derive from `data_pre.txt`.

For `add_pathway_score`:

```
- Function: add_pathway_score
- Inputs:
    seurat_obj    = seurat_obj
    pathway_genes = c("GENE1", "GENE2", ...)   # or: msigdbr query for HALLMARK_HYPOXIA
    pathway_name  = "hypoxia"
- Output: hypoxia_score1 (new metadata column)
- Gene list source: [definitions_final.txt / MSigDB HALLMARK_HYPOXIA / etc.]
```

For `create_gene_based_groups`:

```
- Function: create_gene_based_groups
- Inputs:
    seurat_obj       = seurat_obj
    gene_name        = "SRSF3"
    celltype_column  = "<celltype col from plan0 Metadata Index>"
    sample_column    = "<sample col from plan0 Metadata Index>"
    target_celltype  = "Tumor"
- Output: SRSF3_group (new metadata column; values: SRSF3_high, SRSF3_low)
```

For `pull_out_gene_list_from_GO`:

```
- Function: pull_out_gene_list_from_GO
- Inputs:
    GO_term = "GO:XXXXXXX"
- Output: gene_symbols (character vector, used as input to add_pathway_score)
```

For `gate_cells_composite`:

```
- Function: gate_cells_composite
- Inputs:
    seurat_obj      = seurat_obj
    gene_criteria   = list(
                        list(gene = "KRT8", direction = "high"),
                        list(gene = "VIM",  direction = "mid"),
                        list(gene = "CDH1", direction = "low")
                      )
    celltype_column = "<celltype col from plan0 Metadata Index>"
    parent_celltype = "Epithelial"
    member_name     = "KRT8_VIM_CDH1low_Epithelial"
    new_column      = "refined_annotation"   # or NULL to overwrite celltype_column
- Output: refined_annotation (new or updated cell-type column; passing cells
  get member_name, failing parent cells keep the parent label, non-parent
  cells keep their original label)
- Note: threshold logic is per gene. A gene used only with "high"/"low"
  gets a median split. Any gene used with "mid" anywhere gets a quartile
  split (Q1 / Q3) for all its directions.
```

For `add_extra_meta`:

```
- Function: add_extra_meta
- Inputs:
    seurat_obj = seurat_obj
    annot_path = "Outputs/data_pre_add_source.csv"   # or whatever path data_pre_add.txt points to
- Output: every column from the CSV is added to @meta.data (matched by cell barcode)
- New columns expected: [list the added columns plan0 references downstream]
- Note: run this FIRST in the preprocessing list so the new columns are
  available to every later preprocessing / analysis step.
```

For combined group columns (inline base-R — there is no function in
`preprocess.R` for this; emit the `paste()` line directly in `plan2.txt`):

```
- Type: Combined group column (inline base-R, no preprocess.R function)
- Inline R: seurat_obj$gender_condition <- paste(seurat_obj$gender,
                                                  seurat_obj$condition,
                                                  sep = "_")
- Output: gender_condition (new metadata column; values example:
  male_primary, male_metastatic, female_primary, female_metastatic)
- Used by: [Piece IDs that compare the same feature across both gender and condition]
```

### Step 5: Track dependencies

For each preprocessing step, note which analysis tasks depend on it:

```
Used by: Piece 4.2a, 4.2b (hypoxia correlation and boxplot)
```

This helps the reader understand why each step exists — and makes it easy
to spot an orphan preprocessing step.

---

## Common Errors

| Wrong                                                                | Right                                                                                      |
|----------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| "Compute hypoxia score" (no gene list)                               | List explicit genes or exact MSigDB set name                                                |
| Same score listed twice for different pieces                         | List once; note all pieces that use it via `Used by:`                                       |
| Gene group for a gene that no analysis task uses                     | Only create groups that are actually needed by analysis tasks                              |
| Wrong `celltype_column` for gene groups                              | Use the celltype column that step 0 chose (see plan0 Metadata Index)                        |
| Missing `sample_column`                                              | Always specify — use the sample column from plan0's Metadata Index                          |
| Pathway name with spaces or special chars                            | Use clean names: `MTOR_signaling`, `hypoxia`, `OXPHOS`                                      |
| Computing module score when metadata already has annotation          | Respect plan0 — if it says "use proportion from existing annotation", skip the score step    |
| Separate boxplots for gender and condition                           | Create combined column `gender_condition`, one boxplot                                      |
| Forcing a high/mid/low composite subtype into a module score         | Use `gate_cells_composite` — directionality cannot be collapsed into a score                |
| Referencing CSV-only annotations without calling `add_extra_meta`    | Run `add_extra_meta` first so the columns exist in `@meta.data`                             |
| Calling `add_extra_meta` when `data_pre_add.txt` doesn't exist       | Skip — only call it when plan0 actually references columns from `data_pre_add.txt`          |
| `gate_cells_composite`'s `member_name` collides with an existing label | Choose a unique label (the function refuses colliding names by design)                    |

---

## Output Format

```
===============================================================================
PREPROCESSING
===============================================================================

Preprocessing #1: [short description]
- Function: [function name]
- Inputs:
    [param1] = [value]
    [param2] = [value]
    ...
- Output: [column name or variable]
- Gene list: [explicit genes] | Source: [definitions_final.txt / MSigDB / etc.]
- Used by: [Piece IDs]

Preprocessing #2: ...
```
