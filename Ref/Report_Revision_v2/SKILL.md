# Report Revision Skill - Quick Reference

## Purpose
Quality-check the final report Rmd for number accuracy, plot-claim
alignment, content completeness, figure selection, and text precision.
Fix errors and produce a revised Rmd + revision log.

## Files

| Type | Path |
|------|------|
| Input | `Outputs/final_report.Rmd` (report to check) |
| Input | `Working/brainstorm_final.txt` (statistics source of truth) |
| Input | `Outputs/brainstorm_reorganized.txt` (claim-figure mapping) |
| Input | `Outputs/plots/` (all plot files) |
| Input | `Outputs/results/` (all stat files) |
| Input | `Working/plan2.txt` (what was tested) |
| Output | `Outputs/final_report_revised.Rmd` (corrected report) |
| Output | `Working/revision_log.txt` (change log) |
| Reference | `references/checklist.md` (detailed check rules) |

## Workflow
```
Read all inputs
  → Step 1: Content completeness (FIRST)
  → Step 2: Check summary table numbers + labels
  → Step 3: Check Section 3 tabs (numbers, plots, content, text, figures)
  → Step 4: Check Section 4 tabs (numbers, plots, text, figures)
  → Step 5: Verify plots note + inline plot paths
  → Step 6: Write revised Rmd + log
```

## Check Categories

| Category | What to check |
|----------|-------------|
| Number accuracy | Every r, p, logFC, % matches stat files or plot annotations exactly |
| Fraction counts | x/y counts verified by checking each individual result |
| Plot alignment | Each inline plot matches the claim it's under |
| Cross-check claims | Every claim verified against its source plot |
| Content completeness | All cell types/genes from summary.txt covered in results |
| Figure selection | Figures match claim types; comparative findings use parallel figures |
| Transfer labels | Yes/No/Partial matches brainstorm assessment |
| Claim validity | Each claim maps to summary.txt |
| Superlatives | Softened ("very strong" not "strongest") |
| File existence | All inline plot paths point to real files |

## Source of Truth Hierarchy
1. Stat files in `Outputs/results/` (highest)
2. Plot annotations (title, subtitle, printed values)
3. `brainstorm_final.txt` (lowest — may contain estimates)

## Quick Rules
- Never modify the original Rmd — write to `final_report_revised.Rmd`
- Never estimate — remove numbers if exact value unavailable
- Log every change
- Read actual plots with Read tool to verify content
- Check ALL tabs, no skipping
