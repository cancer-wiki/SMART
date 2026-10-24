# Report Revision Checklist

Detailed rules for each check category. The agent reads this file
before starting the revision process.

---

## Most Common Errors (check these FIRST)

### Error 1: Missing entity from a multi-entity claim

**This is the single most common mistake in reports.** When the
summary names multiple entities in the same claim (e.g., "from A or
B", "secreted by X and Y", "binds receptor R1, R2, and R3"), the
report often includes results for some entities but silently drops
others. The dropped entity usually has a null or absent result — but
a null result is still a finding. Omitting it hides information the
reader needs.

**How to check:** For every sentence in `Outputs/summary.txt` that
names 2+ entities, verify that ALL of them have results somewhere in
Section 3 or Section 4. Do not assume that finding entity A's result
covers entity B. Check each one independently.

**How to fix:** Find the missing entity's result in
`brainstorm_final.txt` and add it to the **same tab** as the other
entity from the same claim. If the result is null (e.g., r = 0.03,
no trend), report it explicitly — "Entity B showed no significant
relationship (r = 0.03), suggesting entity A is the primary driver
in this dataset" or similar.

**"NOT TESTABLE" does not mean "no result."** If the brainstorm
reports a statistic for an entity (r, p, proportion) but labels the
broader claim as "NOT TESTABLE," the statistic still exists and must
be reported. "NOT TESTABLE" means the claim cannot be definitively
proven; it does NOT mean no test was run.

### Error 2: Downstream summary figure without upstream evidence

When a tab's figure shows a downstream summary analysis (e.g., GO
enrichment) and that summary derives from very few significant
inputs (≤5 significant genes), the figure alone is misleading — the
reader cannot judge the actual evidence. Add the upstream analysis
plot (e.g., the volcano plot showing the DE genes) alongside it, or
swap the figure entirely. Check the Result text or brainstorm for
the count of significant genes feeding the enrichment.

---

## Summary Table Checks (Section 2)

### Number accuracy
For each row in the kable summary table:

1. Extract every numeric value from the Comment column (r = X, p = X,
   logFC = X, percentages, fold changes).
2. Check `Outputs/results/` for a stat file with the exact value.
   Stat files are the highest-priority source of truth.
3. If no stat file value is found, search `brainstorm_final.txt` for
   the corresponding claim and its statistics.
4. If the brainstorm value uses `~` (estimated) and no exact value
   was found in a stat file, remove the number entirely — do not
   keep `~`.
5. If the Rmd value differs from the source (rounded, truncated, or
   wrong), correct it using the highest-priority source available
   (stat file > brainstorm).
6. Log every correction.

### Transfer label accuracy
For each row, verify the "Transfers?" value:

| Brainstorm says | Table should say |
|----------------|-----------------|
| exact | Yes |
| alternative | Yes |
| directional (convergent or n≤5) | Yes |
| directional (single weak measurement) | Partial |
| condition-dependent (one condition works) | Yes (note condition in Comment) |
| absent | No |
| contradictory | No |
| not testable | No (note limitation in Comment) |

If the label doesn't match, correct it and log.

### Claim validity
- Every "Original Discovery" cell must map to a statement in
  `Outputs/summary.txt`.
- Flag any row that describes something the paper didn't claim.
- Check for "only", "all", "none" — verify completeness against
  what was actually tested in `plan2.txt`.

---

## Figure Selection (Section 3 and Section 4)

Two rules, checked for every tab.

### Rule 1: Comparative findings need parallel figures
If the finding compares two entities (stronger for X than Y), the
tab MUST show the same test for each entity with the same baseline
axis. If only one is shown, add the parallel figure. A null or
weak result on one side IS the point — do NOT omit it because it
is "uninformative." The contrast is what makes the comparison.

**Quality check (REQUIRED — 4 steps, each written to log):**
Q1. Read both plots, write within-condition r values to log.
Q2. For each r, write: `|r| = X → PASS or FAIL (< 0.15)`.
Q3. If ANY FAIL → Q3 is UNCONDITIONAL. Do NOT write "expected"
or "appropriate." A FAIL always triggers Q3. Read the tab text,
list ALL baseline variables mentioned (they are interchangeable
— swap the baseline, keep the comparison entities). Write which
baselines to try.
Q4. Read alternative baseline plots from Outputs/plots/, write
their within-condition r values, select the most consistent pair
and swap. Do NOT override with judgment about which baseline is
"more direct" — condition-driven plots are misleading regardless.

### Rule 2: Show the most direct evidence
If the tab shows a downstream summary (e.g., enrichment) as its
figure and it derives from ≤3 significant inputs, swap for the
upstream analysis (e.g., volcano) or add it alongside.

### Logging
For each tab, write one line:
`[Section] | [Tab] | Figure check: [Rule 1] [Rule 2] | Verdict: [OK / fixed: (what changed)]`

---

## Section 3 Tab Checks (Core Validation Results)

### Number accuracy
For each tab's Result bullet:

1. Extract every numeric value.
2. Locate the corresponding plot in `Outputs/plots/`.
3. Use the Read tool to open the plot. Read the exact values from
   the plot annotations (title, subtitle, p-value text, correlation
   text).
4. If a stat file exists in `Outputs/results/` for this piece,
   cross-check against it.
5. If the Rmd value differs from the plot/stat file, correct it.
6. If a value uses `~` and the exact value is on the plot or in a
   stat file, replace with the exact value.
7. If a value uses `~` and no exact source exists, remove the number.

### Plot-claim alignment
For each inline plot (knitr::include_graphics):

1. Use the Read tool to open the plot PDF.
2. Verify the plot content matches the claim:
   - Correct cell types shown?
   - Correct gene/score measured?
   - Correct comparison (conditions, groups)?
3. If the plot doesn't match the claim, search `Outputs/plots/` for
   the correct plot and swap the path.
4. Log every swap with reason.

### Cross-check claims against plots
For each claim in the Result text:

1. Identify the corresponding plot in `Outputs/plots/`.
2. Use the Read tool to open the plot and verify the claim matches
   the plot content (correct numbers, correct cell types, correct
   direction).
3. Correct any mismatches between the text and the actual plot.

**Key rule: every claim in the report text must be verified against
its source plot.** Do NOT assume text is correct without checking.

### Content completeness against summary
For each Section 3 tab, cross-check against `Outputs/summary.txt`.
If the summary mentions multiple cell types or genes in a single
claim (e.g., "from A or B", "binds receptor X and Y"), verify that
ALL of them appear in the report tab's Result text. If the report
only discusses A but the summary also mentions B, find B's result in
`brainstorm_final.txt` and add it to the Result text.

### Superlative claims
Replace superlatives ("strongest", "weakest", "highest", "lowest",
"best", "worst") with softer language ("very strong", "relatively
weak", "among the highest", etc.). Do not keep the superlative and
add context — change the word itself. For "only", "all", "none" —
check against `plan2.txt` to verify what was actually tested and add
scope if needed.

---

## Section 4 Tab Checks (Novel/Contradictory)

Same rules as Section 3 except content completeness against summary:
- Number accuracy against plots and stat files
- Plot-claim alignment verified by reading actual plots
- Cross-check claims against plots
- Superlative claims

---

## Plots Note and Inline Plot Verification

### Plots note
Ensure the report has a note stating: "All analysis plots are
available in Outputs/plots/ for detailed exploration."

### Inline plot file existence
Every plot path used in knitr::include_graphics must point to an
actual file. Cross-check against the file listing from Step 0. If a
path doesn't exist, log it and remove the broken reference.

---

## Revision Log Format

```
=== REPORT REVISION LOG ===
Date: [auto]
Input: Outputs/final_report.Rmd
Output: Outputs/final_report_revised.Rmd

--- CHANGES ---

[Section] | [Location] | [Issue] | [Fix]
[Section] | [Location] | [Issue] | [Fix]
...

=== REVISION SUMMARY ===
Numbers corrected: X
Fraction counts corrected: X
Plots swapped: X
Figure selection fixes: X
Text additions: X
Other fixes: X
Total changes: X
```
