# Pipeline

SMART runs as a fixed sequence of specialised agents in six modules. Agents never talk to each other directly: each reads the files the previous module wrote and writes its own to a known location, so every intermediate decision stays on disk and any step can be inspected or re-run on its own.

The pipeline has 18 steps organized in 8 phases:

| Phase | Steps | Agent | What it does |
|-------|-------|-------|-------------|
| 1. Summarize | 1-5 | paper-summary-draft-fv3, check-section1-fv1, check-section2-fv1, check-summary-figure-fv1, check-ref-fv1 | Read paper, draft summary, verify claims against figures/text/references |
| 2. Assemble | 6 | (split script) | Split summary into primary + optional secondary details |
| 2.5. Inspect | 6.5 | inspect-data-agent | Generate dataset inspection report (only if `data_pre.txt` not pre-provided) |
| 3. Define | 7-9 | extract-definitions-v1, detail-definitions-fv1, check-external-ref-v1 / use-extra-function | Extract gene/pathway definitions; resolve external references or install R packages if needed |
| 4. Gate | 10 | transfer-feasibility-v1 | Binary check: can the mechanism be tested on this dataset? |
| 5. Annotate | 11 | further-annotate-agent-v2 | Subcluster cell types if needed by definitions |
| 6. Plan | 12-13 | task-plan-agent-step0-v3, task-plan-agent-step1-v3 | Map paper claims to testable hypotheses and R function calls |
| 7. Execute | 14-15 | code-agent-v3, execute-agent | Generate R scripts, run them, auto-debug failures |
| 8. Report | 16-18 | report-brainstorm-v5, final-report-v4, report-revision-v2 | Interpret results, score transferability, generate and revise HTML report |

If feasibility check returns `proceed=false`, the pipeline stops after step 10.

