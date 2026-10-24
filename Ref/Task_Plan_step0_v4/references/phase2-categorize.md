# Phase 2: Metadata Cross-Check and Categorization

## Goal
For each brainstorm piece, determine whether it can be tested with the actual
dataset, categorize accordingly, propose stratified analyses, and propose
extra dataset-driven tests.

---

## Process

### Step 1: Read All Input Files
1. Read `Working/preprocess-brainstorm.txt` completely
2. Read `Outputs/data_pre.txt` completely (native metadata)
3. Read `Working/data_pre_add.txt` completely (added annotation columns)
4. Read `Working/definitions_final.txt` for any gene list references

`data_pre_add.txt` describes annotation columns added to the dataset
(e.g., refined cell-type clusters, effector-state labels). Treat them
identically to native metadata — their categorical values can drive cell-type
assignment / stratification, and their per-category per-sample proportions
are valid features. When a concept (subtype, phase, ploidy, effector state)
appears as an added annotation, prefer it over computing a new module score.

### Step 2: Build a Metadata Index First

Before categorizing anything, extract from `data_pre.txt` + `data_pre_add.txt`:

```
Sample column:          [name of the sample-identifier column]
Patient column:         [name of the patient-identifier column, if present]
Cell type columns:      [column names and unique values, from both files]
Condition columns:      [column names and unique values — e.g., treatment, primary/recurrent]
Clinical variable cols: [column names and unique values — e.g., stage, grade, survival]
Sample-level metadata:  [any per-sample annotations]
Cell cycle annotations: [present/absent, which column]
Added annotations:      [list columns from data_pre_add.txt and their unique values]
CNV data:               [present/absent — if absent, all CNV pieces → Section 3]
Stratification columns: [columns usable for stratified analyses — e.g., disease stage, sex,
                          treatment status, tumor type]
```

**Sample vs patient column rule.** If both `sample` and `patient` columns
exist, pick `sample` as the unit of aggregation. Record a one-line note in
the output:

> Note: For exploration we use sample-wise data, not patient-wise data.
> Sample column: `<name>` (chosen over `<patient column>` when both exist).

Whenever guidance says "per-sample correlation" / "per-sample proportion",
it means per the chosen sample column.

When multiple columns overlap (e.g., two cell-type labelings), pick the one
with fewer NAs, unless the brainstorm piece explicitly needs a finer-grained
labeling that only the added annotation provides.

**CRITICAL — `paper_cell_type` column.** If `Working/data_pre_add.txt`
contains a `paper_cell_type` column, this column holds cell type labels
aligned to the paper's terminology (alias-resolved from the original cell
type column). Some cell types mentioned in the paper may only exist under
their paper name in `paper_cell_type`, not in the original cell type column
(e.g., the original column may label them differently). For each
paper-mentioned cell type, check: does this exact name appear in the
original cell type column? If NOT, it was alias-resolved and only exists
in `paper_cell_type`. In the Metadata Index, list `paper_cell_type` as the
column for that cell type. Getting this wrong means zero cells matched
in all downstream analyses for that cell type.

**Proportion features from existing annotations.**
When native or added metadata has categorical annotations (e.g., Phase for
cell cycle, subtype labels in `data_pre_add.txt`), identify these as potential
proportion-based features. For each relevant annotation, the per-sample
proportion of cells in each category is a valid feature for correlation and
boxplot analyses. Prefer this over computing new module scores for the
same concept.

Examples:
- Phase column has G1/S/G2M → the %G2M per sample replaces a G2M_checkpoint module score
- Added annotation has B-cell subtypes (naive, memory, plasma) → per-sample % of each subtype is a direct feature
- Added annotation has epithelial subtypes (basal, luminal, secretory) →
  per-sample % of each subtype is a feature

### Step 3: Categorize Each Piece (decision flowchart)
```
├─► Summary sentence or redundant with another piece?
│   └─► YES → Section 3 (Not a testable claim)
│
├─► [FLAG: NOT TESTABLE] from Phase 1?
│   └─► YES → Section 3 (Beyond scRNA-seq capability)
│   └─► BUT has mRNA proxy piece? → Evaluate proxy piece separately
│
├─► Requires spatial/epigenetic/CNV data?
│   └─► YES → Section 3
│
├─► ALL required cell types present in metadata (native OR added)?
│   └─► NO (completely absent) → Section 3 (Missing cell type)
│
├─► ALL required conditions/variables present?
│   └─► NO, but computationally derivable → Section 2
│   └─► NO, metadata might or might not have it → Section 4 (CONDITIONAL)
│   └─► NO, not derivable → Section 3
│
├─► [FLAG: CONDITIONAL] from Phase 1?
│   └─► Check if the required metadata actually exists (native or added)
│   └─► EXISTS → Promote to Section 1 or 2
│   └─► ABSENT → Section 3 (state what was missing)
│   └─► PARTIAL/UNCERTAIN → Keep as Section 4
│
├─► GatingProportion piece (Pattern 4c)?
│   └─► All gate genes present in data + parent cell type present → Section 2
│       (always requires processing to compute the gate)
│   └─► Any gate gene missing or parent cell type absent → Section 3
│
├─► Additional computation needed?
│   ├─► YES → Section 2 (DOABLE WITH PROCESSING)
│   └─► NO  → Section 1 (DIRECT CHECK)
```

Conservative rule: when uncertain → Section 2 or 4, not Section 1.

**No cross-cancer framing**: The paper and dataset may be from different
cancer types. Do NOT add "cross-cancer validation" disclaimers or reframe tests
as "testing whether X from cancer A holds in cancer B." Just test the biological
relationships directly.

**No condition split for cell type comparisons**: When checking if a gene is
present/elevated across cell types (Pattern 4), do NOT stratify by condition.
Pool all samples for a single comparison across cell types. This is a basic
characterization, not a condition-dependent test.

### Step 4: For Each Testable Piece, Add Stratified Analyses

After categorizing a piece as Section 1 or 2, check the Metadata Index for
stratification columns (from both `data_pre.txt` and `data_pre_add.txt`).
For each relevant stratification column, propose:

```
Stratified analysis:
- Repeat [correlation / boxplot / gating proportion] stratified by [column]: [value1] vs [value2]
- Rationale: [why this stratification is biologically interesting]
```

Common stratifications:
- Disease stage / type (e.g., newly diagnosed vs recurrent)
- Sex (male vs female)
- Treatment status (if available)
- Tumor grade (if variable)
- Refined cell-type labels from added annotations (e.g., stratify tumor-cell
  analyses by a finer tumor subcluster if present in `data_pre_add.txt`)

Only propose stratifications that are biologically meaningful — don't blindly
stratify by every column.

### Step 5: Propose Extra Dataset-Driven Tests

After all paper-driven pieces are categorized, scan the Metadata Index for
additional biologically interesting comparisons that go beyond the paper's claims
but are enabled by the dataset's metadata (including added annotations).

**CRITICAL: Keep extra tests high-level and directional.**
- Each extra test should be ONE simple analysis (one correlation OR one boxplot OR one gating proportion)
- Do NOT propose detailed breakdowns (e.g., individual gene-level boxplots for
  every gene in a list). The goal is a quick directional signal.
- Do NOT propose extra tests that are basically the same as a paper-driven piece
  but with a slightly different grouping — those are stratified analyses, not extras.
- Think: "What one comparison would a reviewer want to see?" not "What are all
  possible follow-ups?"

**Combine similar comparisons:** If you want to show the same feature split by
multiple metadata columns (e.g., TGFB1 by sex AND by Type), propose a combined
group column (e.g., sex_Type) so it can be displayed in one boxplot.

Format:
```
===============================================================================
ADDITIONAL TESTS FROM DATASET METADATA
===============================================================================

Extra Test A: [Description]
- Analysis type: [ONE of: Correlation / Boxplot / DE + Enrichment / GatingProportion]
- Rationale: [Why this is biologically interesting — one sentence]
- Cell types: [Which cells]
- Features: [Which genes/scores/proportions/gated-population]
- Processing: [Minimal steps]
- Metadata used: [Which column and values — mark source as native or added]
```

### Step 6: Write to Working/plan0.txt

Write the complete plan including:
1. Metadata Index (including sample column note)
2. Section 1 pieces (if any)
3. Section 2 pieces with full analysis plans (correlation + boxplot + DE / GatingProportion when applicable)
4. Section 3 pieces with reasons
5. Section 4 pieces with conditions
6. Stratified analyses for each testable piece
7. Additional dataset-driven tests
8. Summary table

---

## Section Definitions

### Section 1: DIRECT CHECK
Gene expression or metadata field directly available. No score computation,
no sample grouping, no annotation needed, no gating.

### Section 2: DOABLE WITH PROCESSING
Testable but requires computation first. Examples: signature scoring,
sample grouping by expression level, DE + enrichment, subtype annotation
(if not already in added annotations), GatingProportion.

### Section 3: NOT TESTABLE
Cannot be tested with this dataset. Reasons include: beyond scRNA-seq capability,
missing cell type, missing required metadata, summary sentence, CNV-dependent,
score has no clear definition, gate gene missing.

### Section 4: CONDITIONAL
Testable only if specific metadata exists. After checking `data_pre.txt` AND
`data_pre_add.txt`:
- If metadata found → promote to Section 1 or 2 with concrete plan
- If metadata absent → demote to Section 3 with explanation
- If uncertain → keep as Section 4 with explicit condition stated

---

## Section 2 Special Rules

### Analysis Types — Apply the Full Pattern

For each Section 2 piece, ensure the analysis plan includes ALL applicable types
from the Analysis Pattern Tutorial in `~/.claude/agents/Ref/Task_Plan_step0_v4/references/phase1-brainstorm.md`:

| Claim type | Required analyses |
|------------|-------------------|
| A activates/promotes B | Correlation(A,B) + Boxplot(A-high vs A-low, B) |
| A drives pathway P | Correlation(A, P-score) + Boxplot(A-high vs A-low, P-score) + DE+Enrichment |
| A elevated in cancer | Boxplot across cell types |
| Broad downstream effects | DE + Enrichment (always include alongside specific tests) |
| Composite "X+ Y+ Z-low" population | GatingProportion (plus downstream correlation/boxplot of the proportion) |

### Signature Scoring — always provide full gene list:
```
Required processing: add_module_score with genes: [GENE1, GENE2, ...]
Gene list source: [definitions_final.txt / Paper Figure X / KEGG pathway name / Hallmark gene set]
```
**Check `Working/definitions_final.txt` first** for the gene list. If not there,
use standard sources. If no established gene list exists and the concept is hard
to define in scRNA-seq, **skip the score** and note: "No standard scRNA-seq
signature available — skipped."

**CRITICAL: Prefer existing annotations over module scores.** If native metadata
or `data_pre_add.txt` has a categorical annotation that captures the same concept
(e.g., Phase for cell cycle, subtype labels), use the per-sample proportion of
the relevant category instead of computing a module score. For example:
- Dataset has Phase (G1/S/G2M) → use %G2M per sample, NOT G2M_checkpoint module score
- `data_pre_add.txt` has a refined macrophage subtype column → use per-sample %
  of that subtype, NOT a new macrophage-subtype score

### GatingProportion (Pattern 4c) — required spec:
When a piece involves a composite high/low population:
```
Required processing:
  1. Within parent type [PARENT_CELL_TYPE], classify cells as:
       GENE1 > threshold_1 AND GENE2 > threshold_2 AND GENE3 < threshold_3
     Default thresholds: median of each gene within the parent type
     (or `> 0` for positivity gates — state explicitly).
  2. Per-sample proportion = (# gated cells in sample) / (# parent-type cells in sample)
  3. Use this proportion as the feature in correlation / boxplot / DE downstream.

Gate genes required: [list of genes, each with direction +/-]
Parent cell type: [exact cell-type label from native or added annotation]
```
If any gate gene is missing from the data → Section 3.
If parent cell type is absent → Section 3.

### Subtype Annotation — distinguish:
- "Have broad cell type, need subtype, and subtype is in `data_pre_add.txt`"
  → use the added annotation directly (may be Section 1 for direct checks on
  that column, or Section 2 for downstream analyses)
- "Have broad cell type, need subtype, not in either file" → Section 2
  (state marker genes)
- "Cell type completely absent from both files" → Section 3

### Sample Grouping — state criterion explicitly:
```
Required processing: Group samples by avg [GENE] in [cell type]
→ High = top 50% / Low = bottom 50%
Sample column used: [the chosen sample column from Step 2]
```

### DE + Enrichment — for broad transcriptional changes:
```
Required processing: Group [cell type] by [GENE] expression level (high vs low)
→ Run DE analysis between groups
→ Run pathway enrichment on DE results (GO over-representation preferred)
→ Check for enrichment of: [specific pathways from paper claims]
```

### Cross-Cell-Type Per-Sample Correlation:
```
Required processing: Per sample, compute [score/gene] in [cell type A]
and [score/gene] in [cell type B], then correlate across samples
```

### Concrete Analysis Type — always specify:
| Vague | Concrete |
|-------|----------|
| "Compare X between groups" | "Boxplot of X in group A vs group B + statistical test" |
| "Check association" | "Per-sample correlation of X vs Y" |
| "Look at differences" | "DE analysis: condition A vs B in cell type C" |
| "See if related" | "Per-sample correlation + boxplot by X-high vs X-low" |
| "Identify the X+ Y+ Z- population" | "GatingProportion: gate cells in parent P, per-sample %" |

### Preferred Approach — when multiple options exist:
```
Option A: Individual correlations (GENE vs TARGET1, GENE vs TARGET2, ...)
Option B: GENE vs combined score of [TARGET1, TARGET2, ...]
Preferred: Option B (combined score) — more robust, single test
Also do: Option A as supplementary check for individual targets (only if ≤5 targets)
```

### mRNA Proxy Pieces:
```
Original claim: [protein/PTM-level claim] → Section 3
mRNA proxy test: Correlate [GENE] mRNA with [TARGET] mRNA in [cell type]
Note: Do not necessarily expect a result — protein-level effects may not
manifest at mRNA level.
Disclaimer: mRNA proxy only — protein/PTM level not testable by scRNA-seq.
Null result does not disprove paper's claim.
```

---

## Common Categorization Errors

| Wrong | Right |
|-------|-------|
| Protein-level claim in Section 2 | Section 3 — beyond capability (+ separate mRNA proxy in Section 2 if appropriate) |
| "Cell type absent" in Section 2 | Section 3 — missing cell type (check both data_pre.txt and data_pre_add.txt first) |
| Signature scoring in Section 1 | Section 2 — needs processing |
| GatingProportion piece in Section 1 | Section 2 — gating always requires processing |
| Vague gene lists | Check definitions_final.txt first, then list every gene explicitly |
| Missing "From brainstorm" link | Always include piece reference |
| Summary sentence gets testable pieces | Section 3 — "summary sentence, tested via sub-findings" |
| Duplicate analysis for feedback loop | Consolidate: "same test as Piece X.Y" |
| Proposing undefined score | Skip — "no standard scRNA-seq signature available" |
| Treatment comparison without checking metadata | Section 4 CONDITIONAL, or Section 3 if confirmed absent |
| CNV-dependent finding in Section 2 | Section 3 — CNV analysis out of current scope |
| Saying "compare" without specifying how | Always state: correlation + boxplot / DE + enrichment / gating / etc. |
| Only correlation without boxplot | Most testable pieces need BOTH correlation AND boxplot |
| Skipping DE+enrichment for broad claims | Always include when gene drives downstream pathway changes |
| Forcing composite X+ Y+ Z-low into a module score | Use GatingProportion (Pattern 4c) |
| Ignoring added annotations in `data_pre_add.txt` | Always check both metadata files; prefer existing annotations over new scores |
| Using patient column when sample column exists | Use sample column; note "exploration = sample-wise" |
| No stratified analyses proposed | Check metadata for stratification columns for every testable piece |
| No extra dataset-driven tests | Always scan metadata for additional interesting comparisons |
