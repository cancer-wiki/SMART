# Case folders

Each case folder follows this layout:

```
case_name/
  Inputs/
    paper1_text.txt       # Main paper text (required)
    paper1_method.txt     # Methods section (optional)
    paper1_ref.txt        # References list (optional)
    data.rds              # Seurat object symlink (required)
    Captions/Fig*.txt     # Figure captions (optional)
    figures/Fig*.png      # Figure images (optional)
    Supp/                 # Supplementary files (optional)
  Outputs/
    summary.txt           # Paper summary (generated)
    data_pre.txt          # Dataset inspection report (pre-provided)
    feasibility.json      # {proceed: true/false, reason: "..."}
    preprocess.R           # Generated preprocessing script
    analysis.R             # Generated analysis script
    correction_record.txt  # Auto-debug log
    final_report.Rmd       # R Markdown report
    final_report_revised.Rmd # Revised report
    plots/                 # Generated figures
    results/               # Statistical output CSVs
  Working/
    draft_summary*.txt    # Intermediate summary drafts (1-5)
    check*.txt            # Verification check outputs (1-4)
    map.txt               # Summary-figure mapping
    routing.json          # Route A/B definitions routing
    definitions_needed.txt # Terms needing definitions
    definitions_detail.txt # Detailed definition resolution
    definitions_final.txt # Final gene/pathway definitions
    plan0.txt             # Hypothesis mapping
    plan2.txt             # Unified execution plan
    brainstorm_final.txt  # Transferability assessment
    report_brainstorm.txt # Per-step observations
```


## Setting Up a New Transfer Batch

When you have paper summaries + definitions from one tissue and want to test them on a different dataset:

```bash
# 1. Create the batch folder
mkdir -p /path/to/NewTissue_paperSource

# 2. For each paper case, create a minimal folder with summary + definitions
SRC=/path/to/original/PaperSource   # folder with case subfolders
DST=/path/to/NewTissue_paperSource
DATA_RDS=/path/to/Data/NewTissue/data.rds
DATA_PRE=/path/to/Data/NewTissue/data_pre.txt

for case in $(ls -d "$SRC"/case*/ | xargs -I{} basename {}); do
    num="${case#case}"
    dest="$DST/source${num}"

    mkdir -p "$dest/Inputs" "$dest/Outputs" "$dest/Working"

    # Copy existing summary and definitions
    cp "$SRC/$case/Outputs/summary.txt" "$dest/Outputs/summary.txt"
    cp "$SRC/$case/Working/definitions_final.txt" "$dest/Working/definitions_final.txt"

    # Point to new dataset
    ln -sf "$DATA_RDS" "$dest/Inputs/data.rds"
    cp "$DATA_PRE" "$dest/Outputs/data_pre.txt"
done

# 3. Run the pipeline from step 10 (feasibility) onward — skip summary steps
cd "$DST"
for d in */; do
    (cd "$d" && claude -p "Launch transfer-feasibility-v1-agent agent on Outputs/summary.txt" --dangerously-skip-permissions) > "${d%/}.log" 2>&1 &
    (($(jobs -r | wc -l) >= 4)) && wait -n
done
wait
```

When reusing summaries, start the pipeline from **step 10** (feasibility check). Steps 1-9 (summarize + define) are only needed when processing a new paper from scratch.

## Resetting a Case

To re-run analysis from the planning stage onward (keeping summary + definitions):

```bash
cd case_folder
rm -rf Outputs/plots Outputs/results
rm -f Outputs/correction_record.txt Outputs/final_report.html Outputs/final_report.Rmd
rm -f Outputs/final_report_revised.html Outputs/final_report_revised.Rmd
rm -f Outputs/preprocess.R Outputs/analysis.R
rm -f Working/analysis.log Working/brainstorm_final.txt Working/brainstorm_reorganized.txt
rm -f Working/plan0.txt Working/plan2.txt Working/preprocess-brainstorm.txt
rm -f Working/preprocess.log Working/processed_meta.csv Working/report_brainstorm.txt
```

