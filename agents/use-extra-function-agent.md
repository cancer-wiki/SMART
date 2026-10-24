---
name: "use-extra-function-agent"
description: "Given Route B packages from routing.json, install each R package, figure out how to use it, and write a usage guide showing how to apply it to scRNA-seq data."
model: opus
---

## Purpose
For terms flagged as Route B in `Working/routing.json`, install the specified R package, understand what it does and how to use it, and write a practical usage guide showing how to apply it to scRNA-seq data. Then update `definitions_final.txt` with the resolved definition.

## Key Principle
**The goal is a working R script, not a gene list.** Route B packages implement specialized scoring/classification methods. The paper used this package — we need to apply the same package to our data. The output is a usage guide with runnable R code.

---

## Input/Output Files
```
Working/routing.json              # Input: route_b entries with package names
Working/definitions_detail.txt    # Input+Output: append usage details
Working/definitions_final.txt     # Input+Output: replace "external package (pending)" entries
Working/extra/                    # Output: usage guides and test results
Inputs/paper1_text.txt            # Reference: how the paper used the package
Inputs/paper1_method.txt          # Reference: method details
```

---

## Workflow Overview
Phase 1: Read routing.json → get route_b packages
Phase 2: For each package → find, install, understand
Phase 3: Write usage guide with working R code
Phase 4: Update definitions_detail.txt and definitions_final.txt

---

## Process

### Phase 1: Read Routing JSON
Read `Working/routing.json`. Extract the `route_b` array. For each entry, note:
- `term_name` — the biological term
- `package` — the R package name
- `reason` — why it needs this package

If `route_b` is empty, report "No Route B terms" and exit.

Also read `Inputs/paper1_text.txt` and `Inputs/paper1_method.txt` to understand HOW the paper used this package (what function, what parameters, what input data).

### Phase 2: Find + Install + Understand

For each package:

**2a. Find and install:**
```bash
# Check if already installed
Rscript -e 'cat(requireNamespace("PKGNAME", quietly=TRUE))'

# Try CRAN
Rscript -e 'install.packages("PKGNAME", repos="https://cloud.r-project.org")'

# Try Bioconductor
Rscript -e 'BiocManager::install("PKGNAME", ask=FALSE, update=FALSE)'

# Try GitHub (clone + local install is most reliable)
git clone https://github.com/OWNER/REPO.git /tmp/PKGNAME_source
Rscript -e 'devtools::install("/tmp/PKGNAME_source", dependencies=TRUE, upgrade="never")'
```

If the package source is unknown, search:
```bash
# Search CRAN
Rscript -e 'ap <- available.packages(repos="https://cloud.r-project.org"); cat(grep("PKGNAME", ap[,"Package"], ignore.case=TRUE, value=TRUE))'

# Search GitHub
gh search repos "PKGNAME" --limit 5
```

**2b. Understand what it does:**
```r
# List exported functions
Rscript -e 'library(PKGNAME); cat(ls("package:PKGNAME"), sep="\n")'

# Read help for main function
Rscript -e 'help("main_function", package="PKGNAME")'

# List vignettes
Rscript -e 'vignette(package="PKGNAME")'

# Check what data objects are bundled
Rscript -e 'data(package="PKGNAME")'

# Look at the package source for internal data
Rscript -e 'cat(list.files(system.file(package="PKGNAME"), recursive=TRUE), sep="\n")'
```

**2c. Figure out how to use it on scRNA-seq data:**

Key questions to answer:
- What input does it expect? (matrix, Seurat object, ExpressionSet, data.frame)
- What gene ID format? (HUGO symbols, Entrez IDs, Ensembl)
- Does it need bulk or single-cell data? (if bulk → need pseudobulk)
- What scale? (raw counts, log2, CPM, TPM)
- What does it return? (subtypes, scores, gene lists)
- What are the key parameters?

Also grep the citing paper's methods for how they used it:
```bash
grep -i "PKGNAME\|package_function" Inputs/paper1_text.txt Inputs/paper1_method.txt
```

**2d. Test it:**
Actually run the package on its example data or a minimal test case to confirm it works:
```r
# Run built-in examples
example("main_function", package = "PKGNAME")

# Or create minimal test data and run
```

### Phase 3: Write Usage Guide

Write `Working/extra/{PKGNAME}_guide.md`:

```markdown
# {PKGNAME} — Usage Guide

## What is this?
[One paragraph: what does this package do?]

## Installation
[Exact commands that worked]

## How to apply to scRNA-seq data

### Input requirements
| Requirement | Value |
|-------------|-------|
| Data format | ... |
| Gene IDs    | ... |
| Scale       | ... |
| Single-cell or bulk? | ... |

### Step-by-step R code
[Working R code showing how to apply to a Seurat object or expression matrix]

### What it returns
[What the output looks like and how to interpret it]

## How the citing paper used it
[Grep results from paper text/methods showing their specific usage]

## Reference
- Package: ...
- Version: ...
- Source: ...
```

### Phase 4: Update Definitions

**4a. Append to definitions_detail.txt:**
```
## Section 4: Route B Package Resolution

#### Term: [term_name]
Package: [PKGNAME]
Status: RESOLVED
Usage: See Working/extra/{PKGNAME}_guide.md
Key function: [function_name(input, params)]
```

**4b. Update definitions_final.txt:**
Find the row with "external package (pending)" for this term and replace with a SHORT reference to the package and guide. 

**DO NOT dump gene lists into definitions_final.txt for Route B terms.** The definition should point to the package and the usage guide, not list hundreds of genes. Listing genes would mislead downstream agents into treating it as a simple gene set when it's actually a specialized method.

Example:
```
| 1 | stem cell signature | package (StemScorer) | Apply StemScorer R package (scoring method). Usage guide: Working/extra/StemScorer_guide.md |
| 2 | tumor subtype | package (SubtypeClassifier) | Apply SubtypeClassifier R package (classification method). Usage guide: Working/extra/SubtypeClassifier_guide.md |
```

The gene lists can be saved separately to `Working/extra/extracted_*.txt` for reference, but definitions_final should only reference the package + guide path.

Use python to do the replacement in definitions_final.txt.

---

## Critical Rules
- Always read routing.json to know which packages to handle.
- Actually INSTALL and TEST the package — don't describe it theoretically.
- The output is a WORKING R script, not a gene list.
- Read the citing paper's methods to understand how THEY used the package.
- If install fails, try multiple sources (CRAN → Bioc → GitHub clone).
- UPDATE definitions_final.txt — replace the pending placeholders with SHORT package references (not gene lists).
- If a package bundles gene lists, save them to Working/extra/extracted_*.txt for reference, but do NOT dump them into definitions_final.txt.
- **Install permanently:** Install packages to the user's R library (default location), not to /tmp/. The user should be able to use the package later in R. If you cloned a repo for installation, clean up the clone source after install succeeds:
  ```bash
  rm -rf /tmp/PKGNAME_source
  ```
