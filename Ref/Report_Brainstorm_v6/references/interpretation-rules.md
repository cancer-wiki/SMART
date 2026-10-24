# Interpretation Rules

## Goal
Detailed guidance on how to interpret each kind of analysis output produced
by the analysis script when assessing discovery transferability. This file
expands on the headline rules in `SKILL.md` and is the agent's primary
reference during Phase 1 (per-step observation).

---

## ⚠️ Overriding principle

We are testing whether a paper's discovery in Cancer Type X provides
**useful leads** for Cancer Type Y. We are NOT testing whether the exact
molecular mechanism replicates.

Across different cancer types, expect:
- The broad directional logic (Gene A → Pathway → Phenotype) often holds.
- The specific molecular targets within the pathway frequently differ.
- The effect can be stronger in one disease subtype than another.
- The metabolic / phenotypic output may be a related variant, not identical.

All of these are **positive findings** that justify follow-up. See
`SKILL.md` → "Transfer Types" for the five-way classification used
throughout this agent.

---

## Where the numbers live

The analysis script saves results to two places:
- **`Outputs/plots/`** — plot PDFs (one per analysis task). The numerical
  values you typically need (r, p, n, median direction, sample size,
  significant-gene counts) are shown directly on the plot.
- **`Outputs/results/`** — statistical files (CSVs, TXTs) for steps that have
  per-row data — e.g., the full DE gene table or the GO enrichment table.

In practice you should be able to interpret most steps from the plot
alone. Open a stat file when you need a field the plot doesn't display —
typically when looking up a specific gene's `avg_logFC` in a DE table or
reading the full term list of a GO enrichment.

---

## Result Type 1: Correlation plots (`correlate_celltype_features`)

### What to look at, in this order
1. **Per-condition correlations FIRST** — shown on the plot (typically
   colour-coded by condition with a per-condition r and p annotated).
2. **Overall correlation SECOND** — also annotated on the plot.
3. **Visual pattern** — does one condition's coloured points show a tighter
   trend than the others?
4. **Outliers** — any single sample pulling the correlation strongly?

### Why per-condition comes first
The overall correlation mixes biologically distinct populations. If
Condition A shows r = 0.35 and Condition B shows r = −0.20, the overall
might be 0.05 — which looks like "no relationship." But the real finding
is that the relationship EXISTS in Condition A and is REVERSED in
Condition B. Leading with overall r ≈ 0 and calling it "absent" is wrong.

### Interpretation table
| Pattern | Transfer assessment |
|---|---|
| One condition r > 0.25 in the expected direction | **Directional transfer in that condition** — report as positive |
| One condition r > 0.4 in the expected direction | **Strong directional transfer in that condition** |
| Overall r > 0.3 in the same direction as the paper | **Directional transfer overall** |
| Overall r > 0.2 consistent across conditions | **Weak but consistent directional transfer** |
| Overall r ≈ 0, both conditions ≈ 0 | **Absent** |
| Overall r ≈ 0, conditions diverge | **Condition-dependent** — transfer in one, reversed in the other |
| Overall r opposite to the paper's prediction, p < 0.05 | **Contradictory** |

### Reporting template
```
Observation:
  - Subtype A: r = 0.259, p = 0.271 (positive trend, consistent with paper)
  - Subtype B: r = -0.296, p = 0.233 (opposite direction)
  - Overall:   r = -0.044, p = 0.794 (diluted by mixing two divergent populations)
Interpretation: The Gene X – Target Y link shows a positive trend in
  Subtype A consistent with the paper. The overall null reflects
  cancellation between divergent condition-specific effects, not absence
  of the relationship.
Transfer: Directional in Subtype A; reversed in Subtype B
```

### Common pitfall
Do NOT write *"there is NO correlation (r = -0.044)"* and stop there.
Always check the per-condition split. The example above is NOT "absent"
— it is "condition-dependent with directional transfer in Subtype A."

---

## Result Type 2: Boxplots (`compare_features_boxplot`)

### What to look at
- **p-value** — annotated in the plot title or subtitle.
- **Median direction** — which group has the higher median?
- **Direction match** — does the higher group match the paper's prediction?
- **Spread / overlap** — how much do the boxes overlap?
- **Sample size** — `n` shown in the plot subtitle. Small n means low power;
  do not dismiss visible trends just because p > 0.05.

### Interpretation table
| Pattern | Transfer assessment |
|---|---|
| p < 0.05, expected direction        | **Strong support** |
| p = 0.05–0.15, expected direction   | **Directional** — trend in the right direction given limited power |
| p > 0.2 but visible median difference | **Weak directional** — note the visual trend |
| p < 0.05, opposite direction        | **Contradictory** |
| p ≈ 1.0, no visual difference       | **Absent** |

### Common pitfall
With n = 19 vs 19 (typical for median-split pseudobulk), statistical power is
limited. p = 0.08 with a visible median shift is more informative than
the p alone suggests. Do not dismiss as "non-significant."

---

## Result Type 3: Volcano plots and DE results (`run_de_analysis`)

### Direction verification — do once, reuse forever

The DE analysis uses pseudobulk DE. The sign of `avg_logFC`
depends on how Libra internally orders the condition factor levels —
alphabetical order, which may NOT match the `condition1`/`condition2`
order specified in `plan2.txt`. Getting this wrong reverses every
DE-derived interpretation, so the mapping must be confirmed once before
any DE-based claim.

**Verification procedure** (do this once, the first time you encounter
DE results):

1. Open the DE stat file in `Outputs/results/` (e.g.,
   `de_GeneX_high_vs_low_CancerType.csv` or similar) and confirm the
   column names — typically `gene`, `avg_logFC`, `p_val`, `p_val_adj`.
2. Pick ONE gene whose direction you can independently verify from
   another result in the same run. The best option is a gene that has a
   boxplot (`compare_features_boxplot`) — that boxplot directly shows
   which condition has the higher mean.
3. Read off the boxplot: is the gene HIGHER or LOWER in `condition1`
   (the GeneX-high group)?
4. Look up the same gene in the DE table and check the sign of its
   `avg_logFC`.
5. Confirm the mapping:
   - Boxplot says HIGHER in GeneX-high, DE shows POSITIVE logFC →
     positive logFC means up in `condition1` (GeneX-high). ✓
   - Boxplot says HIGHER in GeneX-high, DE shows NEGATIVE logFC →
     positive logFC means up in `condition2` (GeneX-low) — direction
     is FLIPPED. ✗

**Record the result at the top of `report_brainstorm.txt`** using the
DE DIRECTION RECORD block in `output-template.md`. Reuse this mapping
for every DE-derived interpretation that follows. Do not re-verify per
step.

If the direction is flipped, every subsequent DE claim must be mentally
reversed: genes the table calls POSITIVE logFC are up in `condition2`,
GO enrichment of "positive logFC" genes is actually enrichment in
`condition2`, and so on.

This is the single most common source of catastrophic misinterpretation
in DE analysis — but once the mapping is established and recorded, it's
a fixed lookup, not a recurring concern.

### What to look at after the direction is recorded
- **Number of significant genes (up and down)** — annotated in the volcano
  subtitle.
- **Distribution symmetry** — roughly equal up/down, or skewed?
- **Key genes from the paper's mechanism** — even if not FDR-significant,
  do they trend in the expected direction (after applying the direction
  mapping)?
- **Volcano plot shape** — dense centre (few changes) vs spread (many
  changes).

### Looking up specific genes in the DE table

When checking paper-relevant genes:
```r
de <- read.csv("Outputs/results/de_<task>.csv")
gene_oi <- c("TargetY", "EffectorA", "EffectorB", "ProlifMarker")
de[de$gene %in% gene_oi, ]
```
Report direction (sign of `avg_logFC`, mapped through the direction
record), raw p-value, and adjusted p-value. **Even if not significant,
the direction matters.** logFC = 0.3, p_adj = 0.4 in the expected
direction is weak support. logFC = -0.5 in the opposite direction is
evidence against.

If only the volcano plot is available (no per-gene table), restrict
gene-level inspection to the labelled top genes visible on the plot.

---

## Result Type 4: GO enrichment (`run_go_enrichment`)

### What to look at
- **Top enriched terms** — visible on the dot plot. The full term list
  with adjusted p-values lives in the matching CSV in `Outputs/results/`
  (one for "up" genes, one for "down" — labelled with the direction).
- **Gene ratios and counts** — how many genes drive each term?
- **Adjusted p-values** — colour scale on the dot plot.

### Interpretation through the alternative-transfer lens
The paper claims a specific pathway (e.g., "Pathway Z → metabolic
phenotype"). In GO terms, look for:

1. **Direct match** (exact pathway name appears) → **Exact transfer**
2. **Related pathway** (e.g., "cellular respiration", "ATP metabolic
   process" when the paper claims metabolic reprogramming) →
   **Alternative transfer** — the metabolic theme is conserved even if
   the specific pathway differs.
3. **Upstream / downstream** (e.g., "nucleotide biosynthesis" suggesting
   active proliferative metabolism) → **Indirect support**.
4. **Biological theme match** (e.g., downregulated genes show
   "differentiation" / "development" → consistent with aggressiveness)
   → **Thematic transfer**.

### Common pitfall
Don't require exact pathway name matches. If the paper claims one
metabolic program and GO shows a related-but-different one, this is
alternative transfer in a metabolic-reprogramming context, not failure.

---

## Result Type 5: Cell-type proportion comparisons (`compare_celltype_by_group`)

### What to look at
- **Direction** — which group has the higher proportion?
- **p-value** — annotated on the plot.
- **Spread** — high variance reduces confidence.

### Interpretation
Same principles as boxplots (Result Type 2). Key question: does the
gene-high group show the cell-composition shift the paper predicts?

### Tumor-vs-normal claims tested by cross-cell-type comparison

When the paper claims "Gene X is elevated/upregulated in cancer vs normal
tissue" but the dataset lacks matched normal tissue, the cross-cell-type
comparison (Gene X across cell types in a tumor-only dataset) serves as a
**proxy** test. When interpreting this proxy:

- Frame the result as: "Gene X is expressed in [malignant cell type] at
  [level] relative to other cell types in the TME."
- Acknowledge the proxy: "The paper's tumor-vs-normal elevation claim
  is not directly testable without normal tissue; this cross-cell-type
  result establishes expression in the relevant compartment."
- Do NOT claim that the cross-cell-type result confirms the
  tumor-vs-normal elevation.

---

## Cross-step interpretation: the mechanistic chain

The paper describes a chain: Gene A → Gene B → Pathway C → Phenotype D.
Each analysis step tests one link.

### Proxy test transparency

When reporting a chain link, verify that the test actually correlates the
two nodes named in the link. If the test uses a different upstream gene
as a proxy (e.g., the chain says B → C but the test correlates A with C),
label it explicitly as a proxy test spanning multiple links rather than
claiming it tests the direct B → C link.

### Three ways a link can "hold"
1. **Exact** — A correlates with B specifically.
2. **Alternative** — A doesn't correlate with B, but A correlates with
   the broader pathway C that B belongs to.
3. **Directional** — A trends with B in the expected direction in at
   least one condition, even if not significant.

### When a link is truly broken
A link is truly broken only if ALL of these hold:
- The overall correlation is near zero, AND
- All per-condition correlations are near zero or reversed, AND
- The broader pathway-level analysis also shows no relationship, AND
- The GO enrichment shows no related terms.

If any of those show a positive signal, the link is not broken — it is
weakened or operating through alternative wiring.

### Convergent evidence
Multiple weak signals pointing the same way are stronger than a single
strong one in isolation. Example:
- Gene X – Target Y: r = 0.26 in Subtype A (weak positive, expected dir)
- Gene X – Pathway Z score: r = 0.42 in Subtype A (moderate, expected dir)
- Effector A boxplot: p = 0.089, higher in Gene X-high (trending, expected dir)
- Proliferation marker correlation: r = 0.30 (consistent positive)
- GO: metabolic and biosynthetic terms upregulated

→ No single result is definitive. Collectively, the directional pattern
strongly suggests the broad axis operates in Subtype A. **Score Middle-High**
(moderate alternative transfer), not Middle-Low or Low.

---

## Condition-specific divergence is a finding, not noise

When results systematically differ between conditions (different disease
subtypes, treatment stages), this is a major finding — never average it
away.

- Don't write "the overall correlation is weak" if the conditions diverge.
  That hides the real story.
- Report each condition separately. *"In Subtype A, 5 of 7 links trend in
  the expected direction. In Subtype B, most are reversed."*
- Interpret the divergence: what differs between conditions? Treatment?
  Clonal evolution? Microenvironment?
- If the logic holds in one major condition (e.g., Subtype A = ~50% of
  samples), that IS partial transfer. Score should reflect this.

---

## Scoring boundaries (resolves what counts as High / Middle-High / Middle-Low / Low)

**Automatic High rule (check FIRST, before reading anything below):**
If EVERY testable link in the mechanistic chain transfers (exact or
directional), the score is High. Stop here — do not read the criteria
below to find reasons to downgrade. A link that you assessed as
"directional" in your per-step observations IS a transferring link.
Variation *within* a transferring link (e.g., the effect operates through
a different sub-population, or one sub-component is directional while
another is exact) does not make the link a "gap." A link fails only if
its overall assessment is absent or reversed. If zero links fail, the
score is High.

---

The scoring table in `SKILL.md` is the canonical version. The boundary
cases that arise in practice:

**Score Low if at least one of these is true:**
- Overall directions are actively reversed (significant in opposite
  direction) on the core mechanistic links, AND no condition-specific
  rescue holds, AND GO shows no related themes.
- The paper's central NOVEL claim (the part that distinguishes its
  contribution, not generic upstream regulation) fails in every
  examined condition AND has no alternative-transfer support at the
  pathway level.
- Most checks are absent (r ≈ 0, no median shift) AND no convergent
  directional signal exists across the chain.
- **Only upstream regulatory relationships transfer** (see Upstream-Only
  Transfer Rule below).

**Score Middle-Low if:**
- At least one downstream functional link shows signal (even if
  borderline or in one subgroup), BUT the chain is broken — either the
  central claim is contradicted while peripheral links survive, or
  transfer depends on a single small subgroup.
- Alternative pathway evidence exists but is thematically loose — the
  GO overlap is with generic cancer hallmarks (immune, metabolic,
  proliferative) rather than mechanistically plausible alternatives on
  the same biological axis.
- The gene operates in a fundamentally different cellular context in
  the target dataset (e.g., endothelial vs tumor-cell), undermining the
  mechanistic story even if correlations survive.

**Score Middle-High if:**
- Most of the chain transfers, with at most one significant gap or one
  condition-dependent core link.
- At least one downstream functional claim is confirmed in a condition
  with adequate representation.
- Minor contradictions exist but do not invalidate the central logic.
- Alternative transfer is mechanistically plausible (same biological
  axis, different effectors — e.g., ALOX5 instead of GPX4 for lipid
  peroxidation).

**Score High only if:**
- The core links hold (overall or in the dominant condition) with
  consistent directions (3+ sequential links), AND
- The paper's key downstream/functional claim is confirmed (exactly or
  via mechanistically plausible alternative, or directionally consistent
  when n≤5 per condition), AND
- No major contradiction surfaces on core links.


### Pre-scoring self-check

Before finalizing the score, verify against these rules:

- Did I penalize any link for lack of significance when n≤5 per
  condition? Direction is sufficient. (Rule 4 + "Consistently
  Positive Direction at Small n")
- Did I split a combined signaling axis and penalize one sub-axis?
  Evaluate combined. (Rule 4b + "Combined Score Represents the
  Claim")
- Did I call a spatial/structural claim "absent" based on proportion
  correlation? Spatial claims are not testable from dissociated
  scRNA-seq. ("Co-enrichment vs co-localization")
- Did I count a NOT TESTABLE claim as a gap that downgrades the
  score? Not-testable claims do not count against the score. ("Claims
  NOT TESTABLE by Design Should Not Downgrade")
- Did I cite DE failure at n≤5 as evidence against a claim? Small-n
  DE is uninformative, not negative. ("DE With Very Small Sample
  Sizes Is Uninformative")
- Did I conflate separate independent claims into one "Partial"?
  Assess each claim independently. ("Assess Each Claim
  Independently")
- Did I downgrade because transfer is in one condition only?
  Transfer in the relevant condition IS transfer. ("Context-Specific
  Claims")
- Did I fabricate a claim the paper did not make, then penalize for
  it not transferring? Only assess claims from summary.txt. If the
  summary describes a feature as characterizing or describing a state
  (not as a functional signaling claim), the characterization test
  satisfies the claim — do not fabricate an additional functional
  link and penalize for it. ("Do Not Fabricate Claims")
- Did I call a result a "gap" in the scoring after acknowledging in
  my observations that the same result is "directionally correct" or
  "sufficient at n≤5"? Do not contradict your own observations at
  scoring time.
- Did every testable link transfer (exact or directional)? If yes,
  the score MUST be High — do not downgrade based on variation within
  transferring links (e.g., effect through a different sub-population,
  or within-condition underpowered at small n). A link only fails if
  its overall assessment is absent or reversed. ("Automatic High
  rule")

---

### ⚠️ Upstream-Only Transfer Rule

**If only upstream regulatory relationships transfer but ALL downstream
functional claims (the paper's novel mechanism) fail, the score is Low.
Upstream conservation alone does not constitute mechanism transfer.**

This rule is the single override on the "alternative transfer is still
transfer" framing — it is deliberately strict because of *what* it
applies to.

**What counts as "upstream regulatory relationships":**
- A transcription factor binding the same target gene
- A signaling kinase phosphorylating its expected substrate
- A receptor expressed in the expected cell type
- A regulator and its known direct target both showing the expected
  correlation

These are evolutionarily conserved, often present across virtually any
human tissue, and almost never the paper's actual contribution.

**What counts as "downstream functional claims":**
- The phenotypic output the paper attributes to the mechanism (the
  metabolic shift, the proliferation change, the differentiation block)
- The disease-relevant cell-population shift the paper reports
- The pathway activity readout (module score, signature score) that
  reflects the mechanism's biological output
- Any claim about how the mechanism distinguishes the paper's cancer
  type or condition from others

**Why the rule exists:**
Most papers' novel contribution is in the downstream chain — the
specific mechanistic story from a regulator to a phenotype, in a
specific disease context. If that chain fails entirely in the new
dataset and only the generic upstream wiring is preserved, the paper's
actual claim has not transferred. Calling that "alternative transfer"
or "directional transfer" misrepresents what was preserved.

**How to apply it during scoring:**
1. Identify which links in the mechanistic chain are upstream
   regulatory (regulator-target relationships) vs. downstream
   functional (phenotypes, pathway outputs, cell composition shifts).
2. Tally how many downstream functional links transferred (exactly,
   alternatively, or directionally).
3. If the count is **zero** — every downstream functional claim is
   either absent or contradictory — the score is **Low**, even if all
   upstream regulatory links hold with strong correlations.
4. Record this reasoning explicitly in the Final Conclusion of
   `brainstorm_final.txt`: *"Upstream-Only Transfer Rule applied:
   regulator-target links (X, Y, Z) transfer, but downstream
   functional claims (A, B, C) all fail. Score: Low."*

**Distinction from "Alternative transfer":**
- Alternative transfer = same axis, different specific targets in the
  *downstream* chain (still a downstream finding).
- Upstream-only = ONLY the regulator-target wiring is preserved; the
  downstream consequences absent.
The first is supportive; the second is not.

---

### ⚠️ Context-Specific Claims: Transfer in the Relevant Condition Is Transfer

When the paper's mechanism is explicitly about a specific condition (e.g.,
"this axis operates in the tumor microenvironment"), the within-condition
result is the PRIMARY assessment — not the overall.

If the within-condition correlation is strong (e.g., r = 0.65 in tumor)
but the p-value is not significant due to small sample size (e.g., n = 5
tumor samples), this is **strong directional transfer**, not "partial
transfer." An underpowered p-value from a small-n condition is an expected
dataset limitation, not evidence against the claim. Do not downgrade a
strong within-condition effect size to "partial" because p > 0.05.

The assessment should reflect the effect size and direction in the
relevant condition. Acknowledge the sample-size limitation as a caveat,
but do not let it change the transfer verdict.

---

### ⚠️ Assess Each Claim Independently — Do Not Conflate Separate Tests

Each testable claim from the paper should receive its own transfer
assessment based solely on the evidence for THAT specific claim. Do not
let the failure of one claim drag down the assessment of a different
claim, even when they involve overlapping cell types or related biology.

Example of the error: The paper claims (a) "Subtype-A cells are
Marker-X-high and Subtype-B cells are Marker-X-low" and (b) "Subtype-B
cells are reprogrammed into Subtype-A cells in tumors." If the marker
hierarchy is perfectly confirmed but compositional evidence for active
reprogramming is absent, assess them separately:
- Claim (a): Yes — marker hierarchy confirmed.
- Claim (b): No — no compositional evidence for reprogramming.

Do NOT merge them into a single "Partial transfer" verdict. Each claim
stands on its own evidence.

---

### ⚠️ DE With Very Small Sample Sizes (n ≤ 5 per group) Is Uninformative, Not Negative

Differential expression analysis with n ≤ 5 samples per group (after
median-split) has near-zero statistical power. Finding 0 significant
genes at FDR < 0.05 is the **expected baseline** at this sample size,
not evidence against a claim.

When DE produces no significant results at very small n:
- Do NOT cite the DE failure as evidence against the claim.
- Do NOT use "0 significant DE genes" to downgrade a transfer verdict.
- Instead, note the DE as **uninformative due to sample size** and
  rely on the correlation effect sizes for assessment.
- If correlations are strong in the expected direction, the claim is
  supported regardless of DE results.

DE results at small n are only informative if they DO show significant
genes — that would be a strong positive signal overcoming low power.
Absence of significant genes at small n tells you nothing.

---

### ⚠️ Dynamic Processes (Reprogramming, Conversion, Trajectory) Cannot Be Called "Contradictory" From Static Tests

If the paper claims "Subtype-A is reprogrammed into Subtype-B," standard
scRNA-seq proportion and correlation analyses CANNOT confirm or deny this.
Static snapshots do not capture dynamic transitions.

**Do NOT call reprogramming "contradictory" based on:**
- A flat or positive %Subtype-A vs %Subtype-B correlation (could reflect
  independent recruitment, not absence of conversion)
- Stable Subtype-A proportion between conditions (precursors may be
  replenished from other sources even as some convert)
- A ligand correlating positively with %Subtype-A instead of negatively
  (the ligand may recruit Subtype-A independently of conversion)

**Instead, assess as "not testable with this analysis approach."**
Acknowledge that trajectory inference, RNA velocity, or lineage tracing
would be needed to test the conversion claim. Note what the static data
IS consistent with (e.g., "both subtypes are tumor-enriched and coexist,
but the data cannot distinguish co-recruitment from active conversion").

**Separate the testable components from the untestable claim:**
- Signaling axis (e.g., Ligand-X on cell type A vs Receptor-Y on
  cell type B) → testable, assess normally
- Subtype characterization (e.g., Marker-A higher in Subtype-A than
  Subtype-B) → testable, assess normally
- The conversion itself → not testable, do not assess as positive,
  negative, or contradictory

**Do NOT reinterpret characterization results as evidence for
conversion/origin claims.** When plan2 labels a piece as
"characterization only, not evidence of conversion," respect that
framing. An anti-correlation between two subtype markers (or an
inverse proportion relationship) is a characterization finding —
it shows the subtypes are distinct. Do not call it "consistent with
the precursor model," "supports the replacement model," or "exact
transfer of the origin claim." Use neutral characterization language:
"distinct expression profiles," "inversely proportioned subtypes,"
etc. The origin/conversion claim itself stays NOT TESTABLE.

---

### ⚠️ Convergent Directional Signals Upgrade to Transfer

When 3+ independent measurements of the same claim ALL show expected-
direction correlations in the relevant condition, upgrade the assessment
from "directional" to **transfer (exact or alternative)**, even if no
single measurement reaches p < 0.05.

Example: Ligand-X (cell-type A) vs Receptor-Y (cell-type B) tested
three ways — subtype-specific r = 0.77, second subtype r = 0.51, broad
compartment r = 0.58, all positive in the relevant condition. No
individual test is significant at n = 5. But three independent
measurements all trending in the same direction provides strong
evidence. This is **transfer**, not "directional."

The "convergent weak signals stack" execution rule (rule #5) already
states this principle. This rule makes it explicit for the transfer
assessment: convergence across multiple framings IS the evidence when
sample size prevents individual significance.

---

### ⚠️ Combined Score Represents the Claim — Do Not Downgrade for Sub-Component Variation

When the paper claims "ligands from cell-A activate receptors on cell-B,"
the combined ligand-receptor score is the primary test of that claim.
If the combined score is strong (e.g., r = 0.75 in the relevant
condition), the claim transfers.

Variation among individual sub-components (e.g., sub-axis W1-R1 stronger
than sub-axis W2-R2) is an **interesting alternative-transfer detail** to
report in Section 2 (Novel Findings), NOT a reason to downgrade the
overall claim to "partial." The paper claims the axis exists; the
combined score confirms it; which specific arm drives it is a secondary
observation.

---

### ⚠️ Co-Enrichment Is the Claim — Not Within-Condition Dose-Response

When the paper claims "cell-type A and cell-type B co-occur in tumors,"
the test is whether both cell types are enriched in the same condition
and co-correlate at the dataset level.

If both cell types are significantly enriched in tumor (e.g., p < 0.05)
and their proportions co-correlate overall (e.g., r = 0.80), the
co-enrichment claim **transfers exactly**.

A flat or negative within-condition correlation (e.g., r = -0.20 within
tumor) means they don't dose-respond *within* tumor — but that is a
finer claim the paper typically does not make. Do NOT split the verdict
into "exact (overall), absent (within-tumor)." If the co-enrichment is
the paper's claim, assess it as a single verdict based on the overall
co-occurrence pattern.

Report the within-tumor flat relationship as a nuance or in Section 2
(Novel Findings), not as a failure of the primary claim.

### Co-enrichment vs co-localization / structural formation

When the paper's claim goes beyond co-enrichment and describes cells
physically co-localizing, forming a structure together, or creating a
barrier (e.g., "A and B form a structure that surrounds C", "A and B
co-localize in the tumor region", "A and B create a niche"), the
proportion correlation only tests co-abundance, not spatial proximity.
Structure the assessment as:

1. Co-enriched in the relevant condition: [Yes/No]
2. Co-localized / forming a structure: not testable from dissociated
   scRNA-seq
3. Overall transfer: based on co-enrichment evidence, noting the
   spatial component cannot be assessed

Do not interpret a weak within-condition proportion correlation as
"driven by condition separation."

---

### ⚠️ Consistently Positive Direction at Small n = Supportive, Not "Weak Directional"

When ALL tested readouts of a claim trend positive in the relevant
condition (e.g., score_A r = 0.15, score_B r = 0.42, score_C r = 0.40 — all
positive in the relevant condition) and NONE is contradicted, and sample size (n ≤ 5)
makes significance impossible, the convergent positive direction is
**supportive evidence for transfer**.

Do not label this "weak directional" as if the evidence is equivocal.
The absence of significance is a dataset limitation, not a biological
finding. The proper framing is: "consistently positive across all
readouts; underpowered but not contradicted; supportive of the claim."

This is especially true when the claim is about a downstream functional
output (e.g., "ligands stimulate ECM production") where multiple
independent readouts all point the same way.

---

### ⚠️ Do Not Fabricate Claims the Paper Did Not Make

Only assess transfer for claims the paper **actually** states. Do not
invent stronger versions of claims and then penalize them for failing.

Common mistake: The paper says "cell-type A shows high expression of
Gene X." The agent interprets this as "Gene X is specific/unique to
cell-type A," tests specificity across subtypes, finds Gene X is broadly
expressed, and lists "Gene X specificity to cell-type A: absent" under
"What Does NOT Transfer."

This is wrong. "High expression" ≠ "specific/unique expression." The
paper's claim is that cell-type A expresses Gene X at a high level, not
that no other cell type does. Testing specificity is a valid Extra Test
and the result (broadly expressed) is an interesting Novel Finding for
Section 2. But it must NOT appear under "What Does NOT Transfer" —
that section is reserved for claims the paper actually made that failed.

**Rule**: Before listing something under "What Does NOT Transfer," verify
it corresponds to an actual claim in `summary.txt`. If it is an
observation from an Extra Test or a derived inference, it belongs in
Section 2 (Novel/Interesting Findings) only. Do NOT list the same
finding in BOTH "What Does NOT Transfer" and Section 2 — pick one.
If it's not a paper claim, it goes in Section 2 only.

Similarly, "high expression" ≠ "differential expression between
subtypes." The paper saying "cell-type A shows high ligand activity for
Gene X" does NOT claim Gene X is differentially expressed between
cell-type A and cell-type B. Testing differential expression between
subtypes is a valid Extra Test, but failure of that test must NOT appear
under "What Does NOT Transfer."

---

### ⚠️ Claims That Are NOT TESTABLE by Design Should Not Downgrade the Score

Some claims in the paper require data modalities that the scRNA-seq
dataset cannot provide: spatial co-localization, physical barrier
formation, survival outcomes, protein-level quantification, treatment
response. These are already categorized as NOT TESTABLE in plan0.txt
Section 3.

When these claims cannot be confirmed, it is a **dataset limitation**,
not a **mechanism failure**. Do NOT use the absence of confirmation for
inherently untestable claims to downgrade the transferability score.

Example: The paper claims certain cell populations "form a physical
barrier that excludes immune cells." The physical barrier and spatial
exclusion are spatial claims — untestable with dissociated scRNA-seq.
Testing immune cell proportions is a rough proxy at best. If the proxy
test is flat, this does NOT mean the exclusion mechanism fails — it
means the dataset cannot test it. Report it as "not testable in this
dataset" rather than "absent" or "does not transfer."

**Rule**: When scoring, only count claims that ARE testable with the
available data. Untestable claims are omitted from the scoring calculus
entirely. A claim that cannot be tested is neither evidence for nor
against transfer.

---

**Never use numeric scores** anywhere in the output (no "7/10", no "4/10").
Use only High / Middle-High / Middle-Low / Low.

**The acid test for scoring:** *"Would a researcher prioritize this
mechanism over random gene exploration based on this evidence?"*
- Yes, confidently → High.
- Yes, with specific directions but some gaps → Middle-High.
- Maybe, but with major caveats or thin evidence → Middle-Low.
- No, the original logic does not productively apply here → Low.
