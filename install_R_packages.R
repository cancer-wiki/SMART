# =============================================================
# Install all R packages required by the SMART pipeline
# Run this once on a new machine: Rscript install_R_packages.R
# =============================================================

cat("Installing SMART R dependencies...\n\n")

# --- CRAN packages ---
cran_pkgs <- c("Seurat", "ggplot2", "dplyr", "tidyverse", "msigdbr",
               "knitr", "kableExtra", "rmarkdown", "readxl", "devtools", "remotes")

cat("=== CRAN packages ===\n")
for (pkg in cran_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org")
  } else {
    cat(pkg, "already installed\n")
  }
}

# --- Bioconductor packages ---
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

bioc_pkgs <- c("clusterProfiler", "org.Hs.eg.db", "org.Mm.eg.db",
               "AnnotationDbi", "EnhancedVolcano", "edgeR", "DESeq2", "limma")

cat("\n=== Bioconductor packages ===\n")
for (pkg in bioc_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    BiocManager::install(pkg, update = FALSE, ask = FALSE)
  } else {
    cat(pkg, "already installed\n")
  }
}

# --- GitHub packages ---
cat("\n=== GitHub packages ===\n")
if (!requireNamespace("Libra", quietly = TRUE)) {
  cat("Installing Libra from GitHub...\n")
  remotes::install_github("neurorestore/Libra", upgrade = "never")
} else {
  cat("Libra already installed\n")
}

# --- Verify all packages ---
cat("\n=== Verification ===\n")
all_pkgs <- c(cran_pkgs, bioc_pkgs, "Libra")
missing <- all_pkgs[!sapply(all_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing) == 0) {
  cat("All packages installed successfully!\n")
} else {
  cat("WARNING: Failed to install:", paste(missing, collapse = ", "), "\n")
}
