library(Seurat)
library(ggplot2)
library(dplyr)
library(tidyverse)
library(org.Hs.eg.db)

# Function 1: Add pathway module score, you will get instruction for the task plan about which genes to use to add module score
# pathway_genes are a list of genes that the pathway is defined by. 
# pathway_name is how you want to name the pathway score column. If you name it is A, then the column name will be A_score1. 

add_pathway_score <- function(seurat_obj, pathway_genes, pathway_name) {
  
  # Take genes that exist in seurat object
  available_genes <- intersect(pathway_genes, rownames(seurat_obj))
  
  if(length(available_genes) == 0) {
    stop("No genes from pathway found in Seurat object")
  }
  
  cat("Using", length(available_genes), "out of", length(pathway_genes), "genes for", pathway_name, "\n")
  cat("Available genes:", paste(available_genes, collapse = ", "), "\n")
  
  # Add module score (note: result column will be pathway_name + "1")
  seurat_obj <- AddModuleScore(
    object = seurat_obj,
    features = list(available_genes),
    name = paste0(pathway_name, "_score")
  )
  
  score_column <- paste0(pathway_name, "_score1")
  cat("Module score added as column:", score_column, "\n")
  
  return(seurat_obj)
}

# Add new grouping column based on some criteria from other columns/info. 
# For example, if you want to group samples into XX-high and XX-low based on XX's avg expression on cell A across samples, then, you can. 
# Function2: Create gene based groups based on the avg expression of a gene on a cell type across samples, you will get instruction for the task plan about which gene to use to create the groups. 
create_gene_based_groups <- function(seurat_obj, 
                                     gene_name,
                                     celltype_column = "detail_cluster",
                                     sample_column = "Sample",
                                     target_celltype = "Glioma") {
  
  # --- NEW: branch on whether gene_name is a gene or a metadata column ---
  if (gene_name %in% rownames(seurat_obj)) {
    gene_exp <- GetAssayData(seurat_obj, layer = "data")[gene_name, ]
  } else if (gene_name %in% colnames(seurat_obj@meta.data)) {
    gene_exp <- seurat_obj@meta.data[[gene_name]]
    if (!is.numeric(gene_exp)) {
      stop(sprintf("Metadata column '%s' is not numeric; cannot compute group means.",
                   gene_name))
    }
  } else {
    stop(sprintf("'%s' not found in assay rownames or @meta.data columns.", gene_name))
  }
  # ----------------------------------------------------------------------
  
  # Add expression/score to metadata temporarily
  seurat_obj@meta.data$temp_gene_exp <- gene_exp
  
  # Per-sample mean within the target cell type
  sample_data <- seurat_obj@meta.data %>%
    filter(!!sym(celltype_column) == target_celltype) %>%
    group_by(!!sym(sample_column)) %>%
    summarise(avg_gene_exp = mean(temp_gene_exp, na.rm = TRUE),
              .groups = "drop")
  
  sample_data <- sample_data[complete.cases(sample_data), ]
  
  threshold <- median(sample_data$avg_gene_exp, na.rm = TRUE)
  
  sample_data <- sample_data %>%
    mutate(gene_group = ifelse(avg_gene_exp > threshold,
                               paste0(gene_name, "_high"),
                               paste0(gene_name, "_low")))
  
  group_col_name <- paste0(gene_name, "_group")
  seurat_obj@meta.data[[group_col_name]] <- sample_data$gene_group[
    match(seurat_obj@meta.data[[sample_column]], sample_data[[sample_column]])
  ]
  
  seurat_obj@meta.data$temp_gene_exp <- NULL
  
  return(seurat_obj)
}

# Function3: Pull out gene list from the GO term. 
pull_out_gene_list_from_GO <- function(GO_term) {
  genes <- AnnotationDbi::select(org.Hs.eg.db, 
                                 keys = GO_term,
                                 columns = "SYMBOL",
                                 keytype = "GO")
  gene_symbols <- unique(na.omit(genes$SYMBOL))
  return(gene_symbols)
}

# Function 4: Add extra metadata from an external CSV file to a Seurat object
# annot_path is the path to the CSV file containing the extra annotations.
# The CSV should have cell barcodes as row names (first column) and metadata columns to add.
# Row order does not need to match the Seurat object - matching is done by cell barcode.

add_extra_meta <- function(seurat_obj, annot_path) {
  
  # Check file exists
  if(!file.exists(annot_path)) {
    stop("Annotation file not found: ", annot_path)
  }
  
  # Read annotation file
  annot <- read.csv(annot_path, row.names = 1)
  
  cat("Loaded annotation file with", nrow(annot), "rows and", ncol(annot), "columns\n")
  cat("Columns to add:", paste(colnames(annot), collapse = ", "), "\n")
  
  # Check barcode overlap
  n_matched <- sum(rownames(annot) %in% colnames(seurat_obj))
  n_cells <- ncol(seurat_obj)
  
  cat("Matched", n_matched, "out of", n_cells, "cells in Seurat object\n")
  
  if(n_matched == 0) {
    stop("No matching cell barcodes between annotation file and Seurat object. Check that row names are valid cell barcodes.")
  }
  
  if(n_matched < n_cells) {
    cat("Warning:", n_cells - n_matched, "cells will receive NA for added columns\n")
  }
  
  # Check for columns that already exist in metadata
  existing_cols <- intersect(colnames(annot), colnames(seurat_obj@meta.data))
  if(length(existing_cols) > 0) {
    cat("Warning: the following columns already exist in metadata and will be overwritten:",
        paste(existing_cols, collapse = ", "), "\n")
  }
  
  # Add metadata (AddMetaData matches by row name, order-independent)
  seurat_obj <- AddMetaData(seurat_obj, annot)
  
  cat("Added", ncol(annot), "metadata column(s) to Seurat object\n")
  
  return(seurat_obj)
}


# Function 5: Gate cells into a composite subtype defined by a mix of high/mid/low markers
# This is used when a paper defines a cell population by gating criteria
# (e.g., "KRT8+ VIM+ CDH1-low partial-EMT epithelial cells"). Do NOT force such
# a feature into a module score - subtraction/inversion/sign-flipping breaks the
# scoring assumption.
#
# Gating is done GLOBALLY: thresholds are computed across all parent cells in the
# Seurat object (no per-sample stratification), then applied cell-by-cell.
#
# Output: adds a new cell-type annotation column to @meta.data where
#   - cells outside the parent type   keep their original celltype_column value
#   - parent cells that fail the gate keep their original celltype_column value
#     (they remain labeled as the parent cell type)
#   - parent cells that pass the gate get the user-assigned member_name
#
# gene_criteria is a list of per-gene specifications, each of the form:
#   list(gene = "KRT8", direction = "high")
#   list(gene = "VIM",  direction = "mid")
#   list(gene = "CDH1", direction = "low")
# Direction must be "high", "mid", or "low".
#
# Threshold logic is PER GENE:
#   - If a gene is only used with "high"/"low" (no "mid" anywhere for that gene)
#       median split: high = x > median, low = x < median
#   - If a gene is used with "mid" anywhere in the criteria
#       quartile split: high = x > Q3, low = x < Q1, mid = Q1 <= x <= Q3
#
# member_name is the cell-type label assigned to cells passing all gates
# (e.g., "KRT8_VIM_CDH1low_Epithelial").
#
# new_column is the name of the output annotation column. If NULL, the original
# celltype_column is overwritten in place.

gate_cells_composite <- function(seurat_obj,
                                 gene_criteria,
                                 celltype_column = "detail_cluster",
                                 parent_celltype = "Macrophages",
                                 member_name = "CompositeSubtype",
                                 new_column = NULL) {
  
  # Validate direction values
  directions <- sapply(gene_criteria, function(x) x$direction)
  if(!all(directions %in% c("high", "mid", "low"))) {
    stop("Each gene_criteria entry must have direction = 'high', 'mid', or 'low'")
  }
  
  # Check all genes exist in the Seurat object
  genes <- sapply(gene_criteria, function(x) x$gene)
  missing_genes <- setdiff(genes, rownames(seurat_obj))
  if(length(missing_genes) > 0) {
    stop("Genes not found in Seurat object: ", paste(missing_genes, collapse = ", "))
  }
  
  # Check celltype_column exists
  if(!celltype_column %in% colnames(seurat_obj@meta.data)) {
    stop("Cell type column not found: ", celltype_column)
  }
  
  # FIX 1: Check parent cell type(s) exist — vector-friendly
  available_labels <- unique(seurat_obj@meta.data[[celltype_column]])
  missing_parents <- setdiff(parent_celltype, available_labels)
  if(length(missing_parents) > 0) {
    stop("Parent cell type(s) not found in column '", celltype_column, "': ",
         paste(missing_parents, collapse = ", "))
  }
  
  # Check member_name doesn't collide with an existing cell-type label
  if(member_name %in% available_labels) {
    stop("member_name '", member_name, "' already exists in ", celltype_column,
         ". Choose a different name to avoid collision.")
  }
  
  # FIX 2: Identify parent cells using %in% (works for single OR multiple parents)
  parent_mask <- seurat_obj@meta.data[[celltype_column]] %in% parent_celltype
  parent_mask[is.na(parent_mask)] <- FALSE
  n_parent <- sum(parent_mask)
  
  # Any gene that appears in a "mid" criterion uses quartile thresholds
  genes_needing_quartile <- unique(sapply(
    gene_criteria[directions == "mid"],
    function(x) x$gene
  ))
  
  # FIX 3a: Friendly printout for one or many parents
  parent_label <- paste(parent_celltype, collapse = " + ")
  cat("Gating", length(gene_criteria), "criteria within", n_parent,
      parent_label, "cells (global)\n")
  if(length(genes_needing_quartile) > 0) {
    cat("Genes using quartile thresholds (due to 'mid'):",
        paste(genes_needing_quartile, collapse = ", "), "\n")
  }
  
  # Start membership as TRUE for all parent cells, then filter down
  membership <- parent_mask
  
  for(criterion in gene_criteria) {
    gene <- criterion$gene
    direction <- criterion$direction
    
    gene_exp <- GetAssayData(seurat_obj, layer = "data")[gene, ]
    parent_exp <- gene_exp[parent_mask]
    
    use_quartile <- gene %in% genes_needing_quartile
    
    if(use_quartile) {
      q1 <- quantile(parent_exp, 0.25, na.rm = TRUE)
      q3 <- quantile(parent_exp, 0.75, na.rm = TRUE)
      if(direction == "high") {
        pass <- gene_exp > q3
      } else if(direction == "low") {
        pass <- gene_exp < q1
      } else {
        pass <- gene_exp >= q1 & gene_exp <= q3
      }
      thr_str <- paste0("Q1=", round(q1, 4), ", Q3=", round(q3, 4))
      rule <- "quartile"
    } else {
      threshold <- median(parent_exp, na.rm = TRUE)
      if(direction == "high") {
        pass <- gene_exp > threshold
      } else {
        pass <- gene_exp <= threshold
      }
      thr_str <- paste0("median=", round(threshold, 4))
      rule <- "median"
    }
    pass[is.na(pass)] <- FALSE
    
    n_pass_in_parent <- sum(pass & parent_mask)
    cat("  ", gene, direction, "| rule =", rule, "|", thr_str,
        "|", n_pass_in_parent, "/", n_parent, "parent cells pass\n")
    
    membership <- membership & pass
  }
  
  # Summarize
  n_gated <- sum(membership)
  pct_of_parent <- round(100 * n_gated / n_parent, 2)
  cat("Final gated cells:", n_gated, "/", n_parent, "(", pct_of_parent, "% of",
      parent_label, ")\n")
  
  # Build refined column
  refined <- as.character(seurat_obj@meta.data[[celltype_column]])
  refined[membership] <- member_name
  
  if(is.null(new_column)) {
    out_col <- celltype_column
    cat("Overwriting existing column:", out_col, "\n")
  } else {
    out_col <- new_column
    cat("Refined annotation added as column:", out_col, "\n")
  }
  
  seurat_obj@meta.data[[out_col]] <- refined
  
  # FIX 3b: Final printout for one or many parents
  cat("  - cells outside [", parent_label, "]: original label kept\n", sep = "")
  cat("  - parent cells failing gate: kept as their original parent label\n")
  cat("  - parent cells passing gate: relabeled as '", member_name, "'\n", sep = "")
  
  return(seurat_obj)
}
# ============================================================================
# Function 6: add_per_sample_summary
# ----------------------------------------------------------------------------
# Compute a per-sample summary statistic from per-cell metadata, then broadcast
# it back to every cell as a new metadata column.
#
# This wraps a common preprocessing pattern that is easy to get wrong:
#   - subset to a target cell type
#   - aggregate per sample (count / percentage / mean / median / sum)
#   - join the result back to ALL cells in the Seurat object
#
# Why a function: doing this inline tempts users to write
#   seurat_obj$new_col <- sample_value_map[as.character(seurat_obj$sample_col)]
# which fails with "No cell overlap between new meta data and Seurat object"
# because Seurat's `$<-` routes through AddMetaData() and validates that the
# vector's names are cell barcodes (they're sample IDs here). This function
# writes directly to @meta.data and skips that check.
#
# Cells from samples that have NO matching cells (e.g., samples with zero
# target_celltype cells) get NA in the new column. Cells outside the target
# cell type DO receive the sample-level value of their own sample (this is
# what you usually want for "broadcast a per-sample property to all cells").
#
# Arguments
#   seurat_obj       Seurat object
#   sample_column    Column with sample IDs (e.g., "sample", "Fragment", "ID")
#   new_column       Name of the new per-cell column to create
#   summary_type     One of:
#                      "percentage" — % of <celltype_column>==<target_celltype>
#                                     cells in each sample whose
#                                     <feature_column> equals <target_value>
#                                     (denominator = cells of that target_celltype
#                                     in that sample)
#                      "count"      — count of cells matching the same criteria
#                                     as "percentage" (numerator only)
#                      "mean"       — mean of <feature_column> across cells
#                                     of <target_celltype> in each sample
#                      "median"     — median of <feature_column> across cells
#                                     of <target_celltype> in each sample
#                      "sum"        — sum of <feature_column> across cells
#                                     of <target_celltype> in each sample
#   celltype_column  Column to filter on before aggregating (NULL = use all cells)
#   target_celltype  Value(s) of celltype_column to keep (vector OK; NULL = use all cells)
#   feature_column   For "percentage"/"count": the categorical column whose
#                    value will be matched against target_value.
#                    For "mean"/"median"/"sum": the numeric column to summarize.
#                    Ignored when summary_type == "count" AND target_value is NULL
#                    (then the count is just "all cells in target_celltype per sample").
#   target_value     For "percentage"/"count": the value of feature_column that
#                    counts as a "match". Ignored for "mean"/"median"/"sum".
#
# Returns
#   seurat_obj with one new column @meta.data[[new_column]]

add_per_sample_summary <- function(seurat_obj,
                                   sample_column,
                                   new_column,
                                   summary_type   = c("percentage", "count",
                                                      "mean", "median", "sum"),
                                   celltype_column = NULL,
                                   target_celltype = NULL,
                                   feature_column  = NULL,
                                   target_value    = NULL) {

  summary_type <- match.arg(summary_type)

  # Validate columns exist
  if(!sample_column %in% colnames(seurat_obj@meta.data)) {
    stop("sample_column '", sample_column, "' not found in @meta.data")
  }
  if(!is.null(celltype_column) &&
     !celltype_column %in% colnames(seurat_obj@meta.data)) {
    stop("celltype_column '", celltype_column, "' not found in @meta.data")
  }
  if(summary_type %in% c("percentage", "count", "mean", "median", "sum") &&
     !is.null(feature_column) &&
     !feature_column %in% colnames(seurat_obj@meta.data)) {
    stop("feature_column '", feature_column, "' not found in @meta.data")
  }

  meta <- seurat_obj@meta.data

  # Optional filter to target cell type(s)
  if(!is.null(celltype_column) && !is.null(target_celltype)) {
    sub <- meta[meta[[celltype_column]] %in% target_celltype, , drop = FALSE]
    sub <- sub[!is.na(sub[[celltype_column]]), , drop = FALSE]
    cat("Filtered to ", nrow(sub), " cells (",
        paste(target_celltype, collapse = " + "),
        ") out of ", nrow(meta), "\n", sep = "")
  } else {
    sub <- meta
  }

  if(nrow(sub) == 0) {
    warning("No cells matched the target_celltype filter; ",
            "new column will be all-NA.")
    seurat_obj@meta.data[[new_column]] <- NA_real_
    return(seurat_obj)
  }

  # Compute per-sample summary
  samples <- sort(unique(meta[[sample_column]]))
  vals    <- setNames(rep(NA_real_, length(samples)), as.character(samples))

  if(summary_type %in% c("percentage", "count")) {
    if(is.null(feature_column) && is.null(target_value)) {
      # plain count of cells per sample (after celltype filter)
      tab <- table(sub[[sample_column]])
      vals[names(tab)] <- as.numeric(tab)
      if(summary_type == "percentage") {
        warning("summary_type='percentage' but no feature_column/target_value ",
                "given; falling back to count.")
      }
    } else {
      if(is.null(feature_column) || is.null(target_value)) {
        stop("summary_type='", summary_type,
             "' requires both feature_column and target_value.")
      }
      denom <- table(sub[[sample_column]])
      numer_mask <- sub[[feature_column]] %in% target_value
      numer <- table(sub[[sample_column]][numer_mask])
      # align to all samples in `denom`
      numer_aligned <- setNames(rep(0, length(denom)), names(denom))
      shared <- intersect(names(numer), names(denom))
      numer_aligned[shared] <- as.numeric(numer[shared])
      if(summary_type == "percentage") {
        v <- (numer_aligned / as.numeric(denom)) * 100
      } else {
        v <- numer_aligned
      }
      vals[names(v)] <- as.numeric(v)
    }
  } else {
    # mean / median / sum of a numeric feature
    if(is.null(feature_column)) {
      stop("summary_type='", summary_type, "' requires feature_column.")
    }
    fn <- switch(summary_type,
                 mean   = function(x) mean(x,   na.rm = TRUE),
                 median = function(x) median(x, na.rm = TRUE),
                 sum    = function(x) sum(x,    na.rm = TRUE))
    agg <- tapply(sub[[feature_column]], sub[[sample_column]], fn)
    vals[names(agg)] <- as.numeric(agg)
  }

  # Broadcast: write directly to @meta.data to bypass AddMetaData's
  # cell-barcode-name check (the names of `vals` are sample IDs, not barcodes).
  seurat_obj@meta.data[[new_column]] <-
    vals[as.character(seurat_obj@meta.data[[sample_column]])]

  cat("Added per-sample '", summary_type, "' as column '", new_column,
      "' (", sum(!is.na(vals)), " of ", length(vals), " samples have a value)\n",
      sep = "")
  cat("Per-sample summary:\n")
  print(round(vals, 4))

  return(seurat_obj)
}


# ============================================================================
# Function 7: create_groups_from_per_sample_summary
# ----------------------------------------------------------------------------
# Bin a per-sample summary into a categorical group label (e.g., "high"/"low"
# by median split) and broadcast the label to every cell.
#
# This is the natural follow-up to add_per_sample_summary() when plan2.txt
# asks for "split samples into X-high vs X-low based on a per-sample stat".
#
# By design, this wraps the same broadcast logic as add_per_sample_summary
# (direct @meta.data assignment + restore rownames after left_join) so that
# user code never has to do it inline.
#
# Arguments
#   seurat_obj       Seurat object
#   sample_column    Column with sample IDs
#   new_column       Name of the new per-cell group column to create
#   summary_type     "percentage" | "count" | "mean" | "median" | "sum"
#   celltype_column  (optional) restrict aggregation to a cell type
#   target_celltype  (optional) value(s) of celltype_column to keep
#   feature_column   numeric or categorical column, depending on summary_type
#   target_value     for "percentage"/"count": value of feature_column to count
#   split            "median" (default) or a single numeric threshold, or
#                    a length-2 numeric vector c(low_q, high_q) of quantiles
#                    in (0, 1) to define low / mid / high.
#   high_label       label for samples ABOVE the split   (default: paste0(<feature>, "_high"))
#   low_label        label for samples BELOW the split   (default: paste0(<feature>, "_low"))
#   mid_label        label for samples in between        (only used with quantile split)
#
# Returns
#   seurat_obj with one new column @meta.data[[new_column]] (character)

create_groups_from_per_sample_summary <- function(seurat_obj,
                                                  sample_column,
                                                  new_column,
                                                  summary_type    = c("percentage", "count",
                                                                      "mean", "median", "sum"),
                                                  celltype_column = NULL,
                                                  target_celltype = NULL,
                                                  feature_column  = NULL,
                                                  target_value    = NULL,
                                                  split           = "median",
                                                  high_label      = NULL,
                                                  low_label       = NULL,
                                                  mid_label       = NULL) {

  summary_type <- match.arg(summary_type)

  # Default labels: use feature_column if given, else the new_column root
  base <- if(!is.null(feature_column)) feature_column else new_column
  if(is.null(high_label)) high_label <- paste0(base, "_high")
  if(is.null(low_label))  low_label  <- paste0(base, "_low")
  if(is.null(mid_label))  mid_label  <- paste0(base, "_mid")

  # Step 1: compute per-sample summary into a hidden numeric column
  hidden_col <- paste0(".__per_sample_value_", new_column)
  seurat_obj <- add_per_sample_summary(
    seurat_obj,
    sample_column   = sample_column,
    new_column      = hidden_col,
    summary_type    = summary_type,
    celltype_column = celltype_column,
    target_celltype = target_celltype,
    feature_column  = feature_column,
    target_value    = target_value
  )

  # Step 2: collect one row per sample with its summary value
  per_sample <- unique(seurat_obj@meta.data[, c(sample_column, hidden_col), drop = FALSE])
  vals_num   <- per_sample[[hidden_col]]

  # Step 3: assign group labels
  if(identical(split, "median")) {
    thr <- median(vals_num, na.rm = TRUE)
    grp <- ifelse(is.na(vals_num), NA_character_,
                  ifelse(vals_num > thr, high_label, low_label))
    cat("Split: median =", round(thr, 4), "\n")
  } else if(is.numeric(split) && length(split) == 1) {
    grp <- ifelse(is.na(vals_num), NA_character_,
                  ifelse(vals_num >= split, high_label, low_label))
    cat("Split: fixed threshold =", split, "\n")
  } else if(is.numeric(split) && length(split) == 2 &&
            all(split > 0 & split < 1) && split[1] < split[2]) {
    lo_q <- quantile(vals_num, probs = split[1], na.rm = TRUE)
    hi_q <- quantile(vals_num, probs = split[2], na.rm = TRUE)
    grp  <- ifelse(is.na(vals_num), NA_character_,
            ifelse(vals_num >= hi_q, high_label,
            ifelse(vals_num <= lo_q, low_label, mid_label)))
    cat("Split: quantiles q",
        split[1], "=", round(lo_q, 4),
        ", q", split[2], "=", round(hi_q, 4), "\n", sep = "")
  } else {
    stop("Invalid `split`: use \"median\", a single numeric threshold, ",
         "or c(low_q, high_q) with both in (0, 1) and low_q < high_q.")
  }

  per_sample[[new_column]] <- grp

  # Step 4: broadcast the group label back to every cell.
  # Use direct @meta.data assignment (NOT seurat_obj$col <- ...) and a
  # named-vector lookup. Avoids both the AddMetaData "no cell overlap" trap
  # AND the left_join rownames-loss trap.
  group_map <- setNames(per_sample[[new_column]],
                        as.character(per_sample[[sample_column]]))
  seurat_obj@meta.data[[new_column]] <-
    group_map[as.character(seurat_obj@meta.data[[sample_column]])]

  # Clean up the hidden numeric column
  seurat_obj@meta.data[[hidden_col]] <- NULL

  cat("Group distribution in '", new_column, "':\n", sep = "")
  print(table(seurat_obj@meta.data[[new_column]], useNA = "ifany"))

  return(seurat_obj)
}
