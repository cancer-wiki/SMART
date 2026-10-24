# Phase 2: Supplementary File Check

## Goal
For each CHECK_SUPP term from Phase 1, open the referenced supplementary file and extract the relevant gene list or pathway information.

---

## Before Starting

1. List all files in `Inputs/Supp/` to know what is available:
```bash
ls -la Inputs/Supp/
```

2. Read `Working/definitions_detail.txt` to get the CHECK_SUPP items and their fig/supp references.

---

## Process

### Step 1: Identify the Correct Supp File

Match the reference from the paper to a file in `Inputs/Supp/`. Examples:
- "Supplementary Table 3" → look for an xlsx file with tables
- "Supplementary Fig. 2" → look for a pdf or image file with figures
- "Extended Data Fig. 5" → may be in a separate pdf

### Step 2: Open the File Using the Correct Method

#### Excel Files (.xlsx, .xls)

**First: Check if the paper says which sheet to look at.**

If yes → go directly to that sheet.

If no → inspect sheet names first:
```R
library(readxl)
excel_sheets("Inputs/Supp/filename.xlsx")
```

Then check if the first sheet has a summary. If no summary, use sheet names to find candidates.

**Read the target sheet:**
```R
library(readxl)
library(org.Hs.eg.db)
library(dplyr)

raw <- read_excel(
  "Inputs/Supp/filename.xlsx",
  sheet = "Sheet Name",
  col_names = FALSE
)

# Filter to known gene symbols
known_genes <- keys(org.Hs.eg.db, keytype = "SYMBOL")
gene_lists <- lapply(raw, function(col) {
  col <- as.character(col)
  col[col %in% known_genes] %>%
    na.omit() %>%
    unique()
})

# Inspect results
gene_lists[[1]]  # e.g., upregulated genes
gene_lists[[2]]  # e.g., downregulated genes
```

Adjust `col_names`, column indices, etc. based on the actual file structure.

#### PDF Files (.pdf)

**First: Glance through to find the pages of interest.**
```bash
# Get page count
pdfinfo Inputs/Supp/filename.pdf

# Quick text extraction to scan
pdftotext Inputs/Supp/filename.pdf - | head -200
```

**Then: Convert the target page to image for detailed reading:**
```bash
pdftoppm -png -r 150 -f PAGE -l PAGE Inputs/Supp/filename.pdf Inputs/Supp/page
```

Read the resulting image to extract gene names or pathway info.

#### Word/Docx Files (.docx)

Docx files are already converted to `.md` files with the same base name.

**First: Read the md file to find which section/image is relevant:**
```bash
cat Inputs/Supp/filename.md
```

The md file records where images are stored. If you need to check a figure within the docx, read just that image.

#### Figure/Image Files (.png, .jpg, .tif)

Read the image directly to extract gene names, pathway labels, or other information.

---

## Step 3: Evaluate the Supp Content

### What to RECORD:

| Supp Content Type | Action |
|-------------------|--------|
| Gene list from a specific comparison | Record all genes |
| Heatmap with labeled genes (relevant subset) | Record all labeled genes |
| Pathway results table | Record pathway names, but see decision rules |
| Bar chart/dot plot of specific genes | Record all genes shown |
| Experiment results for a gene subset | Record all genes with results |

### What to IGNORE:

| Supp Content Type | Action | Reason |
|-------------------|--------|--------|
| Volcano plot | Ignore | Too many irrelevant genes |
| Enrichment dot/bar plot (general) | Ignore | Too many irrelevant pathways |
| Full marker gene table from clustering | Ignore | Too specific; use main text description instead |
| Full DEG table with thousands of genes | Ignore unless paper highlighted a subset | Not usable directly |

### Special Case: Relevant Subset Plots
If a figure shows experiment results for a **specific subset** of genes (e.g., a heatmap of 10 validated genes with clear labels), and those genes are all relevant, then **record ALL of them**. The key test: are these genes specifically chosen because they passed some validation, or is it just a dump of all results?

---

## Step 4: Update the Table

Update the CHECK_SUPP rows in `Working/definitions_detail.txt` with the Supp Result column filled in.

---

## What NOT to Do

| Wrong | Right |
|-------|-------|
| Read every sheet in the excel | Find the right sheet first |
| Record all 2000 DEGs from a supp table | Only record if paper highlighted them |
| Treat a volcano plot as a gene list | Ignore volcano plots |
| Use marker genes from clustering directly | Use main text description of that cluster |
| Skip checking the supp when paper says "see Supp Table X" | Always check when flagged as CHECK_SUPP |
| Read the entire pdf | Glance first, then focus on pages of interest |
