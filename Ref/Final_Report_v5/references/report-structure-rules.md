# Report Structure Rules (v5)

## Goal
Detailed guidance on how to structure each section of the final R Markdown report
and how to select/present figures effectively.

---

## Section 1: Overview {.tabset}

### Tab: Original Paper Research Highlights {.tabset}

**Source**: `Outputs/summary.txt`

This tab contains two nested sub-tabs. Copy the exact text from
`Outputs/summary.txt` verbatim. Do NOT reformat, paraphrase,
bullet-point, add chain diagrams, or alter the content in any way.

Do NOT include:
- The "## Section 1:" or "## Section 2:" headers — just the content
- Any interpretation, comparison to user data, or content not in summary.txt
- Any reformatting into bullet points or prose summaries
- Any added chain diagrams or pathway arrows

#### Clinically Relevant Findings

Paste the content under "## Section 1: Clinically Relevant Findings"
from summary.txt verbatim. Do not include the section header itself,
just the numbered claims.

#### Mechanistic Claims

Paste the content under "## Section 2: Mechanism" from summary.txt
verbatim. Do not include the section header itself, just the mechanism
text.

---

### Tab: Dataset Overview

**Source**: `Outputs/data_pre.txt`

**Include**:
- Total cell count
- Number of patients/samples
- Cell types (list all, highlight those relevant to paper)
- Clinical metadata columns (actual names: e.g., "Condition", "sex", "Phase")
- Conditions (e.g., different disease subtypes or stages)

**Style**: Brief paragraph + bullet points for specifics.

---

## Section 2: Core Validation Summary (THE KEY TABLE)

This is the most important element of the report. A reader should understand
the full transferability picture from this table alone.

### Table format

```r
summary_df <- data.frame(
  `Original Discovery` = c(
    "Claim 1 text",
    "Claim 2 text",
    ...
  ),
  `Transfers?` = c("Yes", "Partial", "No"), # ONLY use Yes / No / Partial
  `Novel/Contradiction` = c(
    "No contradiction",
    "Alternative target identified",
    ...
  ),
  `Comment` = c(
    "r = 0.30, p = 0.069, consistent across conditions",
    "r = -0.044 overall but r = 0.259 in subtype A",
    ...
  ),
  check.names = FALSE
)

knitr::kable(summary_df, format = "html", escape = FALSE) %>%
  kableExtra::kable_styling(bootstrap_options = c("striped", "hover"))
```

### Rules for the table
- Each row = one granular claim from the paper
- **"Transfers?" column uses EXACTLY one of: Yes / No / Partial** — nothing else
- "Novel/Contradiction" = max one line. If nothing notable, say "No contradiction"
- "Comment" = brief stat reference using only r, p, and logFC values + one qualifier. Do not include fold changes, percentages, counts, or other numeric types in this column. Do not round numbers — use values as they appear in the brainstorm text.

### Mapping brainstorm assessments to Yes / No / Partial
The brainstorm agent uses: exact, alternative, directional, absent, contradictory.
Map them as follows:
- **exact** → Yes
- **alternative** → Yes (note the alternative detail in Comment or Novel column)
- **directional with convergent evidence or strong effect size in the relevant condition** → **Yes** (not Partial — convergent directional IS transfer)
- **directional with only a single weak measurement** → Partial
- **absent** → No
- **contradictory** → No
- **not testable** → label as "No" in the table, but add a Comment noting the dataset limitation (e.g., "spatial claim; rough proxy only"). In the internal re-evaluation step, do NOT count this "No" as a gap that downgrades the score.

**Key principle**: "Partial" means genuinely mixed evidence (e.g., one
condition supports and another contradicts, or the claim is only half-
confirmed). Do NOT use "Partial" for claims where the direction is
consistently correct but statistical power is limited — that is "Yes"
with a sample-size caveat in the Comment column.

### Filtering claims for the table
Before adding a row to the summary table, verify it belongs there:

- **Only include claims the paper actually makes.** Cross-check each
  row against `summary.txt`. If a claim is a fabricated or strengthened
  version of what the paper says (e.g., "Gene X is differentially
  expressed between Subtype-A and Subtype-B" when the paper only says
  "Subtype-A shows high expression of Gene X"), do NOT include it in
  the table. Extra Test observations belong in Section 4 (Novel
  Discoveries), not in the Core Validation Summary.
- **Claims NOT TESTABLE by design stay in the table but don't hurt
  the score.** If the paper's evidence for a claim was spatial,
  histological, survival-based, or protein-level, and dissociated
  scRNA-seq cannot replicate that test, include the row in the table
  (it's still an important part of the paper's story) and label it
  "No" — but add a Comment explaining the dataset limitation (e.g.,
  "spatial claim; proportion test is a rough proxy only"). When
  re-evaluating the score before Section 6, these "No" rows must NOT
  count as gaps that downgrade the transferability score.
- **Exclude trajectory/conversion/origin claims.** Claims about
  cell-state conversion, differentiation origin, or trajectory (e.g.,
  "cell-type A originates from cell-type B") are NOT TESTABLE from
  static scRNA-seq and should NOT appear as their own rows in the core
  summary table. If a related characterization test exists (e.g.,
  anti-correlated expression between markers of two subtypes), mention
  it in another row's Comment column — but the "origin" claim itself
  does not get its own row.
- **Use consistent denominators.** When reporting proportions across
  claims, use the same denominator that the analysis used. If the
  analysis computes cell-type proportions within the biological parent
  compartment (e.g., within T cells for CD8+ T cells, within Myeloid for
  dendritic cells), do not mix in total-cell proportions from Extra Tests.
  Consistency across the table avoids misleading comparisons.

### How to decompose claims
Break the paper's mechanism into the SMALLEST testable units:

**Wrong** (too coarse):
| "Gene X promotes disease through Target Y-Pathway Z-metabolic phenotype" | Partial | ... |

**Right** (granular):
| "Gene X elevated in disease cells" | Yes | ... |
| "Gene X activates Target Y transcription" | No | Alternative target identified | ... |
| "Gene X activates Pathway Z" | Partial | Pathway-level, not target-specific | ... |
| "Gene X promotes metabolic phenotype" | Partial | Individual effectors UP despite module score DOWN | ... |
| "Gene X promotes proliferation" | Partial | ... |
| "Gene X promotes migration/invasion" | Yes | Condition-specific | ... |

---

## Section 3: Core Validation Results {.tabset}

### Structure per tab

```markdown
## Claim Title {.tabset}

### [Claim short name]

- **Test**: [One sentence: what was tested and how]
- **Result**: [One sentence: what was found, with key stats inline (r, p, logFC)]
- **Assessment**: [One sentence: what this means for transferability]

[Figure 1]

[Figure 2 if warranted]
```

**CRITICAL**: Each tab contains EXACTLY 3 bullet points: Test, Result, Assessment. Each bullet is one sentence. No additional text, no paragraphs, no extra bullets.

**No rounding or estimation**: Do not round numbers. Use the values as they appear in brainstorm_reorganized.txt. Do not estimate numbers from plots if the value is not explicitly labeled on the plot.

**Do NOT omit contradictory sub-results in the Result bullet**: When a claim is tested at multiple levels (e.g., proportion + expression, or overall + within-condition), the Result bullet must mention ALL sub-results, including negative or contradictory ones. If within-tumor proportion correlation is negative while expression correlations are strongly positive, state the negative proportion result explicitly. The Assessment bullet can explain why the overall conclusion is still positive despite the negative sub-result — but do not hide it.

### Figure embedding

For PDF plots (always use absolute paths):
```r
knitr::include_graphics("/absolute/path/to/Outputs/plots/piece5_1_corr_GeneX_TargetY_CancerType.pdf")
```

For multiple figures side by side:
```r
knitr::include_graphics(c(
  "/absolute/path/to/Outputs/plots/piece5_1_corr_GeneX_TargetY_CancerType.pdf",
  "/absolute/path/to/Outputs/plots/piece5_1_boxplot_TargetY_by_GeneX_group.pdf"
))
```

### Figure selection rules per claim type

| Claim Type | Best Figure(s) |
|------------|----------------|
| "Gene A correlates with Gene B" | Correlation scatter plot (shows condition split) |
| "Gene A is higher in Group X" | Boxplot (shows median + p-value) |
| "Gene A activates Pathway B" | Correlation (gene vs pathway score) + boxplot if significant |
| "Pathway X is enriched" | GO dot plot |
| "Gene A affects transcriptome" | Volcano plot |
| "Gene A promotes proliferation" | Correlation (gene vs proliferation marker) |

### Choosing between available plots
- **Prefer gene-level correlations over proportion-level when
  denominators are inconsistent.** If the proportion correlation uses
  a different denominator (e.g., total cells) than the rest of the
  analysis (e.g., parent compartment), use the gene-level correlation
  as the headline figure and stat. Proportion plots with inconsistent
  denominators can be shown as supplementary but should not be the
  primary evidence.
- **When the paper groups multiple ligands/receptors as one axis,
  present the combined score as the headline.** If the paper says
  "ligands A, B, C signal to receptors X, Y, Z," use the combined
  ligand score vs combined receptor score plot as the primary figure.
  Do not lead with individual pairs. Individual pair results can be
  noted briefly in the Comment column but should not drive the
  assessment or figure selection.
- **When a claim is tested at multiple levels (e.g., proportion +
  expression, or intra-cell-type + cross-cell-type), show BOTH plots**
  side by side. Example: if a co-occurrence claim has both a proportion
  correlation plot and an expression correlation plot, include both.
  The assessment should integrate the two: if one level confirms in all
  conditions while the other shows a within-condition reversal, explain
  which level provides the stronger evidence and why the divergence at
  the other level is acceptable. Do not hide divergent results by
  showing only the favorable plot.

### What NOT to include
- Do NOT show 4+ figures per claim
- Do NOT show redundant plots (e.g., both overall and stratified correlation if stratification adds nothing)
- Do NOT include figures that show null results UNLESS the null is the main finding
### Plots note

At the end of Section 3, add a note: "All analysis plots are available
in Outputs/plots/ for detailed exploration."

---

## Section 4: Contradictions & Novel Discoveries {.tabset}

### When something is a "Contradiction"
The paper claims X, but we find the opposite or a significantly different pattern.
Example: "Paper claims metabolic phenotype is activated, but metabolic module score is
significantly LOWER in Gene X-high cells."

### When something is a "Novel Discovery"
We found something the paper didn't test or claim, specific to our dataset/cancer type.
Example: "Alternative regulatory subunit downregulation as compensatory activation mechanism."
Example: "Subtype A vs subtype B divergence in all Gene X-associated biology."

### Filtering for Section 4
Only include findings that are **genuinely informative and actionable**.
- A finding that merely confirms a gene is broadly expressed (when the
  paper never claimed specificity) is NOT a Novel Discovery — it's an
  uninformative Extra Test result. Do not include it.
- A Novel Discovery should change the researcher's understanding or
  suggest a concrete new direction. Ask: "Would a researcher change
  their experimental plan based on this finding?" If no, omit it.
- **Exclude results derived from trajectory/conversion/origin claims.**
  If a claim was excluded from the core summary table because it is a
  trajectory, conversion, or origin claim (not testable with static
  scRNA-seq), then any test result or "contradiction" derived from
  that claim is also excluded from Section 4. A correlation test that
  serves as a proxy for a conversion hypothesis (e.g., sample-level
  anti-correlation between two subtypes as evidence of reprogramming)
  is not a real contradiction — it is testing a claim the data cannot
  address. Do not report it in Section 4, and do not let it cascade
  into Sections 5 or 7.
- **Novel finding strength filter**: A novel finding must be supported
  by at least one statistic with p < 0.05, regardless of how many
  pairs or comparisons are involved. If no individual test reaches
  p < 0.05, prefer to omit unless the plot shows a visually very
  strong signal.

### Structure per tab
```markdown
## [Finding title]

**Type**: Contradiction / Novel Discovery

[2-3 sentences: What was found, how it differs from the paper]

[1 figure if applicable]

**Implication**: [1-2 sentences: Does this undermine translation or open new directions?]
```

---

## Section 5: Investigation on Contradictions

**Use bullet points, NOT a paragraph.** Each bullet = 1-2 sentences.

```markdown
# Investigation on Contradictions/Novel Discoveries

- **Fundamental vs. context-specific**: [Are the contradictions fundamental flaws or cancer-type-specific adaptations?]
- **Mechanistic reinterpretation**: [Do the contradictions suggest alternative wiring rather than absence of the mechanism?]
- **New opportunities**: [Do novel findings open directions the paper did not explore?]
- **Bottom line**: [Overall assessment — pursue, pursue with caveats, or abandon?]
```

**Tone**: Balanced. Not dismissive of contradictions, not alarmist either.

---

## Internal step: Re-evaluate the transferability score before writing Section 6

**This is NOT a section in the report.** Do not write it as a visible
section. Perform this re-evaluation internally, then use the adjusted
score directly in Section 6.

**Step 1: Check "What Does NOT Transfer" for illegitimate entries.**
For each item listed under "What Does NOT Transfer" in brainstorm_final.txt:
- Does it correspond to an actual claim in `summary.txt`? If it's a
  fabricated or strengthened version of a claim (e.g., "specificity"
  when the paper only said "high expression"), discard it.
- Is the original evidence for this claim spatial, histological,
  survival-based, or protein-level? If the paper proved it with a
  data modality that scRNA-seq cannot replicate, the failure is a
  dataset limitation. Do NOT count it as a gap that downgrades the score.

**Step 2: Check if "directional" claims have convergent support.**
If the brainstorm lists claims as "directional" or "weak directional,"
check whether multiple independent measurements all trend in the same
direction. Convergent directional evidence = transfer, not a gap.

**Step 3: Re-score.**
After removing illegitimate non-transferring items and upgrading
convergent directional claims, re-evaluate whether the score should
change. If the brainstorm said Middle-high but the only "gaps" were
untestable claims or fabricated specificity tests, upgrade to High.
Use the adjusted score in Section 6.

---

## Section 6: Final Conclusions

**Format**:
```markdown
# 🎯 Final Conclusions

## **🚀 Transferability Score: Low / Middle-low / Middle-high / High**
```

**CRITICAL**: Use ONLY Low / Middle-low / Middle-high / High. NEVER use numeric scores (no X/10, no 7/10, etc.). NEVER use plain "Middle" — always specify Middle-low or Middle-high.
Use the **adjusted score** from the internal re-evaluation, not the raw brainstorm score.

Scoring guidance:
- **High**: Most claims transfer, contradictions are context-specific rather than fundamental, strong novel findings reinforce the direction
- **Middle-high**: Majority of claims transfer with some gaps; contradictions exist but are context-specific; direction is clearly worth pursuing with targeted follow-up
- **Middle-low**: Some claims transfer but notable gaps remain; contradictions are significant but not fatal; direction has specific leads worth focused investigation but not full pursuit. Important: don't over-positive — if only 1 or 2 pieces transfer, use *Low* instead
- **Low**: Most claims do not transfer, fundamental contradictions undermine the axis, not worth pursuing

**Upstream-only transfer rule**: If only the first step upstream regulatory relationships 
transfer but ALL downstream functional claims (the paper's novel mechanism) 
fail, the score is Low. Upstream conservation alone does not constitute 
mechanism transfer.

That's it. No explanation after the score. The score speaks for itself, and the rest of the report provides the justification.

---

## Section 7: Strategic Research Recommendations

**All content in this section is in bullet point format.**

### Score = High: Full recommendations

Two tabs:
1. **Contradiction-Informed Studies**: 2-3 bullet points, each with a title and 1-2 lines of reasoning
2. **Further Experiment Possibility**: bullet points covering:
   - What sample types/conditions to prioritize
   - Whether protein-level validation is needed
   - What functional experiments would strengthen the case (knockout, CRISPR, etc.)
   - Whether patient outcome data should be consulted
   - Specific databases or resources to search

### Score = Middle-high or Middle-low: Conditional recommendations

Both Middle-high and Middle-low use the same recommendation format.

One tab: **Conditional Recommendations** — bullet points:
- What would need to be true for this to be worth pursuing?
- Which specific condition/subtype should be focused on?
- What 1-2 experiments would most decisively test the axis?
- Note: "Not a strong enough recommendation for full pursuit, but specific leads in [condition] warrant focused follow-up"

### Score = Low: Abandon

One tab: **Abandon Recommendation** — bullet points:
- Why this direction is not productive (1-2 bullets)
- Any salvageable leads, if any (1 bullet)

---

## R Markdown Technical Notes

### YAML frontmatter (REQUIRED — paste verbatim at top of every report)

Every generated `Outputs/final_report.Rmd` must begin with exactly this YAML block. Do not change the theme. Do not add a "Code" button.

```yaml
---
title: "[Report title]"
output:
  html_document:
    toc: true
    toc_float: true
    theme: cosmo
---
```

**Required fixed values:**
- `theme: cosmo` — the project's standard theme. Do not substitute another Bootswatch theme (e.g., flatly, lumen, journal) even if they look similar.

**Forbidden — these add a "Code" dropdown button at the top-right of the rendered HTML:**
- Do **NOT** include `code_folding: hide` in the YAML.
- Do **NOT** include `code_folding: show`.
- Do **NOT** include `code_download: true`.

  All three of these add the "Code ▾" button. Since chunks are already set to
  `echo = FALSE` in the setup chunk (see "Setup chunk" below), no code is ever
  rendered into the HTML — the button is therefore both useless and visually
  cluttering. Omit any `code_folding` / `code_download` lines entirely.

**Other forbids:**
- Do **NOT** add `df_print`, `highlight`, or other appearance-affecting fields. The defaults under `theme: cosmo` are correct.
- Do **NOT** wrap the YAML inside an R chunk or move it below other content. It must be the first lines of the file.

### Required packages
```r
library(knitr)
library(kableExtra)  # for styled tables
```

### Setup chunk
```r
knitr::opts_chunk$set(
  echo = FALSE,
  message = FALSE,
  warning = FALSE,
  fig.align = "center",
  out.width = "100%",
  out.height = "500px"
)
library(knitr)
```

### Figure sizing for PDFs
```r
# Single figure (absolute path)
knitr::include_graphics("/absolute/path/to/Outputs/plots/filename.pdf")

# Two figures side by side (use out.width = "48%")
```

### Path handling
- **Always use absolute paths** for all figure references
- The absolute path root is determined by the project location
- **Always verify paths exist** before writing them into the Rmd
- Use `list.files()` in a setup chunk to confirm all referenced files are present

---

## Common Errors

| Wrong | Right |
|-------|-------|
| 5 figures per claim | 1-2 figures max per claim |
| Paragraph prose in Section 3 | Exactly 3 bullets: Test / Result / Assessment |
| Paragraph prose in Section 5 | Bullet points (4 bullets) |
| Visible "Section 5b: Re-evaluation" in the report | Re-evaluation is internal only; adjusted score goes directly to Section 6 |
| Trajectory/origin claim as its own row in core table | Mention in another row's Comment; origin claims are NOT TESTABLE |
| Uninformative Extra Test result in Section 4 | Only include Novel Discoveries that change the researcher's plan |
| Inconsistent proportion denominators across table rows | Use the same parent compartment denominator the analysis used |
| Paragraph prose in Section 7 | Bullet points throughout |
| Numeric score (7/10) | Low / Middle-low / Middle-high / High only |
| Plain "Middle" without qualifier | Always use Middle-low or Middle-high |
| Rounded or estimated stats | Use values as-is from brainstorm text; do not estimate from plots |
| Transfer label "Alternative" or "Directional" | Only Yes / No / Partial |
| Pasting brainstorm text verbatim | Condense into bullet format |
| Missing figure path | Verify file exists before referencing |
| Relative figure paths | Use absolute paths |
| Explanation after the score | Score only in Section 6, no explanation |
| Full recommendations for Low score | Abandon with bullet points |
| Claim table rows too coarse | Decompose into granular testable claims |
| Missing {.tabset} on sections that need tabs | Include {.tabset} on Overview, Core Results, Novel Findings |
| Forgetting kableExtra for table styling | Include in library loading |
| Real paper examples in template | Use abstract placeholders (Gene X, Target Y, Pathway Z) |
| Different theme (e.g., `theme: flatly`) | Always `theme: cosmo` — fixed across all reports |
| Including `code_folding: hide` or `show` (adds "Code ▾" button) | Omit `code_folding` from YAML entirely — chunks already have `echo = FALSE` |
| Including `code_download: true` (also adds "Code" button) | Omit entirely — the button must be absent |
| Putting YAML inside an R chunk | YAML is the first lines of the file, outside any chunk |
| "Co-enrichment driven by condition separation" for weak within-tumor proportion correlation | Co-enrichment/co-localization is a spatial claim; dissociated scRNA-seq cannot capture spatial proximity — note this limitation instead |
| Dropping a cell type mentioned in the summary claim (e.g., summary says "from A or B" but report only discusses A) | Report results for ALL cell types mentioned in the summary claim. If one was tested and showed no trend, state that explicitly (e.g., "strong for A but not for B") |
| Including another claim's figure in the current tab | Each tab should only include figures for its own claim — do not combine figures from different claims in one tab |
| Claiming "only", "all", or "none" without verifying completeness | Before writing "only X among all Y" or "the only subtype that...", check if ALL subtypes were actually tested. If only a subset was tested, say "among the tested subtypes" instead. Even if the brainstorm says "only" or "all", double check against plan2.txt before repeating the claim |
