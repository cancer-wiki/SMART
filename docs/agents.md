# Agent reference

| Agent | Description |
|-------|-------------|
| `paper-summary-draft-fv3` | Read paper text, extract structured summary (discovery, clinical, mechanism) |
| `check-section1-fv1-agent` | Verify Section 1 (clinical findings) against figures |
| `check-section2-fv1-agent` | Verify Section 2 (mechanism) for causal logic and accuracy |
| `check-summary-figure-fv1-agent` | Cross-check summary against any overview/graphical-abstract figure |
| `check-ref-fv1-agent` | Verify figure references cited alongside claims match the actual figure content |
| `extract-definitions-v1-agent` | List terms needing precise definitions for testing |
| `detail-definitions-fv1-agent` | Resolve each term to gene lists or pathway sets from the paper |
| `check-external-ref-v1-agent` | Find referenced papers and extract gene lists (Route A definitions) |
| `use-extra-function-agent` | Install R packages and write usage guides (Route B definitions) |
| `inspect-data-agent` | Load Seurat object and produce comprehensive metadata inspection report |
| `transfer-feasibility-v1` | Binary gate: can the mechanism be tested on this dataset? |
| `further-annotate-agent-v2` | Subcluster broad cell types to match paper-specific subtypes |
| `task-plan-agent-step0-v3` | Map paper claims to testable hypotheses against the data |
| `task-plan-agent-step1-v3` | Convert hypotheses to concrete R function calls |
| `code-agent-v3` | Generate `preprocess.R` and `analysis.R` from the execution plan |
| `execute-agent` | Run R scripts, diagnose failures, auto-patch and retry |
| `report-brainstorm-v5` | Interpret all plots/stats, assign transferability score |
| `final-report-v4` | Generate polished R Markdown report from brainstorm results |
| `report-revision-v2` | Quality-check the report for number accuracy, plot-claim alignment, and completeness |
