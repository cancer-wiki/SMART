# brainstorm_final.txt Output Template

This is the literal template the agent fills in to produce
`Working/brainstorm_final.txt` at the end of Phase 2. Replace bracketed
placeholders with actual content; keep the section headers and dividers
exactly as shown.

---

```
=================================================================
DISCOVERY TRANSFERABILITY ANALYSIS
=================================================================

Dataset: [disease name]
Original Discovery: [1–2 sentence summary from Outputs/summary.txt]
Transferability Score: [High / Middle-High / Middle-Low / Low]
Transfer Type: [exact / alternative / directional / mixed]

[OPTIONAL — include this paragraph only if the plan2.txt header shows
multiple samples per patient (see report-brainstorm.md execution rule #6).
Substitute the actual counts and sample-column name; otherwise omit
this entire block including the surrounding blank lines.]

Note on analysis granularity: this dataset has [N_patients] patients and
[N_samples] samples (one row per `[sample_column_name]`, multiple samples
per patient). All statistical results in this report are computed at the
**sample level**, treating each sample as an independent observation.
This is appropriate for exploratory transferability analysis aimed at
surfacing useful leads, but is not a rigorous patient-level inference —
within-patient sample correlations are not modelled. Effect sizes and
directions remain informative; p-values and confidence intervals should
be read as exploratory.

=================================================================
SECTION 1: ESSENTIAL VALIDATION RESULTS
=================================================================
Description: Core checks that directly test the paper's mechanistic chain.
These are the unavoidable steps to assess whether the discovery transfers.

The mechanistic chain tested:
[Write out the chain from the paper, e.g., A → B → C → D]

[For each essential finding, repeat this block.
Note: When the paper describes multiple ligands/receptors as ONE combined
signaling axis, merge the corresponding steps into a single link block
below. Report which sub-axis dominates and assess transfer at the
combined level.]

Step [X]: [Step name from plan2.txt]
Observation:
  - Overall: r = [..], p = [..], n = [..]
  - Condition 1 ([name]): r = [..], p = [..]
  - Condition 2 ([name]): r = [..], p = [..]
  - [Other key numbers from the plot or stat file]
Interpretation: [What this means for the paper's mechanistic chain]
Transfer for this link: [exact / alternative / directional / absent / contradictory]
Supporting Files:
  - plots/[filename]
  - results/[filename]    (if a stat file exists for this step)

[End of repeated block]

Section 1 Summary: [3–5 sentences synthesising which links hold,
which don't, and in which conditions]

All analysis plots are available in Outputs/plots/ for detailed exploration.

=================================================================
SECTION 2: NOVEL/CONTRADICTORY/INTERESTING FINDINGS
=================================================================
Description: Unexpected observations, contradictions with the paper,
or interesting patterns specific to this dataset that suggest new
research directions.

[For each interesting finding, repeat this block:]

Finding [X]: [Brief title]
Observation: [What you noticed; specific numbers]
Why It Matters: [Significance — alternative mechanism? condition-specific
effect? new direction?]
Supporting Files:
  - plots/[filename]
  - results/[filename]    (if applicable)

[End of repeated block]

Section 2 Summary: [2–4 sentences synthesising the novel findings]

=================================================================
FINAL CONCLUSION
=================================================================

Transferability Assessment: [High / Middle-High / Middle-Low / Low]
Transfer Type: [exact / alternative / directional / mixed]

What Transfers:
- [Specific links or themes that hold, with their numbers]

What Does NOT Transfer:
- [Specific links that are absent or contradicted]

What Transfers Alternatively:
- [Links where the direction holds but through different specific targets]

Condition-Specific Summary:
- [Condition 1]: [brief assessment of which links hold here]
- [Condition 2]: [brief assessment]

[OPTIONAL — include this block ONLY if the Upstream-Only Transfer Rule
was applied to drive the score to Low. See report-brainstorm.md
execution rule #2 and interpretation-rules.md → "Upstream-Only Transfer
Rule" for the trigger condition. If the rule does not apply, omit this
entire block.]

Upstream-Only Transfer Rule applied:
- Upstream regulatory links that DO transfer:
  - [link 1: regulator → target, with numbers]
  - [link 2: regulator → target, with numbers]
- Downstream functional claims that FAIL or CONTRADICT:
  - [phenotype / pathway output 1, with numbers]
  - [phenotype / pathway output 2, with numbers]
  - [phenotype / pathway output 3, with numbers]
- Conclusion: only generic regulator-target wiring is preserved; the
  paper's novel mechanistic claim does not transfer to this dataset.
  Score is Low per the Upstream-Only Transfer Rule, despite the
  upstream conservation.

Reasons Supporting This Score:
1. [Reason 1 — reference specific results]
2. [Reason 2 — reference specific results]
3. [Reason 3 — reference specific results]

Key Takeaways:
- [Main takeaway 1]
- [Main takeaway 2]
- [Main takeaway 3]

Recommendations:
[What should be done next? Which specific leads are worth following up?
Which condition should be prioritized? What alternative targets should
be explored?]

=================================================================
```

---

## report_brainstorm.txt block format (Phase 1)

For each step in plan2.txt, append this block to `Working/report_brainstorm.txt`
*before* moving to the next step:

```
=================================================================
STEP [X]: [Step name from plan2.txt]
=================================================================

Observations:
- [Statistics — exact numbers, including per-condition where applicable]
- [Visual trends from the plot]
- [Notable outliers, sample size considerations]

Interpretation:
- [What this means for the paper's discovery]
- [Does this link in the chain hold? In which conditions?]
- [Caveats]

Transfer Assessment for this step:
- Type: [exact / alternative / directional / absent / contradictory]
- Brief justification

Supporting Files:
- plots/[filename]
- results/[filename]   (if any)

=================================================================
```

## DE direction record (write once at the top of report_brainstorm.txt)

If the analysis included any DE step, the very first thing the agent writes
to `report_brainstorm.txt` is the direction record. Reuse the verified mapping for
every DE result thereafter — do not re-verify per step.
Same for the Enrichment analysis. The first thing to verify is for the enrichment result, what condition it associate with. 

```
=================================================================
DE DIRECTION RECORD
=================================================================
DE call from plan2.txt: condition1 = "[X]_high", condition2 = "[X]_low"
Verification gene: [gene]
  - Independent result (boxplot/correlation): [gene] is [higher/lower]
    in [X_high / X_low]
  - DE table avg_logFC for [gene]: [value] (sign: [positive/negative])
CONCLUSION: positive avg_logFC means up in [X_high / X_low]

[If the conclusion is "up in condition2 (X_low)", this means the
direction is FLIPPED relative to the typed condition1/condition2 order.
All subsequent DE-based interpretations must apply this mapping —
genes the table calls POSITIVE logFC are up in condition2.]
=================================================================
```
