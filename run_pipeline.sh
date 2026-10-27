#!/bin/bash
# ==============================================================================
# TransferAgent Pipeline
#
# Tests whether a published biological discovery transfers to an independent
# scRNA-seq dataset. Runs 20 sequential agent steps from paper download through
# final report generation.
#
# Usage:
#   bash run_pipeline.sh <output_folder> <paper_doi_or_pmid_or_url> <data_path> <tissue> \
#     [--paper-summary FILE] [--definitions FILE] [--data-summary FILE]
#
# Example:
#   bash run_pipeline.sh ./test_case pubmed_url /path/to/data.rds "colon cancer"
# ==============================================================================

set -euo pipefail

# --- Parse arguments ---
usage() {
  echo "Usage: bash run_pipeline.sh <output_folder> <paper_doi_or_pmid_or_url> <data_path> <tissue>"
  echo "         [--paper-summary FILE] [--definitions FILE] [--data-summary FILE]"
  echo ""
  echo "  output_folder    Where the case folder will be created (e.g., ./results/case1)"
  echo "  paper_input      DOI, PMID, PMCID, or a doi.org / PubMed / PMC / nature.com URL"
  echo "                   (use - when both --paper-summary and --definitions are given)"
  echo "  data_path        Path to a .rds or .h5ad file, or a folder with raw files and metadata"
  echo "  tissue           Tissue or disease of the dataset, in quotes (e.g., \"colon cancer\")"
  echo ""
  echo "  Optional: skip steps by giving your own .txt files"
  echo "  --paper-summary FILE   Your paper summary (skips steps 2-6)"
  echo "  --definitions FILE     Your scRNA-seq definitions of the paper's terms (skips steps 7-9)"
  echo "  --data-summary FILE    Your dataset summary (skips steps 10-11; data_path must be"
  echo "                         the ready Seurat .rds that the summary describes)"
  exit 1
}

PAPER_SUMMARY=""
DEFINITIONS=""
DATA_SUMMARY=""
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --paper-summary) PAPER_SUMMARY="${2:-}"; shift 2 || usage ;;
    --definitions)   DEFINITIONS="${2:-}";   shift 2 || usage ;;
    --data-summary)  DATA_SUMMARY="${2:-}";  shift 2 || usage ;;
    -h|--help)       usage ;;
    *)               POSITIONAL+=("$1"); shift ;;
  esac
done
if [ ${#POSITIONAL[@]} -ne 4 ] || [ -z "${POSITIONAL[3]}" ]; then
  usage
fi

OUTPUT_DIR="${POSITIONAL[0]}"
PAPER_INPUT="${POSITIONAL[1]}"
DATA_PATH="${POSITIONAL[2]}"
TISSUE="${POSITIONAL[3]}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Validate inputs ---
if [ ! -e "$DATA_PATH" ]; then
  echo "ERROR: Data path not found: $DATA_PATH"
  exit 1
fi
for f in "$PAPER_SUMMARY" "$DEFINITIONS" "$DATA_SUMMARY"; do
  if [ -n "$f" ] && [ ! -f "$f" ]; then
    echo "ERROR: File not found: $f"
    exit 1
  fi
done
NEED_PAPER=true
if [ -n "$PAPER_SUMMARY" ] && [ -n "$DEFINITIONS" ]; then
  NEED_PAPER=false
elif [ "$PAPER_INPUT" = "-" ]; then
  echo "ERROR: A paper is needed unless you give both --paper-summary and --definitions."
  exit 1
fi
if [ -n "$DATA_SUMMARY" ]; then
  case "$DATA_PATH" in
    *.rds|*.RDS) ;;
    *) echo "ERROR: With --data-summary, data_path must be the Seurat .rds the summary describes."
       exit 1 ;;
  esac
fi

# --- Create folder structure ---
mkdir -p "$OUTPUT_DIR/data" "$OUTPUT_DIR/Inputs" "$OUTPUT_DIR/Outputs" "$OUTPUT_DIR/Working/logs"
CASE_DIR="$(cd "$OUTPUT_DIR" && pwd)"
LOG_DIR="$CASE_DIR/Working/logs"

# --- Your own summaries, if given ---
[ -n "$PAPER_SUMMARY" ] && cp "$PAPER_SUMMARY" "$CASE_DIR/Outputs/summary.txt"
[ -n "$DEFINITIONS" ]   && cp "$DEFINITIONS"   "$CASE_DIR/Working/definitions_final.txt"
[ -n "$DATA_SUMMARY" ]  && cp "$DATA_SUMMARY"  "$CASE_DIR/Outputs/data_pre.txt"

echo "============================================================"
echo "  TransferAgent Pipeline"
echo "  Output: $CASE_DIR"
echo "  Paper:  $PAPER_INPUT"
echo "  Data:   $DATA_PATH"
echo "  Tissue: $TISSUE"
[ -n "$PAPER_SUMMARY" ] && echo "  Paper summary: $PAPER_SUMMARY (skipping steps 2-6)"
[ -n "$DEFINITIONS" ]   && echo "  Definitions:   $DEFINITIONS (skipping steps 7-9)"
[ -n "$DATA_SUMMARY" ]  && echo "  Data summary:  $DATA_SUMMARY (skipping steps 10-11)"
echo "============================================================"
echo ""

# --- Helper: run claude silently, log to file ---
run_agent() {
  local step_name="$1"
  local prompt="$2"
  local log_file="$LOG_DIR/${step_name}.log"
  local extra_args="${3:-}"
  claude -p "$prompt" --dangerously-skip-permissions $extra_args > "$log_file" 2>&1
}

# ==============================================================================
# STEP 0: Download paper
# ==============================================================================
if [ "$NEED_PAPER" = true ]; then
  echo "[Step 0] Preparing the paper..."
  echo "         (Nature papers: a browser opens for login — press Enter in terminal when logged in)"
  echo ""
  if ! python3 "$SCRIPT_DIR/download_paper.py" "$PAPER_INPUT" "$CASE_DIR"; then
    echo "ERROR: Could not download the paper. Stopping."
    exit 1
  fi
  echo ""
  echo "         Paper downloaded to $CASE_DIR/Inputs/"
else
  echo "[Step 0] Paper summary and definitions given, no paper download needed."
fi

# ==============================================================================
# STEP 1: Copy data
# ==============================================================================
echo "[Step 1] Copying dataset..."
if [ -n "$DATA_SUMMARY" ]; then
  cp "$DATA_PATH" "$CASE_DIR/Inputs/data.rds"
  echo "         Data copied to $CASE_DIR/Inputs/data.rds (used as is)"
elif [ -d "$DATA_PATH" ]; then
  mkdir -p "$CASE_DIR/data"
  cp -r "$DATA_PATH"/. "$CASE_DIR/data/"
  echo "         Data folder copied to $CASE_DIR/data/"
elif [ -f "$DATA_PATH" ]; then
  mkdir -p "$CASE_DIR/data"
  DATA_EXT="${DATA_PATH##*.}"
  if [ "$DATA_EXT" = "h5ad" ]; then
    cp "$DATA_PATH" "$CASE_DIR/data/data.h5ad"
    echo "         Data copied to $CASE_DIR/data/data.h5ad"
  elif [ "$DATA_EXT" = "rds" ] || [ "$DATA_EXT" = "RDS" ]; then
    cp "$DATA_PATH" "$CASE_DIR/data/data.rds"
    echo "         Data copied to $CASE_DIR/data/data.rds"
  else
    cp "$DATA_PATH" "$CASE_DIR/data/$(basename "$DATA_PATH")"
    echo "         Data copied to $CASE_DIR/data/$(basename "$DATA_PATH")"
  fi
fi
echo ""

cd "$CASE_DIR"

# ==============================================================================
# PHASE 1: Summarize paper (Steps 2-6)
# ==============================================================================
if [ -z "$PAPER_SUMMARY" ]; then
  echo "[Step 2] Summarizing the paper..."
  run_agent "step02_summary_draft" \
    "Launch paper-summary-draft-agent-fv3 agent on Inputs/paper1_text.txt"
  echo "         Finished paper summary draft."

  echo "         Revising paper summary (1/4)..."
  run_agent "step03_check_section1" \
    "Launch check-section1-fv1-agent agent on Working/draft_summary1.txt"

  echo "         Revising paper summary (2/4)..."
  run_agent "step04_check_section2" \
    "Launch check-section2-fv1-agent agent on Working/draft_summary2.txt"

  echo "         Revising paper summary (3/4)..."
  run_agent "step05_check_figure" \
    "Launch check-summary-figure-fv1-agent agent on Working/draft_summary3.txt"

  echo "         Revising paper summary (4/4)..."
  run_agent "step06_check_ref" \
    "Launch check-ref-fv1-agent agent on Working/draft_summary4.txt"

  # Assemble final summary
  if grep -q "^Secondary details:" Working/draft_summary5.txt 2>/dev/null; then
    sed '/^$/{ N; /\nSecondary details:/{ s/.*//; q; } }' Working/draft_summary5.txt | sed '/^$/{ :a; N; $!ba; s/\n*$//; }' > Outputs/summary.txt
    sed -n '/^Secondary details:/,$p' Working/draft_summary5.txt > Outputs/optional_extra_detail.txt
  else
    cp Working/draft_summary5.txt Outputs/summary.txt
  fi
  echo "         Finished summary. Check Outputs/summary.txt"
else
  echo "[Steps 2-6] Using your paper summary: Outputs/summary.txt"
fi
echo ""

# ==============================================================================
# PHASE 2: Define terms (Steps 7-9)
# ==============================================================================
if [ -z "$DEFINITIONS" ]; then
  echo "[Step 7] Deciding terms that need scRNA-seq definitions..."
  run_agent "step07_extract_defs" \
    "Launch extract-definitions-v1-agent agent on Outputs/summary.txt"

  echo "[Step 8] Checking paper for detailed definitions..."
  run_agent "step08_detail_defs" \
    "Launch detail-definitions-fv1-agent agent on Outputs/summary.txt"

  # Route A: external paper references
  if [ -f Working/routing.json ] && [ "$(jq -r '.route_a | length' Working/routing.json 2>/dev/null)" -gt 0 ] 2>/dev/null; then
    echo "[Step 9a] Definitions reference external papers, checking..."
    run_agent "step09a_external_ref" \
      "Launch check-external-ref-v1-agent on $(pwd). Read Working/routing.json for Route A terms. Find papers, extract gene lists, and update definitions_detail.txt and definitions_final.txt."
  fi

  # Route B: R package classifiers
  if [ -f Working/routing.json ] && [ "$(jq -r '.route_b | length' Working/routing.json 2>/dev/null)" -gt 0 ] 2>/dev/null; then
    echo "[Step 9b] Definitions require extra R packages, working on it..."
    run_agent "step09b_extra_func" \
      "Launch use-extra-function-agent on $(pwd). Read Working/routing.json for Route B terms. Install each package, write usage guides, and update definitions_detail.txt and definitions_final.txt."
  fi
else
  echo "[Steps 7-9] Using your definitions: Working/definitions_final.txt"
fi
echo ""

# ==============================================================================
# PHASE 3: Prepare data (Steps 10-11)
# ==============================================================================
if [ -z "$DATA_SUMMARY" ]; then
  echo "[Step 10] Preparing the data..."
  run_agent "step10_preprocess" \
    "Launch preprocess-agent-v1 agent on data/, this data is $TISSUE data. Write the final Seurat object to Inputs/data.rds."

  if [ ! -f Outputs/data_pre.txt ]; then
    echo "[Step 11] Summarizing the data..."
    run_agent "step11_inspect_data" \
      "Launch inspect-data-agent agent on Inputs/data.rds, this data is $TISSUE data."
  else
    echo "[Step 11] Data summary already exists, skipping."
  fi
else
  echo "[Steps 10-11] Using your data summary: Outputs/data_pre.txt"
fi
echo ""

# ==============================================================================
# PHASE 4: Feasibility gate (Step 12)
# ==============================================================================
echo "[Step 12] Checking if the paper logic is worth exploring on your data..."
run_agent "step12_feasibility" \
  "Launch transfer-feasibility-v2 agent on Outputs/summary.txt"

if [ -f Outputs/feasibility.json ]; then
  PROCEED=$(jq -r '.proceed' Outputs/feasibility.json 2>/dev/null || echo "unknown")
  if [ "$PROCEED" != "true" ]; then
    REASON=$(jq -r '.reason' Outputs/feasibility.json 2>/dev/null || echo "unknown reason")
    echo ""
    echo "============================================================"
    echo "  Not worth pursuing on this dataset."
    echo "  Reason: $REASON"
    echo "  Details: Outputs/feasibility.json"
    echo "============================================================"
    exit 0
  fi
else
  echo "WARNING: feasibility.json not found. Proceeding anyway."
fi
echo "         Feasible. Proceeding with analysis."
echo ""

# ==============================================================================
# PHASE 5: Annotate data (Step 13)
# ==============================================================================
echo "[Step 13] Refining cell type annotations for this analysis..."
run_agent "step13_annotate" \
  "Launch further-annotate-agent-v2 agent on Inputs/data.rds"
echo ""

# ==============================================================================
# PHASE 6: Plan analysis (Steps 14-15)
# ==============================================================================
echo "[Step 14] Drafting the analysis plan based on the paper and your data..."
run_agent "step14_plan0" \
  "Launch task-plan-agent-step0-v4 agent on Outputs/summary.txt"

echo "[Step 15] Finalizing the analysis plan..."
run_agent "step15_plan1" \
  "Launch task-plan-agent-step1-v3 agent on Outputs/summary.txt"
echo ""

# ==============================================================================
# PHASE 7: Execute analysis (Steps 16-17)
# ==============================================================================
echo "[Step 16] Coding the analysis scripts..."
run_agent "step16_code" \
  "Launch code-agent-v4 agent on Working/plan2.txt"

echo "[Step 17] Executing the analysis..."
run_agent "step17_execute" \
  "Launch execute-agent agent on Outputs/preprocess.R" \
  "--max-turns 200"
echo ""

# ==============================================================================
# PHASE 8: Report (Steps 18-20)
# ==============================================================================
echo "[Step 18] Finished executing. Brainstorming on results..."
run_agent "step18_brainstorm" \
  "Launch report-brainstorm-v6 agent on Working/plan2.txt"

echo "[Step 19] Consolidating the report..."
run_agent "step19_report" \
  "Launch final-report-v5 agent on Working/brainstorm_final.txt"

echo "[Step 20] Final revision..."
run_agent "step20_revision" \
  "Launch report-revision-v2 agent on Outputs/final_report.Rmd"

# Render Rmd to HTML
echo "         Rendering HTML report..."
Rscript -e 'rmarkdown::render("Outputs/final_report_revised.Rmd", quiet = TRUE)' > "$LOG_DIR/step20_render.log" 2>&1

echo ""
echo "============================================================"
echo "  Finished!"
echo "  Report: $CASE_DIR/Outputs/final_report_revised.html"
echo "  Logs:   $CASE_DIR/Working/logs/"
echo "============================================================"
