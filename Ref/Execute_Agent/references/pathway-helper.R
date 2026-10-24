# ============================================================================
# pathway-helper.R
# ----------------------------------------------------------------------------
# Standalone helper for debugging "pathway name not found" errors in
# msigdbr-based gene-list lookups.
#
# Source this file from a debug R session:
#   source("~/.claude/agents/Ref/Execute_Agent/references/pathway-helper.R")
#
# Then call:
#   get_pathway_genes("HALLMARK_GLYCOLYSIS")                    # exact name
#   get_pathway_genes("KEGG_GLYCOLYSIS", fallback_patterns = c("glycolysis", "glucose"))
#
# Behavior:
#   1) Tries the exact pathway_name across a list of (collection, subcollection)
#      sources. Returns gene symbols on first hit.
#   2) On miss, if `fallback_patterns` is non-NULL, prints all set names whose
#      gs_name matches ANY of the patterns (case-insensitive). Returns
#      character(0) so the caller can inspect the candidates and pick one.
#   3) On total miss, returns character(0) and prints [FAIL].
#
# Sources tried in order (CP:KEGG is deprecated since msigdbr ≥ 10.0
# and not included):
#   1. C2 / CP:KEGG_LEGACY     (classic ~186 KEGG sets, e.g. KEGG_GLYCOLYSIS_GLUCONEOGENESIS)
#   2. C2 / CP:KEGG_MEDICUS    (newer, larger Medicus collection)
#   3. C2 / CP:REACTOME
#   4. C2 / CP:WIKIPATHWAYS
#   5. C2 / CP:BIOCARTA
#   6. C5 / GO:BP
#   7. H   / (no subcollection — Hallmark sets, gs_name starts with HALLMARK_)
# ============================================================================

suppressPackageStartupMessages({
  library(msigdbr)
  library(dplyr)
})

# Detect msigdbr version once. msigdbr >= 10.0 deprecated category/subcategory
# in favor of collection/subcollection. The helper uses the new API and warns
# on old versions.
.use_collection_api <- tryCatch({
  utils::packageVersion("msigdbr") >= "10.0.0"
}, error = function(e) TRUE)

if (!.use_collection_api) {
  warning("Old msigdbr (< 10.0.0) detected. The helper uses the new ",
          "collection/subcollection arguments; please update msigdbr.")
}

.msigdbr_call <- function(species, collection, subcollection = NULL) {
  if (.use_collection_api) {
    if (is.null(subcollection)) {
      msigdbr(species = species, collection = collection)
    } else {
      msigdbr(species = species, collection = collection,
              subcollection = subcollection)
    }
  } else {
    if (is.null(subcollection)) {
      msigdbr(species = species, category = collection)
    } else {
      msigdbr(species = species, category = collection,
              subcategory = subcollection)
    }
  }
}

get_pathway_genes <- function(pathway_name,
                              fallback_patterns = NULL,
                              species = "Homo sapiens") {

  sources <- list(
    list(coll = "C2", sub = "CP:KEGG_LEGACY"),
    list(coll = "C2", sub = "CP:KEGG_MEDICUS"),
    list(coll = "C2", sub = "CP:REACTOME"),
    list(coll = "C2", sub = "CP:WIKIPATHWAYS"),
    list(coll = "C2", sub = "CP:BIOCARTA"),
    list(coll = "C5", sub = "GO:BP"),
    list(coll = "H",  sub = NULL)
  )

  src_label <- function(src) {
    if (is.null(src$sub)) src$coll else paste0(src$coll, "/", src$sub)
  }

  # ---- Step 1: exact pathway_name across all sources ----
  for (src in sources) {
    genes <- tryCatch({
      .msigdbr_call(species, src$coll, src$sub) %>%
        filter(gs_name == pathway_name) %>%
        pull(gene_symbol) %>% unique()
    }, error = function(e) character(0))

    if (length(genes) > 0) {
      cat(sprintf("[OK] Found '%s' in %s: %d genes\n",
                  pathway_name, src_label(src), length(genes)))
      return(genes)
    }
  }

  # ---- Step 2: pattern-based candidate search ----
  if (!is.null(fallback_patterns) && length(fallback_patterns) > 0) {
    cat(sprintf("[WARN] '%s' not found by exact name. Searching patterns: %s\n",
                pathway_name, paste(fallback_patterns, collapse = ", ")))

    pattern <- paste(fallback_patterns, collapse = "|")
    any_hit <- FALSE

    for (src in sources) {
      all_sets <- tryCatch({
        .msigdbr_call(species, src$coll, src$sub)
      }, error = function(e) NULL)

      if (is.null(all_sets)) next

      matches <- unique(all_sets$gs_name)
      matches <- grep(pattern, matches, value = TRUE, ignore.case = TRUE)

      if (length(matches) > 0) {
        any_hit <- TRUE
        cat(sprintf("[INFO] %d candidate(s) in %s:\n",
                    length(matches), src_label(src)))
        cat(paste0("       ", matches, collapse = "\n"), "\n")
      }
    }

    if (any_hit) {
      cat("[ACTION REQUIRED] Pick one set name above and rerun the original ",
          "preprocess.R / analysis.R with that EXACT name substituted in.\n",
          sep = "")
    } else {
      cat("[INFO] No candidate set names matched the patterns in any source.\n")
    }
    return(character(0))
  }

  cat(sprintf("[FAIL] No genes found for '%s' (no fallback_patterns provided).\n",
              pathway_name))
  return(character(0))
}
