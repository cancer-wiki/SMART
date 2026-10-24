# Common Errors in Task Planning

---

### 1. Protein-Level Claim in Wrong Section ⚠️

Paper: "Enzyme X catalyzes modification on surface protein Y"
Wrong: Section 2 — "Check enzyme X expression vs protein Y expression"
Right: Section 3 for the modification mechanism; Section 1/2 only for mRNA proxy,
       labeled explicitly as a proxy

---

### 2. Wrong Correlation Direction ⚠️

Paper: "Gene A represses program B"
Wrong: "expect positive correlation"
Right: "expect **negative** correlation — Gene A is a repressor"

Rule: Always state expected direction and justify from paper's causal claim.

---

### 3. Causal Claim Treated as Simple Correlation

Paper: "Transcription factor X induces gene Y under stress condition"
Wrong: "Correlate TF_X with GENE_Y"
Right: "Correlate TF_X pathway signature with GENE_Y — tests co-occurrence only,
        not causation; scRNA-seq cannot confirm causal direction"

---

### 4. Wrong Cell Type Assignment

Paper: "Gene A on macrophages; marker B+ regulatory T cells increased"
Wrong: Check gene A and marker B both in macrophages
Right: Gene A in macrophages; marker B in CD4+ T cells separately

---

### 5. Vague Gene Lists

Wrong: "Required processing: Calculate metabolic pathway score"
Right: "Required processing: add_module_score with genes: [GENE1, GENE2, GENE3, ...]
        — source: definitions_final.txt / KEGG [pathway name]"

---

### 6. Missing Brainstorm Link

Wrong: "Check Gene X vs Gene Y in malignant cells"
Right: "Check Gene X vs Gene Y in malignant cells
        — From brainstorm: Finding #N, Piece N.M"

---

### 7. Section 1 Item That Needs Processing

Wrong (Section 1): "Check program score vs cell type percentage"
Right (Section 2): "Check program score vs cell type percentage — requires computing
                    signature first (add_module_score)"

---

### 8. Proxy Without Disclaimer

Wrong: "Gene X mRNA confirms post-translational mechanism"
Right: "Gene X mRNA is a transcriptional proxy only; actual protein modification
        levels require proteomics/mass spectrometry. Do not necessarily expect a result."

---

### 9. Summary Sentence Given Testable Pieces ⚠️

Paper finding: "Gene X acts as a regulator of transcription through
mechanism Y in cancer cells."
Wrong: Decompose into testable pieces about the mechanism
Right: NOT TESTABLE — "summary sentence, tested via its specific sub-findings below"

Rule: If a finding merely restates or summarizes other listed findings,
skip it entirely and reference the sub-findings.

---

### 10. Duplicate Analysis for Feedback Loop ⚠️

Paper: Finding A says "molecule P promotes activity of protein Q" and
Finding B says "protein Q activates transcription of molecule P"
Wrong: Create two separate correlation tests (Q vs P twice)
Right: "Same correlation as Piece X.Y — feedback loop does not require
        a separate test at the mRNA level"

---

### 11. Undefined Score Proposed ⚠️

Paper: "Loss of gene X causes macrophage exhaustion and cytokine storm"
Wrong (Section 2): "Correlate gene X with cytokine storm score"
Right: "Skip — concepts like cytokine storm or macrophage exhaustion
        have no standard scRNA-seq gene signature. Test a related, well-defined
        score instead (e.g., inflammatory response via Hallmark gene set) if available."

Rule: Check `Working/definitions_final.txt` first. If not there, check
KEGG/Hallmark. If no established gene list exists, skip the score.

---

### 12. Metadata Assumed Without Checking ⚠️

Paper: "Gene X is elevated in metastatic vs primary tumors"
Wrong (Section 1): "Compare gene X between metastatic and primary"
Right (Section 4/CONDITIONAL): "Compare gene X between primary vs metastatic —
        CONDITIONAL on having tumor site metadata. If unavailable, skip."

---

### 13. CNV-Dependent Finding Not Flagged ⚠️

Paper: "Amplification of genes in region Xq correlates with higher program score"
Wrong (Section 2): "Check copy number vs program score"
Right (Section 3): "NOT TESTABLE — CNV analysis is out of current scope"

---

### 14. Vague Analysis Type ⚠️

Wrong: "Compare gene X between groups"
Right: "Boxplot of gene X expression: condition A vs condition B in [cell type]"

Wrong: "Check association between gene X and pathway activity"
Right: "Per-sample correlation of gene X vs pathway score in [cell type]
        + Boxplot: split samples by gene X level, compare pathway score"

Rule: Always specify the exact analysis type — correlation, boxplot,
DE + enrichment, gating proportion, percentage comparison, etc. Most pieces
need BOTH correlation AND boxplot.

---

### 15. Missing Preferred Approach / Splitting One Signaling Axis Into Separate Pieces ⚠️

Paper: "Gene X regulates targets T1, T2, T3, T4, T5"
Wrong: "Correlate gene X with T1, T2, T3, T4, T5"
Right: "Option A: Individual correlations gene X vs each target.
        Option B: Gene X vs combined score of [T1, T2, T3, T4, T5].
        Preferred: Option B (combined score — more robust, single test)"

**Extended rule for multi-ligand / multi-receptor axes:**
When the paper describes multiple ligands from cell-type A binding
multiple receptors on cell-type B as ONE signaling axis (e.g.,
"Ligands L1, L2, L3, L4 bind receptors R1, R2, R3, R4, R5 on target
cells"), create ONE piece with a combined ligand score vs combined
receptor score as the primary cross-cell-type correlation test. Do NOT
split this into separate pieces per ligand family (e.g., one piece for
L1-R1/R2 and another for L2/L3/L4-R3/R4/R5).

Wrong: Piece A tests "L1 vs R1/R2"; Piece B tests "L2/L3/L4 vs R3/R4/R5"
  → The brainstorm agent assesses each sub-axis individually, one may
    appear "weak" even though the combined axis is strong.

Right: ONE piece with combined ligand score (L1+L2+L3+L4) vs combined
  receptor score (R1+R2+R3+R4+R5) as primary. Individual ligand-receptor
  pairs as supplementary within the SAME piece.

---

### 16. Cross-Cell-Type Signaling Chain Decomposition ⚠️

Paper: "Cell type A secretes ligand L → binds receptor R on cell type B → causes output Z in cell type B"

This is a three-step signaling chain: (1) A produces L, (2) L binds R on B, (3) R activation drives Z in B. Each step is a separate testable link:

Wrong: Correlate ligand L in cell type A vs output Z in cell type B
  → This skips the receptor step entirely. It tests whether samples with
    higher ligand in A also have higher output in B, but the ligand level
    in A may not vary across samples (constitutively secreted), or the
    bottleneck may be at the receptor level, not the ligand level. This
    indirect cross-cell-type correlation adds noise and often produces
    null results even when the biology is real.

Also wrong: Check the factor and activation markers in the same cell type
  → The ligand-receptor link IS cross-cell-type and must be tested as such.

Right: Decompose into TWO pieces:
  **Piece X (ligand-receptor link):** Correlate ligand L in cell type A
    vs receptor R in cell type B (cross-cell-type). This tests whether the
    signaling axis exists between the two cell types.
  **Piece Y (receptor-effector link):** Correlate receptor R vs output Z,
    BOTH within cell type B (same-cell-type). This tests whether receptor
    engagement is associated with the downstream output in the receiving
    cell. This is the direct test of the mechanism's consequence.

Example:
  Paper: "Tumor cells secrete cytokine W → binds receptor R on stromal
    cells → induces gene Z in stromal cells"
  Wrong: One piece — correlate W in tumor vs Z in stromal (cross-cell-type)
  Right: Two pieces:
    Piece A — correlate W in tumor vs R in stromal (cross-cell-type, ligand-receptor)
    Piece B — correlate R vs Z both in stromal (same-cell-type, receptor-effector)

Rule: When a mechanism claim involves a sender cell producing a signal that
causes an output in a receiver cell, ALWAYS decompose into (1) ligand-receptor
cross-cell-type correlation and (2) receptor-effector same-cell-type
correlation. Never test ligand-effector directly across cell types.

---

### 17. Only Correlation Without Boxplot ⚠️

Paper: "Gene A activates pathway B"
Wrong: "Per-sample correlation of A vs B-score" (correlation only)
Right: "Per-sample correlation of A vs B-score +
        Boxplot: split samples by A level (median), compare B-score
        between A-high vs A-low groups"

Rule: For "A activates/promotes B" claims, ALWAYS assign both correlation
AND boxplot. The boxplot provides visual confirmation of the directional effect.

---

### 18. Missing DE + Enrichment for Broad Claims ⚠️

Paper: "Gene A activates the Wnt signaling pathway"
Wrong: Only test correlation of A vs Wnt-signaling score
Right: Also include DE + enrichment: split cells by A level, run DE,
       check if Wnt-signaling / proliferation GO terms are enriched in A-high group
       (GO over-representation preferred)

Rule: Whenever a gene is claimed to drive a pathway or broad transcriptional
changes, include DE + enrichment as an unbiased validation, in addition to
specific correlations.

---

### 19. Missing Stratified Analyses ⚠️

Paper: "Gene A promotes pathway B in cancer cells"
Dataset has: disease_stage (primary vs recurrent), sex (male vs female)
Wrong: Only test overall correlation of A vs B
Right: Test overall correlation + repeat stratified by disease stage and by sex

Rule: In Stage 2, for every testable piece, check metadata (both native and
added) for meaningful stratification columns and propose repeating the
analysis within subgroups.

---

### 20. Gene List Not Checked in definitions_final.txt First ⚠️

Paper: "Gene A promotes glycolysis"
Wrong: Immediately look up KEGG glycolysis genes
Right: First check `Working/definitions_final.txt` for the paper's own
       glycolysis gene list. If present, use it. If absent, fall back to KEGG.

Rule: definitions_final.txt is the primary source for gene lists. Standard
databases (KEGG, Hallmark) are fallbacks.

---

### 21. Computing Module Score When Annotation Already Exists ⚠️

Paper: "Gene A regulates G2/M checkpoint"
Dataset: Has Phase column with G1/S/G2M assignments (native metadata OR in `data_pre_add.txt`)
Wrong: Compute HALLMARK_G2M_CHECKPOINT module score
Right: Use per-sample %G2M (proportion of G2M cells per sample in the
       relevant cell type) as the feature for correlation/boxplot

Rule: When the dataset already has categorical annotation that captures the
concept (cell cycle phase, ploidy, subtype) — whether in native metadata or
in `data_pre_add.txt` — use the proportion of the relevant category per
sample. Do not compute a module score for something already annotated.

---

### 22. Cell Type Comparison Stratified by Condition ⚠️

Paper: "Gene A is elevated in cancer cells"
Wrong: Boxplot of gene A across cell types, then repeat for each condition separately
Right: Single boxplot of gene A across cell types, pooling all samples.
       No condition split — this is a basic characterization.

Rule: Pattern 4 (gene across cell types) should pool all samples.
Do not stratify by condition.

---

### 23. Extra Tests Too Detailed ⚠️

Wrong (Extra test): "Boxplot of VEGFA, KDR, FLT1, PECAM1, CDH5, TEK
       each by angiogenesis-status group — 6 separate boxplots"
Right (Extra test): "Correlate VEGFA with %proliferating proportion in endothelial cells"
       (one simple directional test)

Rule: Extra tests are high-level taste tests. ONE simple analysis each
(one correlation or one boxplot). Do not propose detailed breakdowns or
individual-gene-level analyses in extras.

---

### 24. Forgetting Cell Subtype Proportion as a Feature ⚠️

Paper: "Gene A promotes cell proliferation"
Dataset: Has cell cycle Phase column (native or added)
Wrong: Only test correlation of A vs proliferation score
Right: Also test correlation of A vs %S+G2M cells per sample (proportion
       of actively cycling cells)

Rule: Cell subtype proportion is a per-sample feature just like a gene
or a score. Always consider it for composition-related claims.

---

### 25. Separate Boxplots for Same Feature Different Groupings ⚠️

Wrong: Three separate tasks — "VEGFA by Type", "VEGFA by sex", "VEGFA by Type×sex"
Right: Create a combined column (e.g., sex_Type) in preprocessing, then
       display in one boxplot

Rule: When you want to show the same feature compared across multiple
metadata groupings, combine them into a single group column to reduce
the number of plots.

---

### 26. Forcing Composite High/Low Feature into a Module Score ⚠️ (NEW)

Paper: "KRT8-positive, VIM-expressing, CDH1-low partial-EMT epithelial cells"
Gene list: KRT8 high, VIM high, CDH1 low

Wrong (subtraction): score = module(KRT8, VIM) − module(CDH1)
  → produces negative values, scale mismatch, hard to interpret

Wrong (inversion): score = module(KRT8, VIM) + 1/CDH1
  → unbalanced, one gene dominates due to scale

Wrong (sign-flip in single module): AddModuleScore([KRT8, VIM, −CDH1])
  → not well-defined; module scoring assumes all genes should be high

Right (GatingProportion, Pattern 4c):
  1. Within the epithelial parent type, gate:
     KRT8 > median AND VIM > median AND CDH1 < median
  2. Per-sample proportion = (# gated cells) / (# epithelial cells) per sample
  3. Use the proportion as the feature (positive, interpretable, matches the
     flow-cytometry-style / state-gating definition from the paper)

Rule: Whenever the paper defines a population by a mix of high and low markers,
use GatingProportion (Pattern 4c). Do not subtract, invert, or sign-flip.
If a continuous version is explicitly required, fall back to two separate
module scores (one for high genes, one for low genes) tested independently
with opposite expected directions — never combined arithmetically.

---

### 27. Using Patient Column When Sample Column Exists ⚠️ (NEW)

Dataset: Has both `sample` and `patient` columns
Wrong: Aggregate per patient for correlations and boxplots
Right: Aggregate per `sample` (include a note: "For exploration we use
       sample-wise data, not patient-wise data. Sample column: `sample`
       (chosen over `patient` when both exist).")

Rule: Prefer `sample` over `patient` when both are present. This is
exploration, not a formal clinical analysis — the finer-grained unit gives
more data points and is what we want for directional signals.

---

### 28. Ignoring `data_pre_add.txt` Added Annotations ⚠️ (NEW)

Dataset: `data_pre_add.txt` has a refined cell-type column
(e.g., a `T_cell_subtype` column with categories like "effector T cell",
"memory T cell", "naive T cell", etc.)

Wrong: Only inspect `data_pre.txt`; propose computing new module scores or
       running marker-based annotation to identify these subtypes
Right: Treat `data_pre_add.txt` columns as first-class metadata. Use their
       categorical values directly for cell-type assignment; use per-sample
       proportion of each category as a valid feature. No re-annotation
       needed when the added annotation already captures the concept.

Rule: In Stage 2, always read BOTH `data_pre.txt` and `data_pre_add.txt`.
Added annotations are equally authoritative. When building the Metadata
Index, list added-annotation columns alongside native ones.

---

### 29. Not Checking the `orig.ident` Column ⚠️ (NEW)

Dataset: `orig.ident` column exists in the Seurat object metadata

Wrong: Ignore `orig.ident` or assume it only contains sample identifiers
Right: Always inspect the `orig.ident` column. It sometimes contains important
       information such as cell types, patient IDs, or other biologically
       meaningful groupings that differ from other metadata columns (e.g.,
       `orig.ident` may have finer-grained cell type labels like "MSC" while
       a separate column groups them broadly as "Stroma").

Rule: In Stage 2, when building the Metadata Index, always check `orig.ident`
values and compare them against other metadata columns. If `orig.ident`
contains more informative or granular categories, prefer it over coarser
grouping columns.

---

### 30. Choosing the Wrong Parent Group When Multiple Broad Columns Exist ⚠️ (NEW)

**Example A — Lymphoid vs T:**

Dataset has two columns that both look like broad cell type groupings:
- `column_A` (4 categories): "Lymphoid", "Myeloid", "Stromal", "Epithelial"
- `column_B` (8 categories): "T", "B", "NK", "Macrophage", "DC", "Fibroblast", "Endothelial", "Epithelial"
- Target fine cell type: "Treg" (from a refined annotation column)

Wrong: Use `column_A = "Lymphoid"` as the parent for computing %Treg
  → Lymphoid includes T + B + NK, diluting the denominator with unrelated lineages

Right: Use `column_B = "T"` as the parent
  → Tregs belong to the T cell lineage; B and NK cells should not be in the denominator

**Example B — Non-immune broad vs Mesenchymal:**

- `broad_labels` (5 categories): "T", "B", "Myeloid", "Non-immune", "Epithelial"
- `cluster_labels` (11 categories): "T", "B", "Myeloid", "MSC", "Endo", "Glia", "Epithelial", ...
- Target fine cell type: "POSTN+ myofibroblasts" (from a refined annotation column)

Wrong: Use `broad_labels = "Non-immune"` as the parent for computing %POSTN+ myofibroblasts
  → "Non-immune" lumps mesenchymal cells with endothelial cells and glia — different lineages

Right: Use `cluster_labels = "MSC"` as the parent
  → Myofibroblasts are mesenchymal stromal cells; endothelial cells and glia should not
    be in the denominator

Rule: When multiple columns offer broad groupings, do not default to the column
with fewer categories. For each fine cell type, pick the column whose category
is the **narrowest biological compartment** that still contains the target.
Cross-check by asking: "what other fine cell types fall under this parent?"
If the parent includes cells from a different lineage, it is too broad.

---

### 31. Testing Subtype-Specific Claims at the Broad Compartment Level ⚠️ (NEW)

**Example A — T cell and B cell subtypes:**

Paper: "CD8+ exhausted T cells secrete CXCL13, which binds CXCR5 on follicular B cells"
Dataset has: `CellTypes_refined` with "Exhausted CD8+ T", "Effector CD8+ T",
"Naive CD4+ T", "Follicular B", "Memory B", etc., plus a broad column with
"T", "B", "Myeloid", ...

Wrong: Correlate avg CXCL13 in all T cells vs avg CXCR5 in all B cells
  → Dilutes the signal with Naive CD4+ T, Effector CD8+ T, Memory B, etc.
    that are not part of the claimed interaction

Right: Correlate avg CXCL13 in **Exhausted CD8+ T** vs avg CXCR5 in **Follicular B**
  → Matches the paper's specific claim about which subtypes are involved

**Example B — Fibroblast and macrophage subtypes:**

Paper: "ACTA2+ myofibroblasts secrete WNT5A, which activates FZD5 on
TREM2+ lipid-associated macrophages"
Dataset has: `subtype_labels` with "ACTA2+ myofibroblasts", "COL14A1+ fibroblasts",
"PI16+ fibroblasts", "TREM2+ LAMs", "FOLR2+ macrophages", etc., plus a broad
column with "Stromal", "Myeloid", ...

Wrong: Correlate avg WNT5A in all Stromal cells vs avg FZD5 in all Myeloid cells
  → Stromal includes endothelial, pericytes, other fibroblast subtypes that
    may not express WNT5A; Myeloid includes DCs, monocytes, other macrophages
    that may not express FZD5

Right: Correlate avg WNT5A in **ACTA2+ myofibroblasts** vs avg FZD5 in **TREM2+ LAMs**
  → Directly tests the claimed signaling axis between the specific subtypes

Rule: When the paper claims a specific subtype produces a ligand that acts on
another specific subtype, the primary cross-cell-type correlation must use those
exact subtypes — not their broad parent compartments. If per-sample cell counts
in the specific subtypes are low, the broad-compartment version can be added as
a supplementary robustness check, but never as the primary test.

**IMPORTANT — apply to BOTH sides.** A common mistake is upgrading only one
side of the cross-cell-type pair to the specific subtype while leaving the
other side as the broad compartment. For example, if the paper says
"Subtype-X secretes ligand L, which binds receptor R on Subtype-Y", the
primary test must be L in **Subtype-X** vs R in **Subtype-Y** — not
L in Subtype-X vs R in all Myeloid. Check both the source and the target
cell types against the paper's claim.

---

### 32. Pooling Multiple Named Target Subtypes Without Testing Each Individually ⚠️ (NEW)

Paper: "IL-10 from Tregs acts on IL10RA on both M2 macrophages and tolerogenic DCs"
Dataset has: "Treg", "M2 macrophage", "Tolerogenic DC" in a refined annotation column

Wrong: Only test avg IL10 in Tregs vs avg IL10RA in M2 macrophages + tolerogenic DCs pooled
  → Hides which target subtype drives the correlation; one may respond, the other may not

Right: Three tests:
  1. avg IL10 in Tregs vs avg IL10RA in **M2 macrophages** (individual)
  2. avg IL10 in Tregs vs avg IL10RA in **tolerogenic DCs** (individual)
  3. avg IL10 in Tregs vs avg IL10RA in M2 + tolerogenic DCs pooled (supplementary)

Rule: When the paper names multiple specific subtypes as targets of the same
signal, test each subtype individually as separate correlations. The pooled
version can be included as supplementary, but individual tests are the primary
analyses — the signal may differ between subtypes.

---

### 33. Testing Reprogramming/Conversion/Differentiation/Trajectory Claims With Static Proportion Tests ⚠️ (NEW)

This applies to ALL dynamic cell-state transition claims, including:
- Reprogramming (e.g., "Subtype-A macrophages reprogram into Subtype-B")
- Precursor-product differentiation (e.g., "CD14+ monocytes differentiate
  into TREM2+ macrophages")
- Lineage conversion (e.g., "Epithelial cells undergo EMT into mesenchymal cells")

Paper: "Subtype-A cells convert/differentiate into Subtype-B cells
in the tumor microenvironment"

Wrong (Section 2): "Correlate Ligand-X in stromal cells vs %Subtype-A
T cells — expect negative if Ligand-X drives conversion of A → B"
  → This conflates the signaling axis (does Ligand-X reach T cells?)
    with the conversion outcome (are A cells becoming B cells?). These
    are separate claims. The signaling axis can be tested; the conversion
    cannot.

Right: Keep the conversion/differentiation/reprogramming claim in
**Section 3 (NOT TESTABLE)** — trajectory inference, RNA velocity, or
lineage tracing is required. But create proportion-based proxy tests
in Section 2 for the involved subtypes. Also test the signaling
components separately as their own pieces (e.g., Ligand-X in cell
type A vs Receptor-Y on cell type B is a valid signaling test), and
test characterization of the subtypes separately (e.g., marker-A
higher in Subtype-A than Subtype-B is a valid characterization test).

Rule: The conversion outcome itself goes in Section 3. But proportion
tests for the involved subtypes should be created in Section 2 as
proxy tests.

---

### 34. Spatial Claims Placed in Section 3 Without a Proportion-Based Proxy in Section 2 ⚠️ (NEW)

When a paper claims a spatial phenomenon (e.g., "cell-type A forms a
barrier that excludes cell-type B," or "cell-type A and cell-type B
physically co-localize"), the spatial claim itself belongs in Section 3
(NOT TESTABLE — requires spatial transcriptomics).

However, if the relevant cell types are present in the dataset, a
**proportion-based proxy test** should also be created in Section 2.
This proxy cannot confirm or deny the spatial claim, but it provides
indirect evidence about whether the compositional pattern is consistent
with the spatial model.

Example: Paper claims "cell-type A forms a barrier that excludes
immune cells from the tumor core."
- Section 3: "Physical barrier/exclusion is a spatial claim — NOT
  TESTABLE from dissociated scRNA-seq."
- Section 2 (proxy): "Correlate per-sample proportion of cell-type A
  with per-sample proportion of T cells, B cells, NK cells — expect
  negative if exclusion model holds. Label as proxy: proportion-based
  proxy for spatial claim; null result does not disprove the spatial
  mechanism."

Wrong: Put the entire claim in Section 3 with no proxy, losing the
  ability to test even the compositional correlate.

Right: Section 3 for the spatial claim + Section 2 for the proportion
  proxy, clearly labeled as a rough proxy with appropriate caveats.

Rule: For every spatial claim in Section 3, check whether the relevant
cell types exist in the dataset. If they do, create a proportion-based
correlation test in Section 2 as a proxy, with an explicit disclaimer
that it cannot confirm the spatial mechanism.

For trajectory/conversion claims (Error 33), the conversion outcome
itself is not testable, but proportion-based proxy tests for the
involved subtypes should still be created in Section 2.

---

### 35. Total-Cell Proportion Artifact in Cross-Compartment Correlations ⚠️ (NEW)

When correlating proportions of cell types from different compartments
(e.g., stromal subtype vs immune subtype), using total-cell proportions
for both sides creates a compositional artifact.

Example: The paper claims "high Subtype-X infiltration suppresses
Subtype-Y abundance." If Subtype-X is condition-enriched (e.g., higher
in treated vs untreated) and Subtype-Y has a different distribution
between conditions, any negative correlation using total-cell proportions
just proves "condition A ≠ condition B in composition" — not that
Subtype-X specifically suppresses Subtype-Y.

Wrong: Correlate %Subtype-X / total cells vs %Subtype-Y / total cells
  across all samples (mixing conditions)
  → The condition shift dominates. Condition A has more X and possibly
    less Y simply because the overall composition differs.

Right:
  (a) Use parent-compartment proportion for the predictor:
      %Subtype-X within its parent compartment rather than
      %Subtype-X / total cells
  (b) Test within-condition: among condition-A samples only, does
      higher %Subtype-X / parent correlate with lower %Subtype-Y?
  (c) The within-condition test is the real test. The overall
      correlation mixing conditions is uninformative for the claim.

Rule: For cross-compartment proportion correlations (proxy tests for
exclusion, suppression, or compositional effects across lineages),
use parent-compartment proportions and emphasize within-condition
results. Note in the piece description that overall correlations
mixing conditions are compositionally confounded.

---

### 36. Correlating Signatures Against Each Other to Test "Which Is Better" ⚠️ (NEW)

When the paper claims its signature outperforms competitors (lower bias,
higher AUROC, better survival prediction), do NOT create pieces that
correlate the signatures against each other — correlation between scores
does not test "which is better." Instead, for each signature (including
competitors), create a boxplot comparing the score between conditions
(e.g., tumor vs normal, or by stage if available) as extra exploration.
This tests whether each signature captures disease-relevant variation in
this dataset.

Wrong: "Correlate Signature A score vs Signature B score across samples"
  → A positive correlation just means they rank samples similarly, not
    that one outperforms the other

Right: "For each signature (A, B, C...), boxplot of score in condition 1
  vs condition 2" → shows which signatures capture the condition
  difference in this dataset

---

### 37. Skipping Intermediaries in a Mechanistic Chain ⚠️ (NEW)

Paper: "Gene A activates Gene B, which activates Gene C, which drives Gene D"
Wrong: Test Gene A vs Gene D directly (skips B and C)
Right: Test each adjacent pair: A vs B, B vs C, C vs D.
       If A vs D is also informative, include it as a supplementary
       full-chain test, but the adjacent pairs must each be tested
       individually.

Rule: When decomposing a mechanistic chain into testable pieces, test
each adjacent pair of nodes. Do not skip intermediaries by testing only
the endpoints. Each link in the chain (A→B, B→C, C→D) is a separate
testable claim. Endpoint-to-endpoint tests (A→D) can supplement but
never replace the adjacent pair tests.

---

## Verification Checklist

| Check | Question |
|-------|----------|
| Summary screening | Is this a summary sentence? If so, skip. |
| Redundancy check | Does this duplicate a previous analysis? If so, consolidate. |
| Section assignment | No processing needed for Section 1? |
| Cell type accuracy | Gene assigned to correct cell type from paper? |
| Cross-cell-type signaling | A→B signaling chains split into ligand-receptor (cross-cell-type) + receptor-effector (same-cell-type) pieces (Error 16)? |
| Correlation direction | Expected direction stated and justified? |
| Gene list source | Checked definitions_final.txt first? |
| Gene list | All genes listed explicitly for signatures? |
| Score definability | Can this score actually be defined in scRNA-seq? |
| Brainstorm link | `From brainstorm: Finding #X, Piece X.Y` included? |
| Proxy notation | mRNA-as-proxy labeled as such with "do not expect" note? |
| Column names | Real column names from data_pre.txt AND data_pre_add.txt used? |
| Sample column | Sample column identified? Preferred over patient when both exist? |
| Added annotations | `data_pre_add.txt` inspected and used where applicable? |
| orig.ident check | `orig.ident` column inspected for cell types, patient IDs, or other useful info? |
| Metadata check | Required conditions confirmed in native OR added metadata? |
| CNV flag | Any CNV-dependent finding flagged as out of scope? |
| Analysis type | Specific analysis stated (not just "compare")? |
| Correlation + Boxplot | Both assigned for activation/promotion claims? |
| DE + Enrichment | Included for broad pathway claims? |
| GatingProportion | Used for composite high/low-marker populations (not arithmetic hacks)? |
| Stratified analyses | Proposed for each testable piece using available metadata? |
| Extra tests | Dataset-driven tests proposed after paper-driven pieces? |
| Preferred approach | When multiple options, is preference stated? |
| Annotation proportion | Used existing annotation proportion instead of module score where applicable? |
| Cell type comparison | Pattern 4 boxplots pool all samples (no condition split)? |
| Extra test scope | Each extra test is ONE simple analysis, not detailed breakdowns? |
| Combined grouping | Similar boxplots combined into single group column? |
| Individual gene rule | ≤5 genes: individual plots + combined; >5 genes: combined only? |
| Spatial proxy | Every Section 3 spatial claim has a proportion-based proxy in Section 2 (if cell types exist)? |
| Trajectory vs spatial | Trajectory conversion not testable, but subtype proportion changes between conditions should be tested as characterization (Error 33); spatial claims DO have a proportion-based proxy (Error 34)? |
| Cross-compartment proportions | Proxy tests use parent-compartment denominators and emphasize within-condition results (Error 35)? |
| Signature comparison | Not correlating signatures against each other — using per-signature condition boxplots instead (Error 36)? |
| Adjacent pair testing | Each link in the mechanistic chain tested as an adjacent pair, not skipping intermediaries (Error 37)? |
