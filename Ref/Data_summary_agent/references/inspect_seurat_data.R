# inspect_seurat_data.R
# Comprehensive Seurat metadata inspection function
# Source this file: source("Scripts/inspect_seurat_data.R")

library(Seurat)
library(Matrix)

inspect_seurat_data <- function(seurat_obj, tissue_type = NULL, save_to_file = TRUE, output_file = "Outputs/data_pre.txt") {
  if(save_to_file) {
    dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)
    sink(output_file)
  }

  if (!is.null(tissue_type)) {
    cat(sprintf("=== COMPREHENSIVE INSPECTION OF %s DATA ===\n\n", toupper(tissue_type)))
  } else {
    cat("=== COMPREHENSIVE SEURAT DATA INSPECTION ===\n\n")
  }

  # Dataset Overview
  cat("DATASET OVERVIEW:\n")
  cat("• Total cells:", ncol(seurat_obj), "\n")
  cat("• Total genes:", nrow(seurat_obj), "\n")
  cat("• Metadata columns:", ncol(seurat_obj@meta.data), "\n\n")

  meta_data <- seurat_obj@meta.data
  col_names <- colnames(meta_data)
  cat("METADATA COLUMNS:", paste(col_names, collapse = ", "), "\n\n")

  # Column Analysis
  cat("DETAILED COLUMN ANALYSIS:\n", rep("=", 50), "\n")

  for(i in seq_along(col_names)) {
    col_name <- col_names[i]
    col_data <- meta_data[[i]]
    non_missing <- col_data[!is.na(col_data)]

    cat(sprintf("\n--- Column %d: '%s' ---\n", i, col_name))
    cat("• Type:", class(col_data)[1], "| Values:", length(col_data),
        "| Missing:", sum(is.na(col_data)),
        sprintf("(%.1f%%)\n", sum(is.na(col_data)) / length(col_data) * 100))

    if(length(non_missing) == 0) {
      cat("• All values missing\n")
      next
    }

    unique_count <- length(unique(non_missing))
    cat("• Unique values:", unique_count, "\n")

    # Print actual unique values if ≤60 (for any column type)
    if(unique_count <= 60) {
      all_unique <- sort(unique(as.character(non_missing)))
      cat("• All unique values:", paste(all_unique, collapse = ", "), "\n")
    } else {
      cat("• Too many unique values (>60) to list\n")
    }

    if(is.numeric(col_data)) {
      stats <- c(min(non_missing), max(non_missing), mean(non_missing),
                 median(non_missing), sd(non_missing))
      quartiles <- quantile(non_missing, c(0.25, 0.75))
      cat("• Min:", round(stats[1], 3), "| Max:", round(stats[2], 3),
          "| Mean:", round(stats[3], 3), "| Median:", round(stats[4], 3),
          "| SD:", round(stats[5], 3), "\n")
      cat("• Q1:", round(quartiles[1], 3), "| Q3:", round(quartiles[2], 3), "\n")
    } else {
      if(unique_count <= 60) {
        # Print top 3 categories by frequency
        sorted_freq <- sort(table(non_missing), decreasing = TRUE)
        cat("• Top categories:\n")
        for(j in 1:min(3, length(sorted_freq))) {
          cat(sprintf("  %s: %d (%.1f%%)\n", names(sorted_freq)[j],
                      sorted_freq[j], sorted_freq[j] / length(non_missing) * 100))
        }
      } else {
        cat("• Most common:",
            names(sort(table(non_missing), decreasing = TRUE))[1], "\n")
      }
    }
    cat("• Sample:", paste(head(non_missing, 5), collapse = ", "), "\n")
  }

  # Data Preview
  cat("\n", rep("=", 50), "\n")
  cat("FIRST 5 ROWS:\n")
  print(head(meta_data, 5))

  # Expression Data
  cat("\nEXPRESSION DATA:\n")
  cat("• Assays:", paste(names(seurat_obj@assays), collapse = ", "), "\n")
  cat("• Default assay:", DefaultAssay(seurat_obj), "\n")
  rna_data <- GetAssayData(seurat_obj, assay = DefaultAssay(seurat_obj), layer = "counts")
  cat("• Total UMIs:", sum(rna_data),
      "| Mean UMIs/cell:", round(mean(Matrix::colSums(rna_data)), 2),
      "| Mean genes/cell:", round(mean(Matrix::colSums(rna_data > 0)), 2), "\n")

  # Additional Info
  cat("\nMETADATA STRUCTURE:\n")
  str(meta_data)

  cat("\nSUMMARY STATISTICS:\n")
  summary(meta_data)

  cat("\nOBJECT DIMENSIONS:\n")
  print(dim(seurat_obj))

  cat("\n=== INSPECTION COMPLETE ===\n")

  if(save_to_file) {
    sink()
    cat("Report saved to:", output_file, "\n")
  }
}