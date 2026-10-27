#' Correlate Any Two Features Between Cell Types
#'
#' @description
#' This function correlates ANY two features between two cell types across samples.
#' 
#' **SIMPLE MENTAL MODEL:**
#' - Pick two cell types (A and B)
#' - For each cell type, pick ONE feature: gene expression, a metadata score, or cell percentage
#' - The function correlates these two features across all samples
#' 
#' **WHEN TO USE THIS FUNCTION:**
#' Use this function when you want to answer questions like:
#' - "Does gene X in cell type A correlate with gene Y in cell type B?"
#' - "Does gene X in cell type A correlate with the percentage of cell type B?"
#' - "Does a signature score in cell type A correlate with a signature score in cell type B?"
#' - "Do the percentages of two cell types correlate with each other?"
#' 
#' **WHEN NOT TO USE THIS FUNCTION:**
#' Do NOT use this for:
#' - Comparing groups (e.g., treatment vs control) -> use compare_gene_expression()
#' - Differential expression analysis -> use run_de_analysis()
#' - Testing if a value differs between conditions -> use wilcox.test() or t.test()
#'
#' @param seurat_obj Seurat object with your single-cell data
#' @param celltype_A Name of the first cell type (as it appears in celltype_A_col)
#' @param celltype_B Name of the second cell type (as it appears in celltype_B_col)
#' @param feature_A_type What to measure for cell type A: "gene", "metadata", or "percentage"
#' @param feature_B_type What to measure for cell type B: "gene", "metadata", or "percentage"
#' @param feature_A_name Name of the feature for cell type A (gene name or metadata column), or NULL if percentage
#' @param feature_B_name Name of the feature for cell type B (gene name or metadata column), or NULL if percentage
#' @param sample_col Metadata column that identifies unique samples
#' @param condition_col Metadata column for experimental conditions
#' @param celltype_A_col Metadata column containing cell type A annotations
#' @param celltype_B_col Metadata column containing cell type B annotations
#' @param percentage_mode_A "total" or "broad"
#' @param percentage_mode_B "total" or "broad"
#' @param broad_cell_A The broader category that contains cell type A
#' @param broad_cell_B The broader category that contains cell type B
#' @param broad_cell_col Metadata column with broader cell categories
#' @param custom_colors Named vector of colors for conditions. If NULL, uses ggplot2 default colors.
#'
#' @return A list with:
#'   - **plot**: Scatter plot showing the correlation
#'   - **correlation**: Overall correlation test results (all samples combined)
#'   - **correlation_by_condition**: Correlation results split by condition
#'   - **data**: The underlying data frame used for correlation
#'
#' @export

correlate_celltype_features <- function(seurat_obj, 
                                        celltype_A, 
                                        celltype_B, 
                                        feature_A_type = c("gene", "metadata", "percentage"),
                                        feature_B_type = c("gene", "metadata", "percentage"),
                                        feature_A_name = NULL,
                                        feature_B_name = NULL,
                                        sample_col, 
                                        condition_col, 
                                        celltype_A_col, 
                                        celltype_B_col,
                                        percentage_mode_A = "total",
                                        percentage_mode_B = "total",
                                        broad_cell_A = NULL,
                                        broad_cell_B = NULL,
                                        broad_cell_col = NULL,
                                        custom_colors = NULL) {
  
  # Validate inputs
  feature_A_type <- match.arg(feature_A_type)
  feature_B_type <- match.arg(feature_B_type)
  
  # Check that feature names are provided when needed
  if (feature_A_type != "percentage" && is.null(feature_A_name)) {
    stop("feature_A_name must be provided when feature_A_type is 'gene' or 'metadata'")
  }
  if (feature_B_type != "percentage" && is.null(feature_B_name)) {
    stop("feature_B_name must be provided when feature_B_type is 'gene' or 'metadata'")
  }
  
  # ============================================================================
  # HELPER FUNCTION: Extract feature values for a cell type
  # ============================================================================
  extract_feature <- function(seurat_obj, celltype, celltype_col, feature_type, 
                              feature_name, sample_col, percentage_mode, 
                              broad_cell, broad_cell_col) {
    
    # Get cells of this cell type (across all samples, ignoring broad category)
    cells <- seurat_obj@meta.data[[celltype_col]] %in% celltype
    cells[is.na(cells)] <- FALSE
    
    if (feature_type == "gene") {
      gene_expr <- GetAssayData(seurat_obj, layer = "data")[feature_name, cells]
      sample_ids <- seurat_obj@meta.data[[sample_col]][cells]
      feature_values <- tapply(gene_expr, sample_ids, mean)
      feature_label <- paste0(feature_name, " avg exp (", paste(celltype, collapse="+"), ")")
      
    } else if (feature_type == "metadata") {
      if (!feature_name %in% colnames(seurat_obj@meta.data)) {
        stop(paste("Metadata column", feature_name, "not found in Seurat object"))
      }
      metadata_values <- seurat_obj@meta.data[[feature_name]][cells]
      sample_ids <- seurat_obj@meta.data[[sample_col]][cells]
      feature_values <- tapply(metadata_values, sample_ids, mean, na.rm = TRUE)
      feature_label <- paste0(feature_name, " avg score (", paste(celltype, collapse="+"), ")")
      
    } else if (feature_type == "percentage") {
      # Fix: for percentage_mode == "broad", the numerator must be cells that
      # are BOTH the requested celltype AND inside the broad category.
      # Otherwise we count e.g. G2M cells across all cell types instead of
      # G2M cells within Glioma, which is not what "%G2M within Glioma" means.
      
      if (percentage_mode == "total") {
        # Denominator: all cells per sample
        total_per_sample <- table(seurat_obj@meta.data[[sample_col]])
        numerator_mask <- cells
      } else if (percentage_mode == "broad" && !is.null(broad_cell) && !is.null(broad_cell_col)) {
        # Denominator: cells in the broad category, per sample
        broad_cells <- seurat_obj@meta.data[[broad_cell_col]] %in% broad_cell
        broad_cells[is.na(broad_cells)] <- FALSE
        total_per_sample <- table(seurat_obj@meta.data[[sample_col]][broad_cells])
        # Numerator: cells in this celltype AND in the broad category
        numerator_mask <- cells & broad_cells
      } else {
        stop("For 'broad' percentage_mode, both broad_cell and broad_cell_col must be provided")
      }
      
      celltype_per_sample <- table(seurat_obj@meta.data[[sample_col]][numerator_mask])
      
      # Build a numerator vector aligned to the SAMPLES in total_per_sample.
      # Samples with 0 numerator cells stay at 0.
      all_samples <- names(total_per_sample)
      celltype_counts <- setNames(rep(0, length(all_samples)), all_samples)
      shared <- intersect(names(celltype_per_sample), all_samples)
      celltype_counts[shared] <- as.numeric(celltype_per_sample[shared])
      
      # Align division by name (not position).
      total_vec <- setNames(as.numeric(total_per_sample), names(total_per_sample))
      feature_values <- (celltype_counts / total_vec[all_samples]) * 100
      names(feature_values) <- all_samples
      
      if (percentage_mode == "total") {
        feature_label <- paste0(paste(celltype, collapse="+"), " % (total)")
      } else {
        feature_label <- paste0(paste(celltype, collapse="+"), " % (within ", broad_cell, ")")
      }
    }
    
    return(list(values = feature_values, label = feature_label))
  }
  
  # ============================================================================
  # 1. Extract features for both cell types
  # ============================================================================
  feature_A <- extract_feature(seurat_obj, celltype_A, celltype_A_col, feature_A_type, 
                               feature_A_name, sample_col, percentage_mode_A, 
                               broad_cell_A, broad_cell_col)
  
  feature_B <- extract_feature(seurat_obj, celltype_B, celltype_B_col, feature_B_type, 
                               feature_B_name, sample_col, percentage_mode_B, 
                               broad_cell_B, broad_cell_col)
  
  # ============================================================================
  # 2. Get condition for each sample
  # ============================================================================
  sample_condition <- unique(seurat_obj@meta.data[, c(sample_col, condition_col)])
  rownames(sample_condition) <- sample_condition[[sample_col]]
  
  # ============================================================================
  # 3. Create data frame with matched samples
  # ============================================================================
  samples <- intersect(names(feature_A$values), names(feature_B$values))
  
  if (length(samples) == 0) {
    stop("No overlapping samples found between the two cell types")
  }
  
  plot_df <- data.frame(
    Sample = samples,
    Feature_A = as.numeric(feature_A$values[samples]),
    Feature_B = as.numeric(feature_B$values[samples]),
    Condition = sample_condition[samples, condition_col]
  )
  
  plot_df <- plot_df[complete.cases(plot_df), ]
  
  if (nrow(plot_df) < 3) {
    stop("Insufficient samples (< 3) for correlation analysis after removing NAs")
  }
  
  # ============================================================================
  # 4. Calculate correlation - OVERALL
  # ============================================================================
  cor_result_all <- cor.test(plot_df$Feature_A, plot_df$Feature_B)
  
  # ============================================================================
  # 5. Calculate correlation - BY CONDITION
  # ============================================================================
  conditions <- unique(plot_df$Condition)
  cor_by_condition <- list()
  
  for (cond in conditions) {
    subset_df <- plot_df[plot_df$Condition == cond, ]
    if (nrow(subset_df) >= 3) {
      cor_by_condition[[cond]] <- cor.test(subset_df$Feature_A, subset_df$Feature_B)
    } else {
      cor_by_condition[[cond]] <- list(estimate = NA, p.value = NA, 
                                       message = "Insufficient samples for correlation")
    }
  }
  
  # ============================================================================
  # 6. Create title with all correlations
  # ============================================================================
  title_text <- paste("Correlation:", feature_A$label, "vs", feature_B$label)
  title_text <- paste0(title_text, "\nOverall: r = ", round(cor_result_all$estimate, 3),
                       ", p = ", format.pval(cor_result_all$p.value, digits = 3))
  
  for (cond in names(cor_by_condition)) {
    if (!is.na(cor_by_condition[[cond]]$estimate)) {
      title_text <- paste0(title_text, "\n", cond, ": r = ", 
                           round(cor_by_condition[[cond]]$estimate, 3),
                           ", p = ", format.pval(cor_by_condition[[cond]]$p.value, digits = 3))
    }
  }
  
  # ============================================================================
  # 7. Plot
  # ============================================================================
  library(ggplot2)
  p <- ggplot(plot_df, aes(x = Feature_A, y = Feature_B, color = Condition, label = Sample)) +
    geom_point(size = 3) +
    geom_text(vjust = -0.5, size = 3) +
    geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "solid") +
    labs(x = feature_A$label,
         y = feature_B$label,
         title = title_text) +
    theme_bw() +
    theme(plot.title = element_text(size = 10))
  
  if (!is.null(custom_colors)) {
    p <- p + scale_color_manual(values = custom_colors)
  }
  
  # ============================================================================
  # 8. Print correlation results
  # ============================================================================
  cat("\n=== Correlation Results ===\n")
  cat("\nFeature A:", feature_A$label, "\n")
  cat("Feature B:", feature_B$label, "\n")
  cat("\nOverall (all samples):\n")
  cat("  r =", round(cor_result_all$estimate, 3), ", p =", round(cor_result_all$p.value, 4), "\n")
  
  cat("\nBy Condition:\n")
  for (cond in names(cor_by_condition)) {
    if (is.na(cor_by_condition[[cond]]$estimate)) {
      cat(" ", cond, ": Insufficient samples\n")
    } else {
      cat(" ", cond, ": r =", round(cor_by_condition[[cond]]$estimate, 3),
          ", p =", round(cor_by_condition[[cond]]$p.value, 4), "\n")
    }
  }
  
  # ============================================================================
  # 9. Return results
  # ============================================================================
  return(list(plot = p, 
              correlation = cor_result_all, 
              correlation_by_condition = cor_by_condition,
              data = plot_df))
}


#' Compare Features Across Groups (Sample-Level Only)
#'
#' @description
#' Creates boxplots comparing gene expression or metadata features across groups.
#' Always aggregates to sample level (one dot per sample per group).
#' Performs pairwise Wilcoxon tests between all groups.
#'
#' @param seurat_obj Seurat object
#' @param value_type "gene" or "metadata"
#' @param value_name Gene symbol or metadata column name
#' @param group_col Column defining groups to compare
#' @param celltype Specific cell type to analyze (NULL = all cells)
#' @param celltype_col Column containing cell type annotations
#' @param sample_col Column identifying unique samples
#' @param plot_type "both" (default), "violin", or "boxplot"
#' @param add_points Show individual points. Default: TRUE
#' @param point_size Size of points. Default: 2
#' @param custom_colors Named vector of colors for groups.
#'
#' @return List with plot, test (for 2 groups), pairwise_tests, data, summary_stats
#'
#' @export

compare_features_boxplot <- function(seurat_obj,
                                     value_type = c("gene", "metadata"),
                                     value_name,
                                     group_col,
                                     celltype = NULL,
                                     celltype_col = NULL,
                                     sample_col,
                                     plot_type = c("both", "violin", "boxplot"),
                                     add_points = TRUE,
                                     point_size = 2,
                                     custom_colors = NULL) {
  
  value_type <- match.arg(value_type)
  plot_type <- match.arg(plot_type)
  
  if (!is.null(celltype) && is.null(celltype_col)) {
    stop("celltype_col must be provided when celltype is specified")
  }
  
  # ============================================================================
  # 1. Filter to specific cell type if requested
  # ============================================================================
  if (!is.null(celltype)) {
    cells_subset <- seurat_obj@meta.data[[celltype_col]] %in% celltype
    cat("Filtering to cell type:", celltype, "(", sum(cells_subset), "cells )\n")
  } else {
    cells_subset <- rep(TRUE, ncol(seurat_obj))
    cat("Using all cells (", sum(cells_subset), "cells )\n")
  }
  
  # ============================================================================
  # 2. Extract values based on value_type
  # ============================================================================
  if (value_type == "gene") {
    if (!value_name %in% rownames(seurat_obj)) {
      stop(paste("Gene", value_name, "not found in Seurat object"))
    }
    values <- GetAssayData(seurat_obj, layer = "data")[value_name, cells_subset]
    value_label <- paste(value_name, "expression")
    
  } else if (value_type == "metadata") {
    if (!value_name %in% colnames(seurat_obj@meta.data)) {
      stop(paste("Metadata column", value_name, "not found in Seurat object"))
    }
    values <- seurat_obj@meta.data[[value_name]][cells_subset]
    value_label <- value_name
  }
  
  # ============================================================================
  # 3. Get sample and group information
  # ============================================================================
  samples <- seurat_obj@meta.data[[sample_col]][cells_subset]
  groups <- seurat_obj@meta.data[[group_col]][cells_subset]
  
  # ============================================================================
  # 4. Aggregate to sample level
  # ============================================================================
  use_combo <- (is.null(celltype) && !is.null(celltype_col) && group_col == celltype_col)
  if (!use_combo) {
    sample_group_check <- unique(paste(samples, groups, sep = "___"))
    samples_check <- sapply(strsplit(sample_group_check, "___"), `[`, 1)
    if (any(duplicated(samples_check))) {
      use_combo <- TRUE
    }
  }

  if (use_combo) {
    sample_group_combo <- paste(samples, groups, sep = "___")
    value_avg <- tapply(values, sample_group_combo, mean, na.rm = TRUE)
    combo_names <- names(value_avg)
    sample_names <- sapply(strsplit(combo_names, "___"), `[`, 1)
    group_names <- sapply(strsplit(combo_names, "___"), `[`, 2)
    
    plot_data <- data.frame(
      Sample = sample_names,
      Value = as.numeric(value_avg),
      Group = group_names,
      stringsAsFactors = FALSE
    )
    
  } else {
    value_avg <- tapply(values, samples, mean, na.rm = TRUE)
    
    sample_group_df <- unique(data.frame(
      Sample = samples,
      Group = groups,
      stringsAsFactors = FALSE
    ))
    sample_group_df <- sample_group_df[!duplicated(sample_group_df$Sample), ]
    group_lookup <- setNames(sample_group_df$Group, sample_group_df$Sample)
    
    plot_data <- data.frame(
      Sample = names(value_avg),
      Value = as.numeric(value_avg),
      Group = group_lookup[names(value_avg)],
      stringsAsFactors = FALSE
    )
  }
  
  plot_data <- plot_data[complete.cases(plot_data), ]
  
  if (nrow(plot_data) < 3) {
    stop("Insufficient data points (< 3) for comparison after removing NAs")
  }
  
  # ============================================================================
  # 5. Summary statistics
  # ============================================================================
  library(dplyr)
  
  summary_stats <- plot_data %>%
    group_by(Group) %>%
    summarise(
      n = n(),
      mean = mean(Value, na.rm = TRUE),
      median = median(Value, na.rm = TRUE),
      sd = sd(Value, na.rm = TRUE),
      se = sd / sqrt(n),
      .groups = 'drop'
    )
  
  cat("\n=== Summary Statistics ===\n")
  print(summary_stats)
  
  # ============================================================================
  # 6. Pairwise Wilcoxon tests
  # ============================================================================
  groups_unique <- unique(plot_data$Group)
  n_groups <- length(groups_unique)
  
  pairwise_tests <- data.frame()
  
  for (i in 1:(n_groups - 1)) {
    for (j in (i + 1):n_groups) {
      group1 <- groups_unique[i]
      group2 <- groups_unique[j]
      subset_data <- plot_data[plot_data$Group %in% c(group1, group2), ]
      test_result <- wilcox.test(Value ~ Group, data = subset_data)
      pairwise_tests <- rbind(pairwise_tests, data.frame(
        Group1 = group1,
        Group2 = group2,
        P_value = test_result$p.value,
        Statistic = test_result$statistic,
        stringsAsFactors = FALSE
      ))
    }
  }
  
  cat("\n=== Pairwise Wilcoxon Tests ===\n")
  print(pairwise_tests)
  
  if (n_groups == 2) {
    test_result <- wilcox.test(Value ~ Group, data = plot_data)
  } else {
    test_result <- NULL
  }
  
  # ============================================================================
  # 7. Create plot
  # ============================================================================
  library(ggplot2)
  
  p <- ggplot(plot_data, aes(x = Group, y = Value, fill = Group))
  
  if (plot_type == "violin" || plot_type == "both") {
    p <- p + geom_violin(alpha = 0.6)
  }
  if (plot_type == "boxplot" || plot_type == "both") {
    if (plot_type == "both") {
      p <- p + geom_boxplot(width = 0.2, fill = "white", outlier.shape = NA)
    } else {
      p <- p + geom_boxplot(outlier.shape = NA)
    }
  }
  
  if (add_points) {
    p <- p + geom_jitter(width = 0.1, size = point_size, alpha = 0.6)
  }
  
  if (!is.null(celltype)) {
    title_text <- paste(value_label, "in", celltype)
  } else {
    title_text <- value_label
  }
  
  if (n_groups == 2) {
    title_text <- paste0(title_text, "\nWilcoxon test: p = ", 
                         format.pval(pairwise_tests$P_value[1], digits = 3))
  } else {
    title_text <- paste0(title_text, "\n(Pairwise Wilcoxon tests - see output)")
  }
  
  title_text <- paste0(title_text, " (n=", nrow(plot_data), " samples)")
  
  p <- p +
    labs(title = title_text,
         x = group_col,
         y = paste("Average", value_label, "per sample")) +
    theme_bw() +
    theme(
      plot.title = element_text(size = 11),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  if (!is.null(custom_colors)) {
    p <- p + scale_fill_manual(values = custom_colors)
  }
  
  # ============================================================================
  # 8. Return results
  # ============================================================================
  return(list(
    plot = p,
    test = test_result,
    pairwise_tests = pairwise_tests,
    data = plot_data,
    summary_stats = summary_stats
  ))
}


#' Universal Differential Expression Analysis Function (V2)
#'
#' @description
#' Performs differential expression analysis between two conditions.
#' Uses Libra for pseudobulk DE analysis and EnhancedVolcano for visualization.
#'
#' **V2 CHANGE — Direction labeling:**
#' Libra sorts condition labels alphabetically. The FIRST condition alphabetically
#' becomes the reference. Positive avg_logFC = upregulated in the SECOND condition
#' (alphabetically later). This function now:
#' 1. Determines which condition is "up" (positive logFC) and which is "down"
#' 2. Labels the volcano plot x-axis with arrows: "← Up in [ref] | Up in [alt] →"
#' 3. Returns `up_condition` and `down_condition` in the output so downstream
#'    enrichment analysis can label results correctly
#'
#' @param seurat_obj Seurat object containing single-cell data
#' @param celltype Cell type to analyze. Set to NULL to skip cell type filtering.
#' @param celltype_col Column name containing cell type annotations
#' @param condition_col Column name containing the conditions to compare
#' @param condition1 First condition to compare
#' @param condition2 Second condition to compare
#' @param sample_col Column name containing sample IDs
#' @param title Custom title for the volcano plot (optional)
#' @param min_cells Minimum number of cells per sample. Default: 3
#' @param min_reps Minimum number of replicates per condition. Default: 2
#' @param pval_cutoff P-value cutoff. Default: 0.05
#' @param fc_cutoff Fold change cutoff. Default: 0.5
#'
#' @return List containing:
#'   - de_results: Full DE results data frame
#'   - significant_genes: Filtered significant genes
#'   - volcano_plot: EnhancedVolcano plot object
#'   - n_sig_up: Number of significantly upregulated genes
#'   - n_sig_down: Number of significantly downregulated genes
#'   - subset_obj: Subsetted Seurat object used for analysis
#'   - up_condition: The condition where positive logFC genes are upregulated
#'   - down_condition: The condition where negative logFC genes are upregulated (= reference)
#'
#' @export

run_de_analysis <- function(seurat_obj,
                            celltype,
                            celltype_col,
                            condition_col,
                            condition1,
                            condition2,
                            sample_col,
                            title = NULL,
                            min_cells = 3,
                            min_reps = 2,
                            pval_cutoff = 0.05,
                            fc_cutoff = 0.5) {
  
  library(Seurat)
  library(Libra)
  library(EnhancedVolcano)
  library(dplyr)
  
  # ============================================================================
  # 1. Determine direction convention
  # Libra sorts labels alphabetically. The FIRST alphabetically = reference.
  # Positive logFC = up in the SECOND (non-reference) condition.
  # ============================================================================
  sorted_conditions <- sort(c(condition1, condition2))
  down_condition <- sorted_conditions[1]  # reference (alphabetically first)
  up_condition   <- sorted_conditions[2]  # positive logFC = up in this one
  
  cat("\n=== Libra direction convention ===\n")
  cat("Reference (alphabetically first):", down_condition, "\n")
  cat("Positive logFC = upregulated in:", up_condition, "\n")
  cat("Negative logFC = upregulated in:", down_condition, "\n\n")
  
  # ============================================================================
  # 2. Intelligent subsetting
  # ============================================================================
  if (!is.null(celltype)) {
    cat("=== Step 1: Subsetting to cell type:", celltype, "===\n")
    cells_celltype <- seurat_obj@meta.data[[celltype_col]] %in% celltype
    seurat_subset <- seurat_obj[, cells_celltype]
    cat("Cells in", celltype, ":", ncol(seurat_subset), "\n")
    
    if (ncol(seurat_subset) == 0) {
      stop(paste("No cells found for celltype:", celltype))
    }
    
    cat("\n=== Step 2: Subsetting to conditions:", condition1, "vs", condition2, "===\n")
    condition_values <- seurat_subset@meta.data[[condition_col]]
    cat("Available conditions in", condition_col, ":", paste(unique(condition_values), collapse = ", "), "\n")
    cells_conditions <- seurat_subset@meta.data[[condition_col]] %in% c(condition1, condition2)
    seurat_subset <- seurat_subset[, cells_conditions]
    
  } else {
    cat("\n=== Subsetting to conditions:", condition1, "vs", condition2, "===\n")
    condition_values <- seurat_obj@meta.data[[condition_col]]
    cat("Available conditions in", condition_col, ":", paste(unique(condition_values), collapse = ", "), "\n")
    cells_conditions <- seurat_obj@meta.data[[condition_col]] %in% c(condition1, condition2)
    seurat_subset <- seurat_obj[, cells_conditions]
    
    if (is.null(celltype_col)) {
      stop("celltype_col must be provided even if celltype is NULL (needed for Libra grouping)")
    }
  }
  
  cat("Cells in", condition1, ":", sum(seurat_subset@meta.data[[condition_col]] == condition1), "\n")
  cat("Cells in", condition2, ":", sum(seurat_subset@meta.data[[condition_col]] == condition2), "\n")
  cat("Total cells for DE:", ncol(seurat_subset), "\n")
  
  if (ncol(seurat_subset) < 10) {
    stop("Insufficient cells for DE analysis (< 10 cells total)")
  }
  
  # ============================================================================
  # 3. Run Libra pseudobulk DE
  # ============================================================================
  cat("\n=== Running Libra pseudobulk DE analysis ===\n")
  cat("Method: edgeR with LRT\n")
  
  de_results <- run_de(
    input = GetAssayData(seurat_subset, layer = "counts"),
    meta = seurat_subset@meta.data,
    replicate_col = sample_col,
    cell_type_col = celltype_col,
    label_col = condition_col,
    min_cells = min_cells,
    min_reps = min_reps,
    min_features = 1,
    de_family = "pseudobulk",
    de_method = "edgeR",
    de_type = "LRT",
    input_type = "scRNA",
    n_threads = 6
  )
  
  cat("DE analysis complete. Total genes tested:", nrow(de_results), "\n")
  
  # ============================================================================
  # 4. Filter significant genes
  # ============================================================================
  cat("\n=== Filtering significant genes ===\n")
  cat("Criteria: p_val_adj <", pval_cutoff, "and |avg_logFC| >", fc_cutoff, "\n")
  
  significant_genes <- de_results %>%
    filter(p_val_adj < pval_cutoff, abs(avg_logFC) > fc_cutoff) %>%
    arrange(p_val_adj)
  
  n_sig_up <- sum(significant_genes$avg_logFC > 0)
  n_sig_down <- sum(significant_genes$avg_logFC < 0)
  
  cat("Significant genes:", nrow(significant_genes), "\n")
  cat("  Upregulated in", up_condition, ":", n_sig_up, "\n")
  cat("  Upregulated in", down_condition, "(= downregulated):", n_sig_down, "\n")
  
  # ============================================================================
  # 5. Create EnhancedVolcano plot with direction labels
  # ============================================================================
  cat("\n=== Creating volcano plot ===\n")
  
  if (is.null(title)) {
    title <- paste0("DE Analysis: ", celltype, "\n", condition1, " vs ", condition2)
  }
  
  # Build subtitle with direction labels
  subtitle_text <- paste0(
    n_sig_up, " up in ", up_condition, ", ",
    n_sig_down, " up in ", down_condition,
    " (FDR < ", pval_cutoff, ", |logFC| > ", fc_cutoff, ")"
  )
  
  # Build x-axis label with direction arrows
  x_label <- paste0("avg_logFC\n\u2190 Up in ", down_condition, "
    |    Up in ", up_condition, " \u2192")
  
  volcano_plot <- EnhancedVolcano(
    de_results,
    lab = de_results$gene,
    x = 'avg_logFC',
    y = 'p_val_adj',
    title = title,
    subtitle = subtitle_text,
    xlab = x_label,
    pCutoff = pval_cutoff,
    FCcutoff = fc_cutoff,
    pointSize = 1.5,
    labSize = 3.0,
    colAlpha = 0.7,
    legendPosition = 'right',
    legendLabSize = 12,
    legendIconSize = 4.0,
    drawConnectors = TRUE,
    widthConnectors = 0.2,
    colConnectors = 'grey30',
    max.overlaps = 20
  )
  
  # ============================================================================
  # 6. Return results — includes direction info for downstream enrichment
  # ============================================================================
  return(list(
    de_results = de_results,
    significant_genes = significant_genes,
    volcano_plot = volcano_plot,
    n_sig_up = n_sig_up,
    n_sig_down = n_sig_down,
    subset_obj = seurat_subset,
    up_condition = up_condition,
    down_condition = down_condition
  ))
}


#' Compare Cell Type Proportions Between Groups
#'
#' @description
#' Analyzes and visualizes the distribution of a specific cell type across different
#' experimental groups.
#'
#' @param seurat_obj Seurat object
#' @param group_col Column name defining the experimental groups
#' @param sample_col Column name that uniquely identifies samples
#' @param celltype Exact cell type name to analyze
#' @param celltype_col Column name containing cell type annotations
#' @param percentage_mode "total" (default) or "broad"
#' @param broad_cell Name of broader cell category (for "broad" mode)
#' @param broad_cell_col Column name with broader cell categories (for "broad" mode)
#' @param custom_colors Named vector of colors for groups.
#'
#' @return A list with: plot, test, data
#'
#' @export

#' Compare Cell Type Proportions Between Groups
#'
#' @description
#' Analyzes and visualizes the distribution of a specific cell type across different
#' experimental groups.
#'
#' @param seurat_obj Seurat object
#' @param group_col Column name defining the experimental groups
#' @param sample_col Column name that uniquely identifies samples
#' @param celltype Exact cell type name to analyze
#' @param celltype_col Column name containing cell type annotations
#' @param percentage_mode "total" (default) or "broad"
#' @param broad_cell Name of broader cell category (for "broad" mode)
#' @param broad_cell_col Column name with broader cell categories (for "broad" mode)
#' @param custom_colors Named vector of colors for groups.
#'
#' @return A list with: plot, test, data
#'
#' @export

compare_celltype_by_group <- function(seurat_obj,
                                      group_col,
                                      sample_col,
                                      celltype,
                                      celltype_col,
                                      percentage_mode = "total",
                                      broad_cell = NULL,
                                      broad_cell_col = NULL,
                                      custom_colors = NULL) {
  
  cells <- seurat_obj@meta.data[[celltype_col]] %in% celltype
  
  if (percentage_mode == "total") {
    total_per_sample <- table(seurat_obj@meta.data[[sample_col]])
  } else if (percentage_mode == "broad" && !is.null(broad_cell) && !is.null(broad_cell_col)) {
    broad_cells <- seurat_obj@meta.data[[broad_cell_col]] %in% broad_cell
    total_per_sample <- table(seurat_obj@meta.data[[sample_col]][broad_cells])
    # Restrict numerator to cells that are ALSO in the broad category
    # so the ratio is bounded at 100%
    cells <- cells & broad_cells
  } else {
    stop("percentage_mode must be 'total', or 'broad' with broad_cell and broad_cell_col specified")
  }
  
  celltype_per_sample <- table(seurat_obj@meta.data[[sample_col]][cells])
  
  all_samples <- names(total_per_sample)
  celltype_counts <- rep(0, length(all_samples))
  names(celltype_counts) <- all_samples
  celltype_counts[names(celltype_per_sample)] <- celltype_per_sample
  
  # Avoid division by zero for samples with no cells in the broad category
  celltype_pct <- ifelse(total_per_sample > 0,
                         (celltype_counts / total_per_sample) * 100,
                         NA_real_)
  
  sample_group <- unique(seurat_obj@meta.data[, c(sample_col, group_col)])
  rownames(sample_group) <- sample_group[[sample_col]]
  
  plot_df <- data.frame(
    Sample = names(celltype_pct),
    Celltype_pct = as.numeric(celltype_pct),
    Group = sample_group[names(celltype_pct), group_col]
  )
  
  # Drop samples with NA percentages (no denominator cells)
  plot_df <- plot_df[!is.na(plot_df$Celltype_pct), ]
  
  # Defensive check: Wilcoxon needs exactly 2 groups, each with observations
  test_result <- tryCatch({
    if (length(unique(plot_df$Group)) == 2) {
      wilcox.test(Celltype_pct ~ Group, data = plot_df)
    } else {
      message("Skipping Wilcoxon test: need exactly 2 groups, found ",
              length(unique(plot_df$Group)))
      NULL
    }
  }, error = function(e) {
    message("Wilcoxon test failed: ", conditionMessage(e))
    NULL
  })
  
  library(ggplot2)
  
  if (percentage_mode == "broad") {
    y_label <- paste(celltype, "% (of", broad_cell, ")")
  } else {
    y_label <- paste(celltype, "%")
  }
  
  # Build title with p-value only if test succeeded
  plot_title <- if (!is.null(test_result)) {
    paste(celltype, "infiltration by", group_col,
          "\np =", round(test_result$p.value, 4))
  } else {
    paste(celltype, "infiltration by", group_col)
  }

  p <- ggplot(plot_df, aes(x = Group, y = Celltype_pct, fill = Group)) +
    geom_violin() +
    geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA) +
    geom_jitter(width = 0.1, height = 0, size = 2) +
    labs(title = plot_title,
         x = group_col,
         y = y_label) +
    theme_bw()
  
  if (!is.null(custom_colors)) {
    p <- p + scale_fill_manual(values = custom_colors)
  }
  
  return(list(
    plot = p,
    test = test_result,
    data = plot_df
  ))
}
#' Run GO Enrichment on DE Results (V2)
#'
#' @description
#' Takes DE results from run_de_analysis() and runs GO enrichment analysis.
#'
#' **V2 CHANGE — Direction-aware labeling:**
#' The `label` parameter should include the biological direction from
#' run_de_analysis(). Use the `up_condition` / `down_condition` fields from
#' DE results to build the label. Example:
#'   label = paste("Upregulated in", de_result$up_condition)
#'
#' @param gene_list Character vector of gene symbols
#' @param organism "human" or "mouse"
#' @param ont GO ontology: "BP" (default), "MF", "CC", or "ALL"
#' @param pvalueCutoff P-value cutoff. Default: 0.05
#' @param qvalueCutoff Q-value cutoff. Default: 0.05
#' @param label Descriptive label for console output and plot title
#'
#' @return A list with:
#'   - result: Data frame of significant GO terms, or message string
#'   - plot: Dotplot (or NULL)
#'   - enrichment_obj: Raw enrichResult object (or NULL)
#'
#' @export

run_go_enrichment <- function(gene_list,
                               organism = "human",
                               ont = "BP",
                               pvalueCutoff = 0.05,
                               qvalueCutoff = 0.05,
                               label = NULL) {
  
  library(clusterProfiler)
  
  if (organism == "human") {
    library(org.Hs.eg.db)
    orgdb <- org.Hs.eg.db
  } else if (organism == "mouse") {
    library(org.Mm.eg.db)
    orgdb <- org.Mm.eg.db
  } else {
    stop("organism must be 'human' or 'mouse'")
  }
  
  if (!is.null(label)) {
    cat("\n=== GO Enrichment:", label, "===\n")
  }
  cat("Input genes:", length(gene_list), "\n")
  
  if (length(gene_list) == 0) {
    cat("No genes provided. Skipping enrichment.\n")
    return(list(
      result = "No significant GO enrichment found — empty gene list",
      plot = NULL,
      enrichment_obj = NULL
    ))
  }
  
  go_enrich_result <- tryCatch({
    go_enrich <- enrichGO(
      gene          = gene_list,
      OrgDb         = orgdb,
      keyType       = "SYMBOL",
      ont           = ont,
      pAdjustMethod = "BH",
      pvalueCutoff  = pvalueCutoff,
      qvalueCutoff  = qvalueCutoff
    )
    
    if (is.null(go_enrich) || nrow(go_enrich@result) == 0) {
      cat("No enriched GO terms found.\n")
      return(list(
        result = "No significant GO enrichment found",
        plot = NULL,
        enrichment_obj = NULL
      ))
    }
    
    sig_results <- go_enrich@result %>%
      filter(p.adjust < 0.05)
    
    if (nrow(sig_results) == 0) {
      cat("No GO terms with p.adjust < 0.05.\n")
      return(list(
        result = "No significant GO enrichment found",
        plot = NULL,
        enrichment_obj = go_enrich
      ))
    }
    
    cat("Significant GO terms (p.adjust < 0.05):", nrow(sig_results), "\n")
    
    # Use label in plot title for clear direction
    plot_title <- ifelse(is.null(label), "GO Enrichment", paste("GO Enrichment:", label))
    
    p <- tryCatch({
      dotplot(go_enrich, showCategory = min(20, nrow(sig_results))) +
        ggtitle(plot_title)
    }, error = function(e) {
      cat("Warning: Could not create dotplot:", e$message, "\n")
      NULL
    })
    
    return(list(
      result = sig_results,
      plot = p,
      enrichment_obj = go_enrich
    ))
    
  }, error = function(e) {
    cat("Error in GO enrichment:", e$message, "\n")
    return(list(
      result = "No significant GO enrichment found — error in analysis",
      plot = NULL,
      enrichment_obj = NULL
    ))
  })
  
  return(go_enrich_result)
}

# ============================================================================
# add_per_sample_summary
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
# create_groups_from_per_sample_summary
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
