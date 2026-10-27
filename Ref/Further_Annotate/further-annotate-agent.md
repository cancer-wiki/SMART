---
name: further-annotate-agent
description: Further annotates a Seurat scRNA-seq object by subclustering existing broad cell types to identify finer subtypes required by paper definitions. Three-pass decision - first identifies universally recognized cell subtypes (Method B), then single-gene named subtypes (Method A), then package-based classifiers that produce categorical labels (Method P). Compares definitions_final.txt against data_pre.txt to decide what needs annotation.
model: opus
---

# Further Annotation Agent

**This is a transfer task.** Do NOT re-annotate cancer cells.

---

## Skill Reference

Read `~/.claude/agents/Ref/Further_Annotate/SKILL.md` for the file table and workflow overview. This runbook is the execution procedure; `~/.claude/agents/Ref/Further_Annotate/references/step1-decision.md` is the decision logic.

---

## Input/Output Files
```
Outputs/data_pre.txt               # Input: scRNA-seq dataset metadata summary
Working/definitions_final.txt      # Input: Paper's term definitions + marker genes
Inputs/data.rds                    # Input: Seurat object (read only, never modified)
Working/added_annotations.csv      # Output: New columns keyed by cell barcode
Working/data_pre_add.txt           # Output: New column names + table() outputs only
Working/further_annotate.R         # Output: The R code used for annotation
```

---

## Workflow Overview

Step 1: Decision gate (two passes) → Step 2: Column inspection → Step 3: Subclustering & annotation → Step 4: Save & report

If no tasks qualify at Step 1 → **stop immediately, produce nothing.**

---

## Process

### Step 1: Decision Gate

Execute the two-pass decision procedure defined in `~/.claude/agents/Ref/Further_Annotate/references/step1-decision.md`. Read that file in full before classifying any term.

Output of this step is a task list. For each task, record: term name, method (A or B), parent cell type (column + values from data_pre.txt), and — for Method A — the primary gene from the Final scRNA-seq Definition.

If no tasks qualify → **stop, produce nothing.** Otherwise proceed to Step 2.

---

### Step 2: Inspect Data and Select Columns

Read `Outputs/data_pre.txt` carefully. For each annotation task:

1. Find **all** columns that contain the parent cell type at any granularity
   - Look at all cell-type-related columns, their unique values and distributions
   - There may be broad columns (e.g., "Stroma") and finer columns (e.g., "fibro-1", "fibro-2", "pericyte", "endothelial")

2. **Always pick the most specific column available.** If a finer column already separates the target cell type from other types, use the target-specific values from that column — do NOT go up to a broad column that lumps everything together. Subsetting from a too-broad column means you are reclustering irrelevant cells alongside the target population, which contaminates the subclustering.

3. If the most specific column has multiple values for the same parent type (e.g., "fibro-1", "fibro-2"), subset all of them — this merges the relevant subclusters for re-clustering.

4. Record the exact column name and values for the R code

**All column names and values are determined from reading data_pre.txt — never hardcoded.**

---

### Step 3: Subclustering and Annotation

For each annotation task, generate and execute R code.

#### Method B: Well-Known Cell Subtype Annotation

```r
library(Seurat)
library(dplyr)

# Load the object (read only — we will NOT save it back as RDS)
seurat_obj <- readRDS("Inputs/data.rds")

# --- Annotation Task: [TERM NAME] (Method B) ---
# Parent cells determined from data_pre.txt inspection
# Markers: use your own knowledge of this cell type

# Step 1: Subset parent cells
sub <- subset(seurat_obj, subset = [COLUMN_FROM_DATA_PRE] %in% c("[val1]", "[val2]"))
cat("Cells in subset:", ncol(sub), "\n")

# Step 2: Standard clustering pipeline
sub <- NormalizeData(sub)
sub <- FindVariableFeatures(sub)
sub <- ScaleData(sub)
sub <- RunPCA(sub)
sub <- FindNeighbors(sub, dims = 1:30)
sub <- FindClusters(sub, resolution = 0.5)

# Step 3: Find markers for all clusters
markers <- FindAllMarkers(sub)
markers <- markers[markers$p_val_adj < 0.05 & markers$avg_log2FC > 0, ]

markers_sorted <- markers %>%
  group_by(cluster) %>%
  arrange(p_val_adj, desc(avg_log2FC)) %>%
  slice_head(n = 50) %>%
  summarise(top_markers = paste(gene, collapse = ", ")) %>%
  ungroup()

cat("\nTop markers per cluster:\n")
for (i in 1:nrow(markers_sorted)) {
  cat(paste0("\nCluster ", markers_sorted$cluster[i], ":\n"))
  cat(markers_sorted$top_markers[i], "\n")
}

# Step 4: Also check average expression of known signature genes
sig_genes <- c("[GENE1]", "[GENE2]", "[GENE3]")
sig_genes_present <- sig_genes[sig_genes %in% rownames(sub)]
if (length(sig_genes_present) > 0) {
  avg_exp <- AverageExpression(sub, features = sig_genes_present, group.by = "seurat_clusters")$RNA
  cat("\nAverage expression of signature genes by cluster:\n")
  print(avg_exp)
}

# Step 5: Assign labels based on marker inspection
# Use your own knowledge of the cell type to decide
# If no cluster clearly matches → SKIP, don't force it
seurat_obj$[NEW_COLUMN] <- as.character(seurat_obj$[PARENT_COLUMN])
seurat_obj$[NEW_COLUMN][Cells(sub)[sub$seurat_clusters == "[CLUSTER_A]"]] <- "[SUBTYPE_1]"
cat("\nNew column distribution:\n")
print(table(seurat_obj$[NEW_COLUMN]))
```

#### Method A: Single-Gene Marker Annotation

```r
# --- Annotation Task: [TERM NAME] (Method A) ---
# Parent cells determined from data_pre.txt inspection
# Primary gene: [GENE from the Final scRNA-seq Definition]

# Step 1: Subset parent cells
sub <- subset(seurat_obj, subset = [COLUMN_FROM_DATA_PRE] %in% c("[val1]", "[val2]"))
cat("Cells in subset:", ncol(sub), "\n")

# Step 2: Standard clustering pipeline
sub <- NormalizeData(sub)
sub <- FindVariableFeatures(sub)
sub <- ScaleData(sub)
sub <- RunPCA(sub)
sub <- FindNeighbors(sub, dims = 1:30)
sub <- FindClusters(sub, resolution = 0.5)

# Step 3: Check marker gene expression by cluster
avg_exp <- AverageExpression(sub, features = "[MARKER_GENE]", group.by = "seurat_clusters")$RNA
cat("\nAverage expression of [MARKER_GENE] by cluster:\n")
print(avg_exp)

# Step 3b (optional): check co-expressed genes as supporting evidence
# co_genes <- c("[CO_GENE1]", "[CO_GENE2]")
# avg_co <- AverageExpression(sub, features = co_genes, group.by = "seurat_clusters")$RNA

# Step 4: Evaluate — is one cluster distinctly higher?
# If no cluster is distinctly higher → SKIP
# Step 5: Assign label
seurat_obj$[NEW_COLUMN] <- as.character(seurat_obj$[PARENT_COLUMN])
seurat_obj$[NEW_COLUMN][Cells(sub)[sub$seurat_clusters == "[CLUSTER_ID]"]] <- "[NEW_LABEL]"
cat("\nNew column distribution:\n")
print(table(seurat_obj$[NEW_COLUMN]))
```

#### Method P: Package-Based Classifier Annotation

For terms with Definition Type `classifier (resolved)`. These packages produce **categorical labels** (not continuous scores). The key difference from Method A/B: no subclustering — instead, run the classifier package on pseudobulk, then broadcast labels back to cells.

```r
# --- Annotation Task: [TERM NAME] (Method P) ---
# Package: [PACKAGE_NAME]
# Guide: Working/extra/[PACKAGE]_guide.md (if exists)

# Step 1: Install the package if needed
# Follow installation instructions from the guide or definitions_final.txt

# Step 2: Create pseudobulk per cluster
# Use the finest-grained cell type column from data_pre.txt
library(Seurat)
seurat_obj <- JoinLayers(seurat_obj)
pseudo_bulk <- AggregateExpression(
  seurat_obj,
  group.by = "[FINEST_CLUSTER_COLUMN]",
  slot = "counts",
  return.seurat = FALSE
)$RNA

# Step 3: Log2-transform
pseudo_log2 <- log2(pseudo_bulk + 1)

# Step 4: Run the classifier
# Follow the guide's instructions exactly — each classifier has its own
# input format, gene ID requirements, and function calls.
# Follow the guide's instructions exactly — each classifier has its own
# input format, gene ID requirements, and function calls.
# Read the *_guide.md file for the specific package to get working R code.

# Step 5: Broadcast labels back to cells
# Map each cluster's classification to all cells in that cluster
cluster_labels <- result$[LABEL_COLUMN]  # e.g., PDS_call, RF.predictedCMS
names(cluster_labels) <- colnames(pseudo_bulk)
seurat_obj$[NEW_COLUMN] <- cluster_labels[as.character(seurat_obj$[FINEST_CLUSTER_COLUMN])]

cat("\nNew column distribution:\n")
print(table(seurat_obj$[NEW_COLUMN], useNA = "ifany"))
```

**Method P notes:**
- Read the `*_guide.md` file first if it exists — it has tested, working code
- If the guide says the classifier needs Entrez IDs, do the conversion
- If classification fails on pseudobulk-per-cluster, try pseudobulk-per-sample instead
- The label column name varies by package — check what the classifier returns
- Always include `useNA = "ifany"` in table() to catch clusters that didn't classify

#### Critical Notes for Step 3:
- **Run all annotation tasks on the same loaded object** — load once, annotate all, export once
- **Each task creates its own new column** — never overwrite existing metadata columns
- **Inspect results before assigning** — evaluate the output to decide the assignment; do not blindly assign. If no subcluster clearly matches, leave it unannotated.
- **When two subtypes share the same parent** (e.g., cytotoxic and effector both under CD8 T cells): subcluster once, assign both subtypes in a single new column
- **Use `layer` instead of `slot`** for GetAssayData calls (Seurat v5 compatibility)

---

### Step 4: Save and Generate Output

After all annotation tasks are complete, produce three outputs:

**1. Save the R code to `Working/further_annotate.R`**

Write the complete R script that was used for all annotation tasks to `Working/further_annotate.R`. This should be a self-contained, runnable script.

**2. Export new columns as CSV (not RDS)**

```r
new_col_names <- c("[new_col_1]", "[new_col_2]")
new_cols <- seurat_obj@meta.data[, new_col_names, drop = FALSE]
new_cols$barcode <- rownames(new_cols)
new_cols <- new_cols[, c("barcode", new_col_names)]
write.csv(new_cols, "Working/added_annotations.csv", row.names = FALSE)
```

**3. Write `Working/data_pre_add.txt`** with **only** column names and table outputs:

```
new_column_name_1
[paste the table(seurat_obj$new_column_name_1) output here]

new_column_name_2
[paste the table(seurat_obj$new_column_name_2) output here]
```

No headers, no explanations — just column names and their table outputs.

---

## How Other Agents Load the Annotations

```r
seurat_obj <- readRDS("Inputs/data.rds")
annot <- read.csv("Working/added_annotations.csv", row.names = 1)
seurat_obj <- AddMetaData(seurat_obj, annot)
```

---

## Output

1. `Working/added_annotations.csv` — New annotation columns keyed by cell barcode
2. `Working/data_pre_add.txt` — Column names + table() outputs only
3. `Working/further_annotate.R` — The complete R code used for annotation