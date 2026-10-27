# Final Report v5 Skill - Quick Reference

## Purpose
Generate a polished R Markdown research direction report from brainstorm analysis output. Reorganizes findings into claim-by-claim structure with selected figures.

## Files

| Type | Path |
|------|------|
| Input | `Working/brainstorm_final.txt` (transferability analysis) |
| Input | `Outputs/summary.txt` (paper's discovery summary) |
| Input | `Outputs/data_pre.txt` (dataset metadata summary) |
| Input | `Outputs/plots/` (all analysis plots) |
| Input | `Outputs/results/` (all statistical results) |
| Input | `Working/plan2.txt` (execution plan reference) |
| Output | `Outputs/brainstorm_reorganized.txt` (intermediate — reorganized claims) |
| Output | `Outputs/final_report.Rmd` (final R Markdown report) |
| Reference | `~/.claude/agents/Ref/Final_Report_v5/references/report-structure-rules.md` (detailed section formatting rules) |

## Workflow
```
brainstorm_final.txt + summary.txt + data_pre.txt
  → Phase 1: Decompose into claims, select figures → brainstorm_reorganized.txt
  → Phase 2: First read the reference report structure rules, then generate R Markdown report → final_report.Rmd
```

## Phase 1: Reorganize

1. **Decompose paper** into individual testable claims (from summary.txt)
2. **Map each claim** to brainstorm results: transfer assessment, key stats, figures
3. **Select 1-2 figures per claim** (prefer correlation > boxplot; significant > non-significant)
4. **Extract novel findings** from Section 2 of brainstorm_final.txt
5. **Write brainstorm_reorganized.txt**

## Phase 2: Generate R Markdown

### Report Structure

| Section | Content |
|---------|---------|
| 1. Overview {.tabset} | Paper highlights (from summary.txt) + Dataset overview (from data_pre.txt) |
| 2. Core Validation Summary | Single table: Claim / Transfers? (Yes/No/Partial) / Novel? / Comment |
| 3. Core Validation Results {.tabset} | One tab per claim: 3 bullet points (Test / Result / Assessment) + 1-2 figures |
| 4. Contradictions & Novel {.tabset} | One tab per finding: description + 1 figure + significance |
| 5. Investigation | Bullet points: are contradictions fundamental or context-specific? |
| 6. Final Conclusions | Score: Low / Middle-low / Middle-high / High only (no numeric values) |
| 7. Recommendations {.tabset} | Bullet points format. High = full recs; Middle-high/Middle-low = conditional; Low = abandon |

## Quick Rules

- **Score uses ONLY Low / Middle-low / Middle-high / High** — no numeric values anywhere
- **Transfer column uses ONLY Yes / No / Partial** — nothing else
- **Section 3 uses exactly 3 bullet points per tab**: Test / Result / Assessment
- **Section 5 uses bullet points** — no paragraph prose
- **Section 7 uses bullet points** — no paragraph prose
- **1-2 figures per claim MAX** — avoid overwhelming
- **Core Summary table is king** — reader should get the full picture from this alone
- **Correct figure paths** — verify files exist in Outputs/plots/, use absolute paths
- **Don't repeat brainstorm verbatim** — condense and reorganize
- **R Markdown must be renderable** — valid syntax, all paths resolve

## Figure Selection Priority

| Situation | Preferred Figure |
|-----------|-----------------|
| Correlation + boxplot both exist | Correlation plot (shows relationship + condition split) |
| Boxplot significant (p < 0.1) | Include boxplot too |
| DE/pathway claim | Volcano or GO dot plot |
| Novel finding | Single most informative plot |
| Condition-specific divergence | Correlation plot (colors show the divergence) |

## Score → Recommendation Logic

| Score | Section 7 Content |
|-------|-------------------|
| High | Full recommendations (bullet points): priorities + experiments |
| Middle-high | Conditional (bullet points): what to focus on, what would strengthen the case |
| Middle-low | Conditional (bullet points): what to focus on, what would strengthen the case |
| Low | Abandon (bullet points) with brief rationale |
