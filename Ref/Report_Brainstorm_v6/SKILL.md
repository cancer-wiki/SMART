# Report Brainstorm Skill — Quick Reference

## Purpose
Interpret computational results from a multi-step validation plan and produce
a comprehensive report assessing whether a paper's discovery transfers to
the user's dataset.

**Core philosophy:** we are looking for useful leads in a new cancer type, not
exact molecular replication. *Alternative transfer* (same broad axis,
different specific targets) is a positive and expected finding when comparing
across cancer types.

## Files

| Type | Path |
|---|---|
| Input  | `Working/plan2.txt`           — what was done (the validation plan) |
| Input  | `Outputs/summary.txt`         — paper's discovery summary |
| Input  | `Outputs/plots/`              — visual results (PDFs, PNGs) |
| Input  | `Outputs/results/`               — statistical results (CSVs, TXTs) |
| Output | `Working/report_brainstorm.txt`      — step-by-step observations (Phase 1) |
| Output | `Working/brainstorm_final.txt`— final reorganised report (Phase 2) |

## Workflow

```
Read plan2.txt + summary.txt
  ↓
Phase 1: per-step observations → report_brainstorm.txt
  ↓
Phase 2: synthesise → brainstorm_final.txt
```

## Transfer Types

| Type | Meaning | Example |
|---|---|---|
| **Exact**         | Same gene → same target → same pathway | Gene X → Target Y → Pathway Z in both cancers |
| **Alternative**   | Same gene → different target → same pathway family | Gene X → (not Target Y but) broader Pathway Z activation |
| **Directional**   | Correct direction, weaker effect | r = 0.26 in expected direction, not significant |
| **Absent**        | No relationship in either direction | r ≈ 0, flat boxplot |
| **Contradictory** | Significant relationship in the OPPOSITE direction | Paper says positive, data shows significant negative |

> **Alternative transfer is still transfer.** Different cancers wire pathways
> differently — this is expected, not a failure.

## Scoring (qualitative — never numeric)

| Score | Meaning |
|---|---|
| **High**        | The core mechanistic chain (3+ sequential links) transfers with consistent directions in the overall analysis or the dominant condition. The paper's key downstream/functional claim is confirmed (exactly or via mechanistically plausible alternative). No major contradiction on core links. A researcher would confidently pursue this mechanism. |
| **Middle-High** | Most of the chain transfers, but with one significant gap or one core link that is condition-dependent. Downstream functional output is confirmed in at least one robust condition. Minor contradictions exist but do not invalidate the central logic. A researcher would pursue this with moderate confidence. |
| **Middle-Low**  | Some links transfer but the chain is broken — either the central claim is contradicted while peripheral links survive, or transfer depends on a single small subgroup. Alternative pathway evidence exists but is thematically loose (not mechanistically plausible). A researcher might note this but would not prioritize it over other leads. |
| **Low**         | The paper's core downstream claims fail across all conditions. Either everything is absent/contradictory, or only upstream regulatory wiring survives (Upstream-Only Transfer Rule). A researcher gains no actionable leads from this paper's logic. |

### Key discriminators between adjacent tiers

**High vs Middle-High:** High requires no major contradiction on core
links AND confirmed downstream function. Middle-High tolerates one gap
or one condition-dependent core link.

**Middle-High vs Middle-Low:** The key question is whether the
**downstream functional output** survives in a robust way. Middle-High
requires at least one downstream functional claim confirmed in a
condition with adequate representation. Middle-Low means surviving
evidence is peripheral, conditional on a small subgroup, or the central
organizing claim is contradicted even though some individual links hold.

**Middle-Low vs Low:** Middle-Low requires at least one downstream
functional link showing signal (even if borderline or in one subgroup).
Low means every downstream claim fails across all conditions.

### ⚠️ Upstream-Only Transfer Rule

**If only upstream regulatory relationships transfer but ALL downstream
functional claims (the paper's novel mechanism) fail, the score is Low.
Upstream conservation alone does not constitute mechanism transfer.**

This rule overrides the "alternative transfer is still transfer" framing
when applied to upstream regulation specifically. The reason: most papers'
novel contribution is downstream — the specific mechanistic chain from a
regulator to a phenotype. If that chain fails entirely and only the
generic upstream wiring is preserved (e.g., the same transcription factor
binds the same target, but the target's downstream effects don't
replicate), the paper's actual claim has not transferred. See
`references/interpretation-rules.md` → "Scoring boundaries" for the
detailed decision tree.

### ⚠️ Alternative-Transfer Plausibility

Not all GO overlaps count as alternative transfer. Distinguish:
- **Mechanistically plausible alternative:** same biological axis,
  different effectors (e.g., ALOX5 instead of GPX4 for lipid
  peroxidation). This supports Middle-High or higher.
- **Thematically related but mechanistically unrelated:** gene correlates
  with any cancer hallmark (immune, metabolic, proliferative). These
  themes are nearly universal in cancer and should not, alone, rescue a
  score from Low to Middle-High. They can support Middle-Low at most.

**Acid test:** *"Would a researcher prioritize this mechanism over random
gene exploration based on this evidence?"*
- Yes, confidently → High.
- Yes, with specific directions but some gaps → Middle-High.
- Maybe, but with major caveats or thin evidence → Middle-Low.
- No, the original logic does not productively apply here → Low.

**Never use numeric scores (no 7/10, no 4/10).** Only High / Middle-High / Middle-Low / Low.

## DE direction — verify once, reuse

The DE analysis uses pseudobulk DE. The sign of `avg_logFC`
depends on how Libra internally orders the condition factor levels — this
may not match the `condition1` / `condition2` order in `plan2.txt`.
Getting the direction wrong reverses every DE-based interpretation, so
the mapping must be confirmed before any DE-derived claim.

Cross-check ONE gene that has an independent result in the same run — a
boxplot or correlation showing the gene is higher/lower in one condition.
Compare that gene's `avg_logFC` sign in the DE table against the boxplot
direction, and record the resulting mapping ONCE at the top of
`report_brainstorm.txt` using the DE DIRECTION RECORD block in
`references/output-template.md`. Reuse that mapping for every DE-derived
claim afterwards — do not re-verify per step.

See `references/interpretation-rules.md` → Result Type 3 for the full
verification protocol.

## Headline rules (the rest is in interpretation-rules.md)

- **Per-condition correlations are PRIMARY** — when conditions diverge, a
  link that holds in one condition IS transfer in that context. Do not
  lead with a diluted overall r.
- **Effect size and direction matter more than significance** — pseudobulk
  power is limited; r = 0.30 in the expected direction with p = 0.07 is
  supportive.
- **Convergent weak signals = strong evidence** — multiple links trending
  correctly is more meaningful than any single p-value.
- **GO terms don't need exact pathway names** — related metabolic /
  signaling / biosynthetic terms count as alternative transfer.
- **Be specific** — always cite exact r, p, n, fold changes. "Weak positive
  trend" is not enough; write `r = 0.26, p = 0.12, n = 38`.
- **Write as you go** — append each step's block to `report_brainstorm.txt` before
  reading the next step's outputs. Do not hold everything in memory.
- **File references are paths, not images** — give the path; never embed.

## ⚠️ Critical assessment rules (MUST READ — details in interpretation-rules.md)

- **Convergent signals upgrade to transfer** — when 3+ independent
  measurements of the same claim ALL trend in the expected direction in
  the relevant condition, this is **transfer**, not "directional."
- **Combined score represents the claim** — when the paper claims a
  multi-ligand/multi-receptor axis, the combined score is the primary
  test. Do NOT downgrade because individual sub-components vary in
  strength. Sub-component variation is a Novel Finding, not a failure.
- **Co-enrichment is the claim** — if two cell types are both significantly
  enriched in the same condition and co-correlate overall, the co-enrichment
  transfers. Within-condition flat correlation is a nuance, not a failure.
- **Small n positive convergence = supportive** — when ALL readouts trend
  positive and none is contradicted at n ≤ 5, this is supportive, not
  "weak directional."
- **Context-specific claims: transfer in the relevant condition IS transfer**
  — if the paper's mechanism is about tumor, and within-tumor r = 0.8
  with p = 0.1 at n = 5, this is strong transfer, not "partial."
- **DE at n ≤ 5 is uninformative, not negative** — 0 significant genes
  at very small n is the expected baseline. Do not cite DE failure as
  evidence against a claim. Rely on correlation effect sizes instead.
- **Do NOT fabricate claims the paper didn't make** — "high expression"
  ≠ "specific/unique expression." Extra Test findings go in Section 2
  (Novel Findings) only, NEVER under "What Does NOT Transfer." Before
  listing anything as non-transferring, verify it matches an actual claim
  from `summary.txt`.
- **NOT TESTABLE claims don't downgrade the score** — spatial claims,
  survival outcomes, protein-level claims are dataset limitations, not
  mechanism failures. Omit them from the scoring calculus entirely.
- **Dynamic processes are not testable** — reprogramming, conversion,
  differentiation trajectory claims cannot be confirmed or denied by
  static proportion/correlation tests. Do not call them "contradictory."
- **Characterization ≠ evidence for conversion** — when plan2 labels
  a piece as "characterization only," do NOT reinterpret the result as
  "consistent with the precursor model" or "supports the conversion
  claim." Anti-correlated subtypes are a characterization finding, not
  transfer of the origin claim. Use neutral language only.

## Two-phase process

### Phase 1 → `Working/report_brainstorm.txt`
For each step in plan2.txt, in order:
1. Locate the step's plot in `Outputs/plots/` and any stat file in `Outputs/results/`.
2. Read the plot for r / p / median direction / sample size — the numerical values shown on the plot are sufficient. Open the stat file if needed for fields the plot doesn't display (e.g., the full DE gene table).
3. Apply the right interpretation rule from `interpretation-rules.md`
   (correlation / boxplot / DE / GO / cell-type comparison).
4. Append the step's block (template in `output-template.md`) to
   `report_brainstorm.txt` before moving on.

### Phase 2 → `Working/brainstorm_final.txt`
1. Read all observations in `report_brainstorm.txt`.
2. Score High / Middle-High / Middle-Low / Low using the scoring table above.
3. Classify the transfer type (exact / alternative / directional / mixed).
4. Reorganise into Section 1 (Essential Validation) + Section 2
   (Novel / Interesting Findings) + Final Conclusion.
5. Fill in the full template from `output-template.md`.

## Reference files

| File | Use |
|---|---|
| `references/interpretation-rules.md` | Detailed per-result-type rules, condition-specific guidance, scoring boundaries, mechanistic-chain logic |
| `references/output-template.md`      | Literal templates for `report_brainstorm.txt` (per step) and `brainstorm_final.txt` (final report) |

The main agent prompt (`report-brainstorm.md`) walks through the phases
without restating the content of these references. When in doubt about
*how* to interpret a number, go to `interpretation-rules.md`. When in doubt
about *how to format* the output, go to `output-template.md`.
