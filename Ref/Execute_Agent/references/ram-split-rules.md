# RAM Split Rules

When `analysis.R` crashes with an out-of-memory error, the agent must split
it into two parts so each part can run within available memory. This file
documents the exact splitting protocol.

---

## When to split

**Only `analysis.R`. Never `preprocess.R`.**

Preprocessing must run in one shot because the atomic handoff is the metadata
CSV. If preprocess.R hits RAM, the fix is to patch the offending step (e.g.
filter the gene set before AddModuleScore), not to split.

For analysis.R, signals that splitting is appropriate:
- `Error: cannot allocate vector of size X Gb`
- `Error: vector memory exhausted`
- The script printed `=== Task A ===` ... `=== Task B ===` then died mid-Task-B
  with no closing line.
- The OS killed the R process (no R-level error, but a final partial log).

---

## Locating the split point

Read `Working/analysis.log` and find:
- **Last successful task header**: the highest `=== Task X.Y ===` line that
  is followed by the task's expected stats / `print(...)` output.
- **Crashing task**: the next `=== Task ... ===` header (which may or may not
  appear in the log) OR the first `Error: cannot allocate vector ...` line.

Open `Outputs/analysis.R`. Find the **block boundary** between these two tasks
— typically the line immediately before the crashing task's
`# --- Task X.Y: ... ---` comment.

---

## Building the two parts

Both parts share the same header. Define it once and copy verbatim into both
files:

```r
# === HEADER (identical in part1 and part2) ===
library(Seurat); library(ggplot2); library(dplyr); library(tidyverse); library(msigdbr)
source("~/.claude/agents/Ref/Code_Agent_v4/references/function_v2.R")

seurat_obj <- readRDS("Inputs/data.rds")
processed_meta <- read.csv("Working/processed_meta.csv", row.names = 1, stringsAsFactors = FALSE)
new_cols <- setdiff(colnames(processed_meta), colnames(seurat_obj@meta.data))
seurat_obj <- AddMetaData(seurat_obj, metadata = processed_meta[, new_cols, drop = FALSE])

dir.create("Outputs/plots",   recursive = TRUE, showWarnings = FALSE)
dir.create("Outputs/results", recursive = TRUE, showWarnings = FALSE)
```

### Part 1: `Outputs/analysis_corrected_part1.R`
```
HEADER
[every task block from start through the LAST SUCCESSFUL task]
cat("Part 1 complete\n")
```

### Part 2: `Outputs/analysis_corrected_part2.R`
```
HEADER
# Reset memory before resuming — fresh load, no accumulated state
rm(list = setdiff(ls(), c("seurat_obj"))); gc()

[every task block from the CRASHING task through the END]
cat("Part 2 complete\n")
```

**Key rule:** every task in the original script must appear in EITHER part 1
OR part 2, never both, never neither. The crashing task itself goes into
part 2 (so the fix below applies to it).

---

## Patching the crashing task

A clean split alone often isn't enough — the task that crashed will probably
crash again unless its memory pattern is fixed. Apply the most relevant of
these patches to the crashing task before placing it in part 2:

### Pattern: DE result kept too long

If a DE variable like `result_4_1_c` is held in memory while a downstream RAM-heavy
task runs, the heap doubles up. Add an explicit `rm()` immediately before
the crashing task:

```r
# Free DE result before the heavy task
if (exists("result_4_1_c")) { rm(result_4_1_c); gc() }
```

Even better: in part 1's last successful task, add `rm(result_4_1_c); gc()` at
the very end so part 2 starts clean.

### Pattern: subset() inside a loop without rm

Each `subset(seurat_obj, condition == X)` makes a new full-sized Seurat object
that R doesn't reclaim until the next gc(). Inside loops, force collection:

```r
for (val in values) {
  sub_obj <- subset(seurat_obj, condition == val)
  .tmp <- some_function(seurat_obj = sub_obj, ...)
  ggsave(...); print(.tmp$stats)
  rm(.tmp, sub_obj); gc()           # ← critical
}
```

### Pattern: collecting full result objects in a loop

Replace "store every result" with "store summary stats only":

```r
# WRONG — accumulates ~loop_size full result objects:
all_results <- list()
for (gene in genes) {
  all_results[[gene]] <- correlate_celltype_features(...)
}

# RIGHT — only the rho and p-value survive each iteration:
corr_summary <- data.frame(gene = character(), rho = numeric(), pval = numeric())
for (gene in genes) {
  .tmp <- correlate_celltype_features(...)
  ggsave(...)
  corr_summary <- rbind(corr_summary, data.frame(
    gene = gene, rho = .tmp$correlation$estimate, pval = .tmp$correlation$p.value
  ))
  rm(.tmp); gc()
}
```

### Pattern: dense matrix operations on the full assay

`as.matrix(GetAssayData(...))` on a full Seurat object can blow up memory.
Restrict to the genes / cells you actually need before densifying:

```r
# WRONG — densifies entire ~20k x 50k matrix
mat <- as.matrix(GetAssayData(seurat_obj, slot = "data"))

# RIGHT — densify only the slice you need
target_cells <- WhichCells(seurat_obj, expression = celltype == "Tumor")
mat <- as.matrix(GetAssayData(seurat_obj, slot = "data")[target_genes, target_cells])
```

---

## Three-way split (rare)

If part 2 also crashes after splitting once, repeat the procedure on
`analysis_corrected_part2.R`, producing `_part2a.R` and `_part2b.R`.
Rename so the final set is `_part1.R`, `_part2.R`, `_part3.R`.

Stop after 3 parts. Beyond that, the crashes signal a structural problem
(e.g. plan2 asks for too many DE comparisons on too-large groups for the
machine) and the fix belongs upstream, not in this agent.

---

## Logging splits in correction_record.txt

A split correction should look like:

```
=== Correction #2 ===
Script:    Outputs/analysis.R
Trigger:   Working/analysis.log — "cannot allocate vector of size 12.4 Gb"
Category:  3 (RAM)
Error:     R process killed mid-Task 5.2.d (looped MYC vs MAPK correlations)

Diagnosis: Task 5.2.d ran 14 correlate_celltype_features calls and accumulated
           the full result objects in `all_results`. Memory grew monotonically
           and the OS killed the process around iteration 9.

Fix:       Split into:
           - Outputs/analysis_corrected_part1.R: Tasks 4.1.a → 5.2.c (last success)
           - Outputs/analysis_corrected_part2.R: Task 5.2.d → end
           Plus refactored Task 5.2.d to keep only summary stats per loop
           iteration (corr_summary data.frame), not the full result objects.

Result:    PASS — both parts complete without OOM.
```
