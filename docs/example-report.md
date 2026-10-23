# Example report

Every SMART run ends in one self-contained HTML file. It holds the claims extracted from the paper,
the verdict on each, the figures and statistics behind those verdicts, the contradictions and novel
signals, and what to do next.

Read a real one before running anything. It is the fastest way to see what the pipeline gives you.

<!-- TODO: pick the report to feature and drop it in as docs/reports/featured.html.
     Then fill in the source paper, the target dataset and the score below. -->

<div class="grid cards" markdown>

-   :material-file-document-outline: **PLACEHOLDER — source paper → target dataset**

    ---

    PLACEHOLDER. One or two sentences on what this run shows: which claims transferred, which did
    not, and what turned up that the paper never reported.

    Scored **PLACEHOLDER**.

    [Open the full report](reports/featured.html){ .md-button .md-button--primary }

</div>

## What is in a report

Every report has the same seven sections, so reports stay comparable across papers and datasets.

| | Section | What it answers |
|---|---|---|
| 1 | **Overview** | What did the paper claim, and what is in the dataset it is being tested against? |
| 2 | **Validation summary** | The key table. Every claim, with a yes, no or partial verdict. Start here. |
| 3 | **Validation results** | For each claim: the figures, the statistics, and the reasoning behind the verdict. |
| 4 | **Contradictions and novel findings** | What ran against the paper, and what turned up that the paper never claimed. |
| 5 | **Investigation of contradictions** | Why a contradiction happened. Often the most interesting section. |
| 6 | **Final conclusions** | The overall [transferability score](scores.md) and what it rests on. |
| 7 | **Recommendations** | What to do next, given the score. Follow-up analyses or experiments. |

!!! tip "Reading a report quickly"
    Go to **section 2** for the verdict table, then jump to the one or two claims in **section 3**
    that matter for your question. Sections 4 and 5 are where the unexpected results live.

## Beyond the report

The report is a selection. The run keeps everything:

| | |
|---|---|
| `Outputs/plots/` | Every figure generated, including those the report did not show |
| `Outputs/results/` | Every statistical table, as CSV |
| `Outputs/analysis.R` *or* `.py` | The exact code that produced them, re-runnable on its own |
| `Working/` | Summary drafts, verification checks, definitions and plans |

A report is therefore auditable end to end: every number in it traces back to a table, and every
table traces back to a line of code you can read and re-run.
