# Further Annotate — Orientation

## Purpose
Further annotate a Seurat scRNA-seq object by subclustering existing broad cell types to identify finer subtypes required by the paper's definitions.

## Files

| Type | Path |
|------|------|
| Input | `Outputs/data_pre.txt` (dataset metadata summary) |
| Input | `Working/definitions_final.txt` (term definitions + marker genes) |
| Input | `Inputs/data.rds` (Seurat object — read only, not modified) |
| Output | `Working/added_annotations.csv` (new columns keyed by cell barcode) |
| Output | `Working/data_pre_add.txt` (new column names + table outputs) |
| Output | `Working/further_annotate.R` (the R code used for annotation) |

## Workflow
Step 1: Decide which terms need annotation (three passes)
  - Pass 1: Well-known cell subtypes → Method B (subcluster with own knowledge)
  - Pass 2: Single-gene markers → Method A (subcluster, check one gene)
  - Pass 3: Package classifiers → Method P (pseudobulk → classify → broadcast labels)
Step 2: Pick the right metadata column(s) to subset from
Step 3: Subcluster/classify, inspect, assign labels
Step 4: Export CSV + summary + R script

If no tasks qualify at Step 1 → stop, produce nothing.

## Where things live
- Full runbook with code templates: `~/.claude/agents/Ref/Further_Annotate/further-annotate-agent.md`
- Two-pass decision logic with examples: `~/.claude/agents/Ref/Further_Annotate/references/step1-decision.md`
