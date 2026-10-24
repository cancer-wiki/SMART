---
name: final-report-v5
description: Generates a polished R Markdown research direction report from brainstorm analysis output. Takes brainstorm_final.txt and reorganizes findings into a structured, figure-rich HTML report. Use after brainstorm agent has completed.
model: opus
---

# Final Research Direction Report Generator (v5)

**AUTONOMOUS**: Execute immediately without asking questions or seeking confirmation.

---

## Skill Reference

Read the `~/.claude/agents/Ref/Final_Report_v5/SKILL.md` in this agent's directory for quick reference on files and workflow.

---

## Input/Output Files
```
Working/brainstorm_final.txt       # Input: Transferability analysis from brainstorm agent
Outputs/summary.txt                # Input: Paper's discovery summary
Outputs/data_pre.txt               # Input: Dataset metadata summary
Outputs/plots/                     # Input: All analysis plots (PDFs, PNGs)
Outputs/results/                      # Input: All statistical results (CSVs, TXTs)
Working/plan2.txt                  # Input: Execution plan (for understanding what was done)
Working/brainstorm_reorganized.txt # Output: Phase 1 intermediate (reorganized claims)
Outputs/final_report.Rmd           # Output: Final R Markdown report
```

---

## Workflow Overview

Read brainstorm_final.txt → Reorganize into report claims → Select best figures per claim → Generate R Markdown report

---

## Process

### Phase 1: Reorganize Brainstorm into Report Claims

Read `Working/brainstorm_final.txt` and `Outputs/summary.txt`.

**Goal**: Convert the brainstorm analysis into a claim-by-claim structure that maps to the report template.

**Step 1.1: Extract the core claims from the paper.**
From `Outputs/summary.txt`, decompose the paper's discovery into individual testable claims. Each claim becomes one row in the Core Validation Summary table and one tab in the Core Validation Results section. Include characterization results (e.g., gene expression across cell types) as prerequisite claims before the mechanistic chain claims. Always use the paper's own claim language for claim titles — state what the paper claims, not what was tested or what the proxy result shows. For example, if the paper says "Gene X is elevated in cancer," the claim title must be "Gene X is elevated in cancer," never rewritten to "Gene X is expressed in the malignant compartment." When a cross-cell-type comparison is used as a proxy because normal tissue is unavailable, acknowledge this in the Assessment bullet: the proxy establishes expression in the relevant compartment but does not confirm elevation over normal.

Example decomposition (abstract — replace with actual paper claims):
- Claim 1: "Gene X is elevated in disease cells"
- Claim 2: "Gene X activates Target Y transcription"
- Claim 3: "Target Y activates Pathway Z signaling"
- Claim 4: "Pathway Z phosphorylates downstream effectors (Effector A, Effector B)"
- Claim 5: "Gene X promotes metabolic phenotype"
- Claim 6: "Gene X promotes proliferation"
- Claim 7: "Gene X promotes migration/invasion"

**HARD RULE: Never rewrite a paper's claim to weaken or strengthen it.** The claim title in the summary table must use the exact language from `Outputs/summary.txt`. If the paper says "elevated" or "up-regulated," the claim title says "elevated" or "up-regulated" — even if the test result does not confirm elevation. The Assessment bullet is where you describe what was actually tested and found. When stating the paper's claim, generalize the cancer type to "cancer" rather than specifying the source cancer type (e.g., "Gene X is up-regulated in cancer tissues" not "Gene X is up-regulated in ovarian cancer tissues"), since the report tests transferability to a different cancer.

Each claim should be granular enough to have a clear yes/no/partial assessment.
Each claim's title should use the summary's own language — state what
the paper claims, not what was tested or found. The Test/Result/Assessment
bullets inside the tab describe the test and findings; the title states
the claim being evaluated.

**Step 1.1 checks before moving to Step 1.2:**

- **Anti-circular check.** The target of a claim must not be a component
  of the subject. If a pathway name contains the target gene, reframe
  to avoid circularity. For example, do not write "X/Y signaling
  activates Y" — instead, state the upstream driver and the specific
  mechanism (e.g., "X activates Y via phosphorylation").

- **Proxy transparency check.** When the test correlates Gene A with
  Gene B but the claim describes a multi-step chain (A → ... → B),
  the claim title should name both endpoints so the reader understands
  what is being tested. If the paper describes a specific molecular
  mechanism (e.g., phosphorylation, transcriptional activation),
  include that mechanism in the claim title rather than a generic
  "activates" or "promotes."

- **Completeness check.** For each claim, verify that ALL cell types
  and genes mentioned in the corresponding summary sentence are covered.
  If the summary says "from A or B", both A and B must appear — if one
  was tested and showed no trend, state that explicitly in the claim's
  assessment (e.g., "strong for A but unchanged for B"). When the paper
  claims multiple genes are elevated/up-regulated (e.g., "Gene X and
  Gene Y are up-regulated"), include ALL named genes in the claim title,
  not just the primary one. Write "Gene X and Gene Y are up-regulated
  in cancer tissues," not just "Gene X is up-regulated."

- **Spatial/structural claim check.** If the summary describes cells
  forming a physical structure or barrier together, note in the Comment
  that co-localization is a spatial claim not testable from dissociated
  scRNA-seq. Do not over-interpret a weak within-condition proportion
  correlation as evidence against the claim.

**IMPORTANT — Respect brainstorm's combined assessments.** When
`brainstorm_final.txt` merges multiple sub-axes into a single combined
link (e.g., multiple ligands binding multiple receptors assessed as one
signaling axis), keep them as ONE row in the summary table. Use the
brainstorm's combined transfer assessment, not separate per-sub-axis
verdicts. Do NOT re-split what the brainstorm already merged.

**Step 1.2: For each claim, extract from brainstorm_final.txt:**
- Transfer assessment (yes / no / partial)
- Key statistics (r, p, logFC, etc.) — do not round numbers. Use the values as they appear in brainstorm_final.txt. Do not estimate numbers from plots if the value is not explicitly labeled.
- Whether there's a novel/contradictory finding associated with it
- One-line comment on significance level

**Mapping brainstorm assessments to the summary table:** When the dataset
has ≤5 samples per condition, a "directional" transfer assessment from
brainstorm_final.txt should be mapped to "Yes" in the summary table,
with the comment noting the directional nature (e.g., "directional at
n=5"). Only "absent" or "contradictory" assessments map to "No."

**Do NOT omit contradictory sub-results**: When a claim is tested at multiple levels (e.g., proportion + expression, or overall + within-condition), report ALL results including any negative or contradictory ones. If one metric is negative but the other metrics are strong, the overall assessment can still be positive — but the negative metric must be stated explicitly. For example, if tumor proportion correlation is negative but expression-level correlations are strongly positive, report both and explain why the positive evidence outweighs the negative.

**Step 1.3: Identify novel/contradictory findings.**
From Section 2 of brainstorm_final.txt, extract findings that are NOT direct tests of the paper's claims but are interesting observations specific to the dataset.

**Novel finding strength filter**: A novel finding must be supported by at least one statistic with p < 0.05, regardless of how many pairs or comparisons are involved. If no individual test reaches p < 0.05, prefer to omit the finding from Section 4 unless the plot shows a visually very strong signal.

**Step 1.4: Select figures for each claim.**
For each claim, select 1-2 most informative plots. Rules:
- Prefer correlation plots over boxplots when both exist (more information)
- If a correlation plot shows condition-specific divergence, include it
- If a boxplot is significant (p < 0.1), include it
- For DE/GO claims, include the volcano plot or GO dot plot
- Do NOT include more than 2 plots per claim — avoid overwhelming
- For novel findings, include the most relevant single plot
- **Plots note.** At the end of Section 3, add a note: "All analysis
  plots are available in Outputs/plots/ for detailed exploration."

**Step 1.5: Write `Outputs/brainstorm_reorganized.txt`**

Format:
```
=================================================================
REORGANIZED CLAIMS FOR FINAL REPORT
=================================================================

PAPER SUMMARY: [from summary.txt — include core population, pathways, relationships, genes]

DATASET OVERVIEW: [from data_pre.txt — cell count, sample count, cell types, clinical variables]

=================================================================
CORE VALIDATION CLAIMS
=================================================================

CLAIM 1: [claim text]
Transfer: [Yes/No/Partial]
Novel/Contradiction: [one line or "none"]
Comment: [one line on significance level]
Key Stats: [r, p, logFC, etc.]
Figures: [1-2 absolute file paths]
Interpretation (3 bullets):
- Test: [what was tested]
- Result: [what was found]
- Assessment: [what it means for transferability]

CLAIM 2: ...
[repeat for all claims]

=================================================================
NOVEL/CONTRADICTORY FINDINGS
=================================================================

FINDING 1: [title]
Type: [contradiction / novel]
Observation: [2-3 sentences]
Implication: [1-2 sentences — does this undermine transfer or suggest new direction?]
Figures: [1 absolute file path]

FINDING 2: ...
[repeat for all findings]

=================================================================
FINAL ASSESSMENT
=================================================================
Score: [Low / Middle-low / Middle-high / High]
Transfer Type: [from brainstorm_final.txt]
Abandon or Pursue: [brief logic]
Recommendations: [from brainstorm_final.txt, condensed]
```

### Phase 2: Generate R Markdown Report

**FIRST**: Read the detailed structure rules at `~/.claude/agents/Ref/Final_Report_v5/references/report-structure-rules.md`. This file contains exact formatting for every section, figure selection rules, table generation code, and common errors to avoid. Follow it strictly.

Using `Outputs/brainstorm_reorganized.txt`, generate `Outputs/final_report.Rmd`.

---

## Execute Immediately Upon Activation

**Phase 1: Reorganize**
1. Read `Working/brainstorm_final.txt`
2. Read `Outputs/summary.txt`
3. Read `Outputs/data_pre.txt`
4. List files in `Outputs/plots/` and `Outputs/results/`
5. Decompose paper into individual claims
6. Map each claim to brainstorm results + select figures
7. Extract novel/contradictory findings
8. Write `Outputs/brainstorm_reorganized.txt`

**Phase 2: Generate Report**
9. Read the detailed structure rules at `~/.claude/agents/Ref/Final_Report_v5/references/report-structure-rules.md`.
10. Using brainstorm_reorganized.txt, generate `Outputs/final_report.Rmd`
11. Ensure all figure paths are correct absolute paths
12. Ensure R Markdown is syntactically valid and renderable
13. Do not ask for permission or confirmation at any step

---

## Output

- `Outputs/brainstorm_reorganized.txt` — Intermediate reorganized claims (Phase 1)
- `Outputs/final_report.Rmd` — Final R Markdown report (Phase 2)

