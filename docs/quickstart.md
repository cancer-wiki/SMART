# Quick start

!!! note
    SMART runs on the [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code).
    Agents execute on Claude Opus.

## What you need

- **A source paper.** A PubMed URL is enough. If you have already summarised the study yourself,
  supply that instead and extraction is skipped.
- **A target dataset.** A Seurat object (`.rds`) or an AnnData object (`.h5ad`).
- **R or Python.** The analysis codebase is available in both.

## 1 · Install

Agents are installed into `~/.claude/agents/`, where the Claude Code CLI picks them up.

```bash
git clone https://github.com/cancer-wiki/SMART.git
cd SMART
bash install.sh            # 20 agents + reference files
bash install_packages.sh   # R and Python dependencies
```

<!-- TODO: install_packages.sh does not exist yet. Repo ships install_R_packages.R (R only). -->

## 2 · Example case

```bash
bash setup_case.sh https://pubmed.ncbi.nlm.nih.gov/PLACEHOLDER/ examples/demo_data.rds demo_case
cd demo_case
bash single_case.sh
```

Open `Outputs/final_report_revised.html` when it finishes. Takes roughly **PLACEHOLDER** on a laptop.

!!! tip "Do not want to wait?"
    [Read a finished report](example-report.md) first.

<!-- TODO: needs a demo paper + small public dataset, and a real runtime figure. -->

## 3 · Run on your own

```bash
bash setup_case.sh <pubmed-url> <path/to/your_data.rds> my_case
cd my_case
bash single_case.sh
```

<!-- TODO: setup_case.sh does not exist yet. -->

The setup script fetches the paper, pulls its text, methods, references, figure captions and figure
images, links your dataset into place, and lays out the folders the pipeline expects. See
[Case folders](cases.md) for the full layout.

## What lands on disk

| File | What it is |
|---|---|
| `Outputs/final_report_revised.html` | **The report.** Self-contained, opens in any browser. Start here. |
| `Outputs/summary.txt` | The verified findings and claims extracted from the paper. |
| `Outputs/plots/` · `results/` | Every figure and statistical table generated. |
| `Outputs/analysis.R` *or* `analysis.py` | The exact code that was run. Re-runnable on its own. |
| `Working/` | Drafts, verification checks, definitions and plans. The full audit trail. |

!!! tip "Running at scale"
    Running one paper against many datasets, or many papers against one dataset?
    See [Batch running](batch.md).
