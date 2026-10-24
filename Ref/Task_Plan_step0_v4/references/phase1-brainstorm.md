# Phase 1: Data-Agnostic Brainstorm

## Goal
For each paper finding, enumerate ALL possible ways it could be tested with
scRNA-seq data — without yet considering whether your specific dataset has
the required data.

---

## Before Starting Phase 1

1. Read `Working/definitions_final.txt` to know the paper's term definitions
   and recommended gene lists for scoring.
2. **Do NOT read `Outputs/data_pre.txt` or `Working/data_pre_add.txt`** in
   this phase. This phase is data-agnostic.
3. Create `Working/preprocess-brainstorm.txt` with the header:
```
# Brainstorm: Testable Pieces from Paper Findings
# Stage 1 output — data-agnostic
```

---

## Pre-Screening: Skip or Consolidate Before Decomposing

Before decomposing a finding, check:

1. **Is it a summary sentence?** If the finding merely restates or summarizes other
   findings already listed, mark it NOT TESTABLE with reason "summary sentence —
   tested via its sub-findings." Do NOT create testable pieces for it.

2. **Is it redundant with a previous finding?** If it describes the same biological
   relationship from a different angle (e.g., a feedback loop restating an earlier
   correlation), write: "Same test as Finding #X, Piece X.Y — feedback loop /
   alternate framing." Do NOT create a duplicate analysis.

3. **Is it purely about a non-transcriptomic mechanism?** If the core claim is about
   protein localization, post-translational modification, enzymatic activity, or
   spatial architecture with no transcriptional readout at all, flag the entire
   finding as NOT TESTABLE immediately. Then check: can an mRNA proxy piece be
   extracted? If yes, create it as a separate piece with disclaimer.

---

## Analysis Pattern Tutorial — Claim-to-Analysis Mapping

Use this mapping to assign the correct analysis types to each testable piece.
**Most pieces should have multiple analysis types** — correlation alone is not enough.

### Pattern 1: "A triggers/activates/promotes B"
The paper says gene A activates, triggers, promotes, or upregulates gene/pathway B.

**Assign both:**
- Correlation: Per-sample correlation of A vs B in the relevant cell type
- Boxplot: Split samples by A expression level (median or quartile), compare B
  levels between A-high vs A-low groups

**Example:** "STAT3 upregulates BCL2 in tumor cells"
→ (1) Per-sample correlation: avg STAT3 vs avg BCL2 in tumor cells
→ (2) Split samples into STAT3-high vs STAT3-low, boxplot compare BCL2 expression

### Pattern 2: "A correlates with pathway/program B"
The paper says gene A is associated with a pathway or biological program.

**Assign both:**
- Correlation: Per-sample correlation of A vs B-score
- Boxplot: Split samples by A level, compare B-score between groups
- Score definition: Check `Working/definitions_final.txt` first, then KEGG/Hallmark

**Example:** "VEGFA promotes the angiogenesis program in endothelial cells"
→ (1) Per-sample correlation: avg VEGFA vs avg angiogenesis score in endothelial cells
→ (2) Split samples into VEGFA-high vs VEGFA-low, boxplot compare angiogenesis score

### Pattern 3: "High A leads to broad changes" → DE + Enrichment
The paper implies gene A has broad transcriptional effects on a pathway or program.

**Assign:**
- DE + Enrichment: Split cells by A expression, run DE between A-high vs A-low,
  then run pathway enrichment (GO over-representation preferred)

**This is a general-purpose analysis.** Apply it whenever a gene is claimed to drive
downstream changes, EVEN IF specific targets are also tested via Patterns 1-2.
The DE + enrichment serves as an unbiased check.

**Example:** "NOTCH1 drives stemness and cell cycle progression in epithelial cells"
→ In addition to specific gene/score correlations, also do: split epithelial cells
by NOTCH1 level, DE between groups, check if stemness / cell-cycle / Notch-signaling
GO terms are enriched in NOTCH1-high cells.

### Pattern 4: "A is elevated in cancer cells"
**Assign:**
- Boxplot comparison: A expression across cell types (malignant vs each non-malignant)
  with statistical test

### Pattern 4b: "Proportion of subtype X differs" / "Gene A correlates with cell composition"
When the paper claims that a gene affects cell composition (e.g., more G2M cells,
more of a subtype):

**Assign:**
- Correlation: Per-sample correlation of gene A vs proportion of subtype X
- Boxplot: Split samples by A level, compare proportion of subtype X

**Key rule:** Cell subtype proportion is a per-sample feature. When the dataset
already has relevant annotations (e.g., cell cycle Phase column, or added
annotation columns in `data_pre_add.txt`), use the proportion of cells in that
category rather than computing a module score.

### Pattern 4c: Composite feature "X+ Y+ Z-low" → Gating + Proportion (GatingProportion analysis)

When the paper defines a cell population by a **mix of high and low markers**
(e.g., "KRT8-positive, VIM-expressing, CDH1-low partial-EMT epithelial cells"), do **NOT** use
a module score — module scoring assumes all genes should be high.

**Assign the GatingProportion analysis:**

1. **Classify cells** meeting all criteria simultaneously, within the relevant
   parent cell type:
   ```
   gated_cells = (KRT8 > threshold_KRT8)
               & (VIM  > threshold_VIM)
               & (CDH1 < threshold_CDH1)
   ```
   Default thresholds: median expression (or expression > 0 for "positivity" gates).
   State the threshold choice explicitly.

2. **Compute per-sample proportion** of gated cells within the parent type:
   `proportion = #(gated cells in sample) / #(parent-type cells in sample)`

3. **Use this proportion as the feature** for downstream correlations /
   boxplots / comparisons, exactly like any other per-sample feature (Pattern 4b).

**Why gating instead of a module score:**
- Module score + subtraction → produces negative values and scale mismatch
- Module score + inverse of "low" gene → unbalanced contribution
- Gating matches the paper's biological framing (the paper describes a
  *population*, not a continuous score)
- Proportion is naturally positive and interpretable

**Example:** "KRT8+ VIM+ CDH1-low partial-EMT epithelial cells drive local invasion"
→ Gate epithelial cells on `KRT8 > median AND VIM > median AND CDH1 < median`
→ Per-sample % of gated cells within the epithelial compartment
→ Correlate that proportion with a per-sample invasion/migration score,
  or boxplot by high/low groups

**Continuous-score fallback (only if a continuous feature is explicitly required):**
Compute two separate module scores — one for high genes [KRT8, VIM], one for
the low gene [CDH1] — and test them separately with opposite expected
directions. Label clearly. Do NOT combine them arithmetically.

### Pattern 5: "A predicts outcome / clinical variable"
**Assign:**
- Group samples by clinical variable, compare A
- Flag as CONDITIONAL if unsure whether metadata exists

### Pattern 6: Feedback loop
**Action:** Consolidate. "Same test as Piece X.Y — single correlation covers both."

### Pattern 7: Protein/PTM claim
**Action:** NOT TESTABLE for protein claim. Separate mRNA proxy piece with disclaimer.
Note: do not expect the mRNA proxy to necessarily show a result.

### The standard testable piece should include:
1. **Correlation** (Pattern 1 or 2) — core directional test
2. **Boxplot** (Pattern 1 or 2) — visual confirmation by sample grouping
3. **DE + Enrichment** (Pattern 3) — when the gene is claimed to drive broad changes
4. **GatingProportion** (Pattern 4c) — when the claim involves a composite
   high/low-marker population
5. Note: Stratified versions will be added in Stage 2 after checking metadata

### Cell subtype proportion as a feature:
When the paper discusses cell composition changes (e.g., "more G2M cells",
"increased proportion of subtype X"), the per-sample proportion of that subtype
is itself a feature that can be:
- Correlated with a gene (per-sample correlation)
- Compared between groups (boxplot)

Use this instead of module scores when the dataset either already has the
relevant annotation natively or is expected to have it as an added annotation
(cell cycle Phase → %G2M instead of G2M_checkpoint score). Stage 2 confirms
which annotations are actually present.

### Individual gene correlations — size-based rule:
- **≤5 target genes**: Individual correlation plots for each + combined score plot
- **>5 target genes**: Combined score only; individual correlations stored as values (no plots)

### Multi-component claims — combined + pairwise decomposition:
When a claim involves multiple causal factors (A and B) driving a phenotype
defined by multiple indicators (C and D), decompose into **BOTH**:
1. **Combined**: (A+B) score vs (C+D) score — tests the full claim as stated
2. **All pairwise**: A vs C, A vs D, B vs C, B vs D — identifies which specific
   interactions carry the signal

**Both are mandatory.** The combined test alone hides which component drives the
effect. The pairwise tests alone miss the joint signal. List every pairwise
correlation explicitly in the processing steps — do not collapse the readout
side into a single combined measure without also testing each component
separately.

This applies whenever the paper names a composite cause or a composite phenotype
that has distinguishable components. A category that contains distinguishable
sub-types (e.g., "lymphocytes" = T cells + B cells, "myeloid" = macrophages +
monocytes + DCs) counts as multi-component — decompose it.

**Example:** "Tumor-associated endothelial cells and pericytes together promote
myeloid infiltration" where myeloid = macrophages + neutrophils. Endothelial %
(A) and pericyte % (B) are the causal factors; macrophage % (C) and neutrophil %
(D) are the readouts.
- Combined: (endothelial+pericyte) vs (macrophage+neutrophil)
- Pairwise (all 4): endothelial%-macrophage%, endothelial%-neutrophil%,
  pericyte%-macrophage%, pericyte%-neutrophil%

---

## For Each Finding (sequentially):

### Step 1: Identify the Core Claim

Extract the central biological statement. Ask:
- What cell type is doing what?
- What gene/pathway/population is involved?
- What is being compared (condition A vs B, cell type X vs Y, gated vs ungated)?

### Step 2: Decompose Into Testable Pieces

| Finding Pattern | Possible Testable Pieces |
|-----------------|--------------------------|
| "X correlates with Y" | Correlation of X vs Y per sample + boxplot X-high vs X-low |
| "X high group has more Y" | Boxplot: group by X, compare Y + correlation X vs Y |
| "Cell A expresses gene G in condition C" | DE analysis: cell A in C vs non-C |
| "X activates transcription of Y" | Correlation X vs Y + boxplot X-high vs X-low compare Y |
| "X activates pathway P" | Correlation X vs P-score + boxplot + DE+enrichment for P |
| "Gene G predicts outcome O" | Correlation of G with O (only if O is in metadata) |
| "Pathway P enriched in cell type X" | Signature scoring + condition comparison |
| "Cell A affects cell B" | Per-sample cross-cell-type correlation: score in A vs score in B |
| "Cell A secretes ligand L → receptor R on cell B → output Z in cell B" | **TWO pieces:** (1) Ligand L in A vs receptor R in B (cross-cell-type); (2) Receptor R vs output Z, both in B (same-cell-type). NEVER test ligand L in A vs output Z in B directly — see common-errors.md Error 16 |
| "Gene G high in condition C vs D" | Boxplot comparison of G between conditions C and D |
| "Gene G affects cell composition" | Per-sample correlation of G vs proportion of relevant subtype |
| "Population X+ Y+ Z-low..." | GatingProportion: gate on criteria → per-sample proportion as feature |
| "KO/overexpression of gene G causes broad changes" | Group cells by G expression, DE + enrichment |
| "Gene G associated with clinical outcome" | Group samples by G level, compare metadata |

### Step 3: For Each Piece, Document

- **Type**: List ALL applicable analysis types using the Pattern Tutorial above
  (e.g., "Correlation + Boxplot + DE+Enrichment", or "GatingProportion + Correlation")
- **Check**: The exact statement being tested (one sentence)
- **Cell types needed**: Which specific cell types (or parent type, for gating)
- **Features needed**: Which genes, scores, proportions, or metadata fields
- **Definitions needed**: Check `Working/definitions_final.txt` first for gene lists.
  If not there, use KEGG/Hallmark/paper-defined sets. List every gene explicitly
  or name the exact source. For gating, list the gates and default thresholds.
- **Conditions/groups**: What comparison groups are required
- **Processing required**: All computation steps — scoring, gating, grouping, DE, enrichment
- **Preferred approach**: If multiple analysis strategies exist, state them and
  indicate preference
- **Conditional on metadata**: If this piece is only testable given specific metadata,
  state the requirement

### Step 4: Flag NOT TESTABLE Pieces

Mark `[FLAG: NOT TESTABLE]` immediately if the piece requires:
- Protein abundance or localization
- Post-translational modifications (phosphorylation, glycosylation)
- Functional assays (cell killing, migration, cytokine secretion)
- Spatial relationships (cell-cell contact, tissue architecture)
- Epigenetic readouts (methylation, histone modification)
- Copy number variation analysis (CNV is out of current scope)

**mRNA proxy exception**: If the paper claims a protein-level effect but the gene's
mRNA expression is still informative, you MAY propose an mRNA-level test BUT must:
1. Label it explicitly: `[mRNA PROXY — protein/PTM level not testable by scRNA-seq]`
2. Note that a null result does not disprove the paper's claim
3. Note "do not necessarily expect a result" for protein/PTM proxies
4. Categorize it as a separate piece from the NOT TESTABLE protein claim

### Step 5: Flag CONDITIONAL Pieces

Mark `[FLAG: CONDITIONAL]` if the piece depends on metadata that may or may not exist:
- Treatment condition (e.g., NACT vs chemo-naive)
- Tumor site (primary vs metastatic vs recurrent)
- Cell cycle annotation
- Clinical variables (survival, stage, grade)
- Specific cell subtype annotations (may be native, may be in `data_pre_add.txt`,
  may be absent — Stage 2 resolves)

State the condition explicitly:
```
[FLAG: CONDITIONAL — requires treatment condition metadata]
If available: group samples by treatment, compare [score/gene]
If unavailable: skip this piece
```

### Step 6: Flag Scores That Are Hard to Define

If a biological concept lacks a clear, established gene signature for scRNA-seq:
- First check `Working/definitions_final.txt` — the definition may be there
- If not there, check standard sources (KEGG, Hallmark, etc.)
- If no established gene list exists anywhere, flag it:
```
[FLAG: SKIP IF NO CLEAR DEFINITION — migration score / invasion score / etc.
has no standard gene list for scRNA-seq]
```
Do not invent vague or arbitrary gene lists.

### Step 7: Append to preprocess-brainstorm.txt immediately after each finding.

---

## Output Format
```
=============================================================================
FINDING #[N]: [One-line description]
=============================================================================

[If summary sentence: NOT TESTABLE — summary sentence, tested via sub-findings]
[If redundant: Same test as Finding #X, Piece X.Y]

Testable Piece [N.1]:
- Type: [Correlation + Boxplot / Correlation + Boxplot + DE+Enrichment /
         GatingProportion + Correlation + Boxplot / etc.]
  Pattern(s): [which patterns from the tutorial apply]
- Check: [Exact one-sentence statement being tested]
- Cell types needed: [e.g., Malignant cells, CD8+ T cells, Macrophages (parent for gating)]
- Features needed: [e.g., gene names, score names, gated-population proportion]
- Definitions needed: [gene list from definitions_final.txt / KEGG / etc.;
                       for gating: the gate genes + threshold rule]
- Conditions/groups: [e.g., per-sample / GENE-high vs low]
- Processing required:
  (a) Correlation: [steps]
  (b) Boxplot: [steps]
  (c) DE + Enrichment: [steps, if applicable]
  (d) GatingProportion: [gate definition, threshold, parent type, if applicable]
- Preferred approach: [if multiple options, state preference]
- [FLAG: NOT TESTABLE — reason] if applicable
- [FLAG: CONDITIONAL — what metadata is required] if applicable
- [mRNA PROXY — disclaimer] if applicable
- [FLAG: SKIP IF NO CLEAR DEFINITION — reason] if applicable
```

---

## What NOT to Do

| Wrong | Right |
|-------|-------|
| Read data_pre.txt or data_pre_add.txt in this phase | Only use summary.txt + definitions_final.txt |
| Invent findings not in paper | Stay strictly within paper claims |
| Combine multiple findings into one piece | One biological claim per piece |
| Skip flagging non-scRNA-seq claims | Flag [NOT TESTABLE] early |
| Forget processing requirements | Always note if scoring/gating/annotation needed |
| Create duplicate analysis for feedback loops | Consolidate and reference earlier piece |
| Propose a score without gene list | Check definitions_final.txt first, then KEGG/Hallmark |
| Say "compare" without specifying how | State: correlation + boxplot + DE, etc. |
| Propose "chromosomal abnormality score" | Skip — no clear scRNA-seq definition |
| Ignore mRNA proxy opportunity | Protein claim → NOT TESTABLE + separate mRNA proxy piece |
| Assume metadata exists | Flag CONDITIONAL when unsure |
| Only assign correlation without boxplot | Most pieces need both correlation AND boxplot |
| Skip DE+enrichment for broad claims | Always include DE+enrichment when gene drives broad changes |
| Force a composite "X+ Y+ Z-low" claim into a module score | Use GatingProportion (Pattern 4c) |
| Compute module score when concept already annotated | Plan to use proportion from existing annotation (confirmed in Stage 2) |
| Propose individual correlation plots for >5 genes | For >5 targets, use combined score; store individual correlations as values only |
