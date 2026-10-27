# Task Planning Skill - Quick Reference

## Purpose
Identify and organize testable hypotheses from paper findings based on scRNA-seq data availability.

## Files

| Type | Path |
|------|------|
| Input | `Outputs/summary.txt` (paper findings) |
| Input | `Outputs/data_pre.txt` (native metadata — Stage 2 only) |
| Input | `Working/data_pre_add.txt` (added annotation columns — Stage 2 only) |
| Input | `Working/definitions_final.txt` (term definitions + gene lists) |
| Intermediate | `Working/preprocess-brainstorm.txt` |
| Output | `Working/plan0.txt` |

`data_pre_add.txt` holds annotation columns added on top of the original
metadata (e.g., refined cell-type labels, effector-state annotations).
Treat them the same as native metadata — their per-category proportions are
valid per-sample features. **If it contains a `paper_cell_type` column,
some paper-mentioned cell types may only exist in that column (alias-resolved
from different names in the original column). Use `paper_cell_type` as the
cell type column for those cell types in the Metadata Index.**

## Workflow
```
Stage 1: Brainstorm (summary.txt + definitions_final.txt)
       → Stage 2: Categorize (+ data_pre.txt + data_pre_add.txt)
       → Working/plan0.txt
```

## Quick Rules

- **Stage 1:** Read paper findings + definitions_final.txt only, do NOT read data_pre.txt or data_pre_add.txt
- **Stage 2:** Read brainstorm output + both metadata files
- **Stage 2 sample column:** Identify the sample column; if both `sample` and `patient` exist, prefer `sample` (we operate sample-wise for exploration, not patient-wise)
- **Don't** invent new findings beyond what the paper states
- **Do** break complex findings into multiple testable pieces
- **Do** flag non-scRNA-seq requirements as NOT TESTABLE early
- **Do** prefer the metadata column with fewer NAs when columns overlap
- **Don't** add cross-cancer framing or tissue-mismatch disclaimers — test directly

## Analysis Pattern Quick Reference

| Paper says... | You do... |
|---------------|-----------|
| A triggers/activates/promotes B | Correlation(A, B) + Boxplot(A-high vs A-low, compare B) |
| A correlates with pathway P | Correlation(A, P-score) + Boxplot(A-high vs A-low, compare P-score) |
| High A causes broad changes | DE + Enrichment (A-high vs A-low cells) |
| A elevated in cancer | Boxplot: A across cell types (NO condition split, pool all samples) |
| A affects cell composition | Correlation(A, %subtype) + Boxplot(A-high vs A-low, compare %subtype) |
| Composite feature "X+ Y+ Z-low" | **Gating + Proportion** — classify cells meeting all criteria, use per-sample % as feature |
| A predicts clinical outcome | Compare A by clinical groups (if metadata exists) |
| A secretes ligand → receptor on B → output in B | **TWO pieces:** (1) ligand in A vs receptor in B (cross-cell-type); (2) receptor vs output both in B (same-cell-type). NEVER ligand vs output directly |
| Feedback loop (A→B and B→A) | Single correlation — consolidate, don't duplicate |
| Protein/PTM claim | NOT TESTABLE + separate mRNA proxy with disclaimer |

**Standard testable piece = Correlation + Boxplot + (DE+Enrichment when applicable) + Stratified versions**

## Gating + Proportion Analysis (Pattern 4c)

When the paper defines a cell population by a mix of high and low markers
(e.g., "KRT8+ VIM+ CDH1-low partial-EMT epithelial cells"):

1. **Classify cells** meeting all criteria simultaneously:
   `KRT8 > threshold_KRT8 AND VIM > threshold_VIM AND CDH1 < threshold_CDH1`
   Threshold default: median expression (or expression > 0 for positivity gates).
2. **Per-sample proportion** of classified cells = the feature.
3. Use this feature in correlations / boxplots like any other per-sample feature.

Do NOT subtract, invert, or sign-flip the "low" gene to force it into a
module score — see ~/.claude/agents/Ref/Task_Plan_step0_v4/references/common-errors.md Error 26.

## Individual Gene Correlation Rule

- **≤5 target genes**: Individual correlation plots + combined score plot
- **>5 target genes**: Combined score only; individual correlations stored as values (no plots)

## Score Definitions Priority

1. Check `Working/definitions_final.txt` first
2. Fall back to KEGG / MSigDB Hallmark / standard sources
3. If no clear gene list exists → skip the score

## Categories (Stage 2)

| Category | Meaning |
|----------|---------|
| Section 1: DIRECT CHECK | Gene/score already in data, no extra computation |
| Section 2: DOABLE WITH PROCESSING | Needs scoring, gating, subtype annotation, sample grouping, etc. |
| Section 3: NOT TESTABLE | Beyond scRNA-seq, missing cell type, summary sentence, CNV-dependent, etc. |
| Section 4: CONDITIONAL | Testable only if specific metadata exists — state the condition |

## Stage 2 Additional Requirements

- **Sample column**: Identify in the metadata index; prefer `sample` over `patient` if both exist
- **Added annotations**: `data_pre_add.txt` columns are valid metadata — use them for subtype assignment, proportion features, or stratification
- **Stratified analyses**: For each testable piece, propose repeating the analysis stratified by available metadata (disease stage, sex, etc.)
- **Extra dataset-driven tests**: After paper-driven pieces, propose additional comparisons enabled by the metadata (high-level, ONE simple analysis each)

## Critical Additions (from validated examples)

- **Skip summary sentences** — mark NOT TESTABLE, tested via sub-findings
- **Consolidate feedback loops** — don't duplicate analyses for the same correlation
- **mRNA proxy OK with label** — always add "mRNA proxy only" disclaimer
- **Every score needs a gene list** — check definitions_final.txt first, then KEGG/Hallmark
- **Specify analysis type** — use the Analysis Pattern Quick Reference above
- **Most pieces need correlation + boxplot** — not just one or the other
- **Always consider DE + enrichment** — as unbiased validation for broad claims
- **CNV analysis out of scope** — flag as NOT TESTABLE
- **Hard-to-define scores → skip** — don't invent vague signatures
- **Composite high/low features → gating + proportion** — never subtract or invert
- **Cross-cell-type per-sample correlation** is valid for inter-cellular claims
- **State preferred approach** when multiple options exist
- **Prefer existing metadata over module scores** — use %G2M instead of G2M score if Phase column exists; use added-annotation proportions from `data_pre_add.txt` when they match
- **Cell subtype proportion is a feature** — can be correlated/boxplotted per sample
- **Cell type comparisons: no condition split** — pool all samples for Pattern 4
- **Extra tests: high-level only** — one simple analysis each, no detailed breakdowns
- **Combine similar boxplots** — create combined group column (e.g., sex_Type) instead of separate plots
- **≤5 genes: individual plots + combined; >5 genes: combined score only**
