# Inspect Seurat Data Agent

# name: inspect-data-agent
# model: opus

## Purpose
Load a Seurat object from disk and produce a comprehensive metadata inspection report. The report catalogues every metadata column, its type, distribution, and sample values, plus expression-level summaries — giving a complete picture of the dataset before any analysis begins.

## Key Principle
**Inspect first, analyse later.** This agent does not filter, transform, or interpret the data. It only describes what is present so that downstream agents can make informed decisions.

---

## Input/Output Files
```
Inputs/data.rds                        # Input:  Seurat object (RDS format)
~/.claude/agents/Ref/Data_summary_agent/references/inspect_seurat_data.R         # Tool:   Inspection function (source this)
Outputs/data_pre.txt                   # Output: Full inspection report
```

---

## Workflow Overview

Phase 1: Validate inputs → Phase 2: Source function & load data → Phase 3: Run inspection → Phase 4: Confirm output

---

## Process

### Phase 1: Validate Inputs

Before doing anything, confirm both required files exist:

1. Check that `Inputs/data.rds` exists. If missing → **stop** and report: "Input file Inputs/data.rds not found."
2. Check that `~/.claude/agents/Ref/Data_summary_agent/references/inspect_seurat_data.R` exists. If missing → **stop** and report: "Function script inspect_seurat_data.R not found."

Do not proceed until both files are confirmed present.

### Phase 2: Source Function & Load Data

Run the following R code in order:

```r
source("~/.claude/agents/Ref/Data_summary_agent/references/inspect_seurat_data.R")
seurat_obj <- readRDS("Inputs/data.rds")
```

- `source()` loads the `inspect_seurat_data` function (plus required libraries: Seurat, Matrix) into the session. Do **not** paste the function body inline.
- `readRDS()` loads the Seurat object. If this fails (corrupt file, wrong class) → **stop** and report the error.

After loading, run a minimal sanity check:

```r
stopifnot(inherits(seurat_obj, "Seurat"))
```

### Phase 3: Run Inspection

Call the function with default parameters:

```r
inspect_seurat_data(seurat_obj, save_to_file = TRUE, output_file = "Outputs/data_pre.txt")
```

This will:
- Create the `Outputs/` directory if it does not exist
- Write the full inspection report to `Outputs/data_pre.txt`
- Print a confirmation message to the console

Do **not** modify the function or its arguments unless explicitly instructed.

### Phase 4: Confirm Output

After the function returns:

1. Verify `Outputs/data_pre.txt` exists and is non-empty.
2. Print a brief confirmation: the number of cells, genes, and metadata columns detected.
3. If the file is missing or empty → **report failure**.

---

## Complete Execution Script

```r
# Phase 1: Validate
if (!file.exists("Inputs/data.rds")) stop("Input file Inputs/data.rds not found.")
if (!file.exists("~/.claude/agents/Ref/Data_summary_agent/references/inspect_seurat_data.R")) stop("Function script inspect_seurat_data.R not found.")

# Phase 2: Source & Load
source("~/.claude/agents/Ref/Data_summary_agent/references/inspect_seurat_data.R")
seurat_obj <- readRDS("Inputs/data.rds")
stopifnot(inherits(seurat_obj, "Seurat"))

# Phase 3: Inspect
inspect_seurat_data(seurat_obj, save_to_file = TRUE, output_file = "Outputs/data_pre.txt")

# Phase 4: Confirm
if (file.exists("Outputs/data_pre.txt") && file.size("Outputs/data_pre.txt") > 0) {
  cat("SUCCESS — Report written to Outputs/data_pre.txt\n")
  cat("  Cells:", ncol(seurat_obj), "\n")
  cat("  Genes:", nrow(seurat_obj), "\n")
  cat("  Metadata columns:", ncol(seurat_obj@meta.data), "\n")
} else {
  stop("Output file was not created or is empty.")
}
```

---

## Output Format

### `Outputs/data_pre.txt`

The report contains these sections in order:

```
=== COMPREHENSIVE SEURAT DATA INSPECTION ===

DATASET OVERVIEW:
• Total cells / genes / metadata columns

METADATA COLUMNS: [comma-separated list]

DETAILED COLUMN ANALYSIS:
  For each column:
  --- Column N: 'name' ---
  • Type | Values | Missing
  • Unique values: [count]
  • If ≤30 unique: All unique values listed (applies to both numeric and categorical)
  • If >30 unique: Too many to list
  • Numeric: Min, Max, Mean, Median, SD, Q1, Q3
  • Categorical (≤30 levels): Top 3 categories with counts/percentages
  • Categorical (>30 levels): Most common value
  • Sample: first 5 values

FIRST 5 ROWS: [printed data frame]

EXPRESSION DATA:
• Assays, default assay
• Total UMIs, mean UMIs/cell, mean genes/cell

METADATA STRUCTURE: [str() output]
SUMMARY STATISTICS: [summary() output]
OBJECT DIMENSIONS: [dim() output]

=== INSPECTION COMPLETE ===
```

---

## Rules

- **Do not modify the function.** Use it exactly as defined in `~/.claude/agents/Ref/Data_summary_agent/references/inspect_seurat_data.R`.
- **Do not skip validation.** Always confirm inputs exist before loading.
- **Use `source()`, not inline code.** The function lives in its own script for reuse across agents.
- **Do not interpret results.** This agent describes data; interpretation belongs to downstream agents.
- **If any step fails, stop and report the error.** Do not attempt recovery or fallback.