# Step 1: Decision Gate — Detailed Logic

## Goal
Compare every term in `Working/definitions_final.txt` against `Outputs/data_pre.txt`
to decide which terms require subclustering annotation.

---

## Reading definitions_final.txt

The file is a table with columns:
- **Term**: The biological concept name (used by Pass 1)
- **Definition Type**: Category of the definition (used by Pass 3)
- **Paper Definition**: How the original paper defines it (informational)
- **Paper scRNA-seq Def?**: Whether the paper provides an scRNA-seq-based definition
- **Final scRNA-seq Definition**: The recommended gene markers for scRNA-seq use (**used by Pass 2**)

Pass 1 looks at the Term name only. Pass 2 looks at the Final scRNA-seq
Definition only. Pass 3 looks at the Definition Type column.

---

## Pre-filter: Remove Obviously Non-Qualifying Terms

Before the two passes, quickly filter out terms that are clearly not cell subtypes:

- Gene lists, pathway scores, module scores, cytokine lists → SKIP (for Pass 1/2 only)
- X-cancer-type-specific cells → SKIP (for Pass 1/2 only)
- Parent cell type entirely absent from data → SKIP (for Pass 1/2 only)
- Already labeled in the data as-is → SKIP
- Already present in the data under an alternative name (alias resolved in Step 0) → SKIP

**IMPORTANT: This pre-filter applies ONLY to Pass 1 and Pass 2 (cell subtype annotation).** Terms that have package-based definitions (Method P) are NOT filtered here — they go directly to Pass 3 regardless of cancer type mismatch or whether they look like gene lists. The whole point of this transfer pipeline is to TEST whether the paper's methods (including cancer-type-specific classifiers) produce meaningful results on a different dataset. The agent does NOT judge scientific appropriateness — it applies the method and lets downstream analysis evaluate the results.

---

## Pass 1: Well-Known Cell Subtypes (Method B) — Do This FIRST

For each remaining term, ask ONE question:

**Is this cell type name a widely agreed-upon, well-defined cell type that the
field universally recognizes?**

**Ignore the paper's own definition entirely.** Don't look at what genes the
paper lists. Just look at the cell type NAME and ask: is this something every
single-cell biologist would agree on? Would it appear as a standard label in
any published scRNA-seq atlas?

If YES → **Method B**. You will:
1. Subcluster the parent cell type
2. Use YOUR OWN knowledge of what this cell type looks like (standard markers
   from the literature, not the paper's idiosyncratic gene lists)
3. If a subcluster matches → label it
4. If no subcluster matches → don't force it, skip

Examples that PASS (universally recognized):
- Naive T cells
- Tregs (regulatory T cells)
- Effector T cells
- Cytotoxic CD8 T cells
- Mature dendritic cells
- Plasma B cells
- Th17 cells
- NK cells
- Memory B cells

Examples that DO NOT PASS:
- "MHC-II-hi CD8 T cells" — not a standard atlas label
- "Activated fibroblasts with matrix remodeling signature" — paper-specific complex phenotype
- "Stress-response fibroblasts" — paper-specific
- "Hypoxic endothelial cells" — paper-specific functional state, not canonical

---

## Pass 2: Single-Gene Definitions (Method A) — Do This SECOND

For terms that did NOT qualify in Pass 1, look at the term's **Final scRNA-seq
Definition** column (not the term name) and ask:

**Does the final definition resolve to a single "GENE high" rule?**

The criteria:
- The final definition specifies one primary gene being high in a parent cell
  type
- Optionally it may list a handful of supporting co-expressed genes, but there
  are no low/inverted markers, no pathway scores, no module scores, and no
  multi-gene logic
- The term NAME is irrelevant — a term can be called anything ("effector
  cells", "proliferating cells", "TREM2+ macrophages"); only the final
  definition matters

If YES → **Method A**, using the single gene from the final definition
If NO → **SKIP**

Examples that PASS:
- Final definition: "TREM2 high" → check TREM2 in subclusters of the parent
- Final definition: "GZMK high" → check GZMK in subclusters of the parent
- Final definition: "GENE_X high (with GENE_Y, GENE_Z as supporting co-markers)"
  → check GENE_X, treat Y/Z as supporting evidence

Examples that DO NOT PASS:
- Final definition requires multiple genes + pathway enrichment → SKIP
- Final definition is "GENE1 high, GENE2 low" (inverted marker) → SKIP
- Final definition is a KEGG/MSigDB pathway or module score → SKIP (not a
  cell label)
- Final definition is "NA" or says no transcriptional markers → SKIP

---

## Pass 3: Package-Based Classifiers (Method P) — Do This LAST

For all remaining terms (including those skipped by Pass 1/2), check the
**Definition Type** column in `definitions_final.txt`.

**Does the Definition Type start with `package (...)` AND does the definition
describe a function that produces categorical labels?**

To decide, look at the Definition column for these signals:
- **YES (classifier)**: function names like `predict`, `classify`, `call`;
  output described as subtypes/classes/labels (e.g., PDS1/PDS2/PDS3,
  CMS1/CMS2/CMS3/CMS4); thresholds for class assignment
- **NO (score)**: function names like `calculate`, `score`, `index`,
  `enrichIt`; output described as continuous scores, enrichment values, or
  indices

When in doubt, read the package's `*_guide.md` in `Working/extra/` and check
the "What it returns" section. If the primary output is categorical labels →
Method P. If continuous scores → SKIP (handled by code-agent later).

If YES → **Method P**. You will:
1. Read the usage guide at `Working/extra/*_guide.md` for the package
2. If no guide exists, follow the instructions in the Definition column itself
3. Run the classifier (typically: pseudobulk → classify → broadcast labels back
   to cells)
4. Add the resulting labels as a new metadata column

**This pass is NOT filtered by cancer type mismatch.** The whole point of this
transfer pipeline is to TEST whether the paper's classifiers produce meaningful
results on a different dataset. The agent does NOT judge scientific
appropriateness — it applies the method and lets downstream analysis evaluate.

Examples that PASS:
- Definition Type is `package (...)` and the function produces categorical labels
  (subtypes, classes, groups) → Method P

Examples that DO NOT PASS:
- Definition Type is `package (...)` but the function produces continuous scores,
  enrichment values, or indices → SKIP (code-agent handles scoring)
- "gene list (resolved)" → gene set scoring → SKIP
- "formula (resolved)" → computed value → SKIP

---

## Everything Else → SKIP

If a term didn't qualify in any of the three passes, skip it. Don't try to make
it work. Gene lists, pathway scores, module scores, formulas, and tools/methods
are all handled by the code-agent in later pipeline steps.

---

## Output of Step 1

Produce a structured decision internally:

```
Pass 1 — Well-known subtypes (Method B):
1. [Term] — parent: [from data_pre.txt], will use own knowledge of markers
2. [Term] — parent: [from data_pre.txt], will use own knowledge of markers

Pass 2 — Single-gene subtypes (Method A):
1. [Term] — parent: [from data_pre.txt], gene: [GENE]
2. [Term] — parent: [from data_pre.txt], gene: [GENE]

Pass 3 — Package classifiers (Method P):
1. [Term] — package: [PACKAGE_NAME], guide: [path or "none"]
2. [Term] — package: [PACKAGE_NAME], guide: [path or "none"]

Skipped:
- [Term]: not a cell subtype (gene list / pathway / score — handled by code-agent)
- [Term]: not universally recognized, not single-gene
- [Term]: parent absent from data
- [Term]: already labeled
```

If no tasks from any pass → **stop immediately, produce nothing.**
If tasks exist → proceed to Step 2.
