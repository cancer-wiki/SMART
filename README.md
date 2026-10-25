<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/smart_logo_dark.svg">
  <img src="assets/smart_logo.svg" alt="SMART, a 20-agent workflow" width="236">
</picture>

<p><strong>Test whether a published discovery holds in your data.</strong></p>

<p>SMART reads a paper, works out which of its claims your single-cell dataset can test,
runs those analyses, and returns a report of which ones held.</p>

[![preprint](https://img.shields.io/badge/preprint-bioRxiv-b31b1b?style=flat-square)](https://www.biorxiv.org/)
[![website](https://img.shields.io/badge/website-cancer--wiki.org-4b3ec9?style=flat-square)](https://cancer-wiki.org)
[![example report](https://img.shields.io/badge/example-report-c2603a?style=flat-square)](https://cancer-wiki.github.io/SMART/example-report/)
[![license](https://img.shields.io/badge/license-MIT-2f855a?style=flat-square)](LICENSE)

<img src="assets/pipeline.svg" alt="The SMART pipeline: a paper and a dataset pass through six modules to a transferability report" width="860">

</div>

---

## What you'd use it for

<p align="center"><b>Every biologist is a CEO.</b> SMART is the staff you could never hire.</p>

<table>
<tr>
<td width="50%" valign="top">

<img src="https://img.shields.io/badge/RESEARCH_ASSISTANT-4b3ec9?style=flat-square" alt="Research assistant">

**Is this paper worth reading closely?**

Before you spend an afternoon on it, SMART does the first pass: reads the paper, tests its claims against your own data, and hands you a report end to end.

</td>
<td width="50%" valign="top">

<img src="https://img.shields.io/badge/LIBRARIAN-177a63?style=flat-square" alt="Librarian">

**Did we overlook something already published?**

Somewhere in another cancer's literature is a result that would work in yours. It has sat there for years, cited but never tested, because nobody in either field had a reason to look. SMART looks.

</td>
</tr>
<tr>
<td width="50%" valign="top">

<img src="https://img.shields.io/badge/CONSULTANT-c2603a?style=flat-square" alt="Consultant">

**My cancer barely has a literature.**

SMART brings the well-studied cancers in as outside expertise, testing their findings against your data so a small field can draw on a large one.

</td>
<td width="50%" valign="top">

<img src="https://img.shields.io/badge/ANALYST-3a4a5a?style=flat-square" alt="Analyst">

**What is my data telling me?**

Every paper you test becomes a lens on your own dataset. Claims that fail, claims that arrive by another route, and signals no paper reported: SMART picks them out and writes them up.

</td>
</tr>
</table>

---

## Quick Start

> [!NOTE]
> SMART runs on the [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code). Agents execute on Claude Opus.

### 1 · Setup

```bash
git clone https://github.com/cancer-wiki/SMART.git
cd SMART
bash setup.sh
```

This sets up the SMART workflow and installs the required packages. You need **R** and **Python 3** installed first.

### 2 · Run

```bash
bash run_pipeline.sh <output_folder> <paper> <data> <tissue>
```

| Argument | What it is | Example |
|---|---|---|
| `<output_folder>` | Where the case folder is created | `./results/case1` |
| `<paper>` | DOI, PMID, PMCID, or a doi.org, PubMed, PMC or nature.com URL | `10.1038/s41467-025-59282-4` |
| `<data>` | Your single-cell dataset: either the path to a Seurat `.rds` or AnnData `.h5ad` file, or a folder with the raw files (e.g. Cell Ranger output) and the sample metadata | `/path/to/your_data.rds` or `/path/to/your_data_folder/` |
| `<tissue>` | The tissue or disease your dataset comes from, in quotes | `"colon cancer"` |

**Note:** for the statistical tests to be meaningful, your data needs at least 3 biological samples (donors or patients) per condition.

For example:

```bash
bash run_pipeline.sh ./results/case1 "10.1038/s41467-025-59282-4" /path/to/your_data.rds "colon cancer"
```

For a Nature journal paper, a browser window opens at the start.\
Log in to the journal with your own institutional or personal account.\
Once you're logged in, minimize the window (don't close it), then press Enter in the terminal.\
Any other paper is downloaded from PubMed Central with no login, so it needs to be open access there.\
The pipeline then runs all 20 steps on its own.\
Each step's log goes to `Working/logs/`.\
If the paper's logic can't be tested on your data, the pipeline stops after step 12 and explains why in `Outputs/feasibility.json`.

| What you get | |
|---|---|
| `Outputs/final_report_revised.html` | **The report.** Self-contained, opens in any browser. Start here. |
| `Outputs/summary.txt` | The verified findings and claims extracted from the paper. |
| `Outputs/plots/` · `results/` | Every figure and statistical table generated. |
| `Outputs/preprocess.R` · `analysis.R` | The exact code that was run. Re-runnable on its own. |
| `Working/` | Drafts, verification checks, definitions and plans. The full audit trail. |

## Citation

<!-- TODO: fill in once the preprint is posted. -->

```bibtex
@article{cheng2026smart,
  title   = {A multi-agent AI framework for Cross-Cancer Discovery Transfer},
  author  = {Cheng, Lingxin and Shireman, Jack and Gogate, Akash and
             Kendziorski, Christina},
  journal = {PLACEHOLDER},
  year    = {2026}
}
```

## License

[MIT](LICENSE)
