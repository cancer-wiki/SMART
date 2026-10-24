---
name: extract-definitions-v1-agent
description: "Given a paper summary, extract all definitions that would need to be checked in the original paper before the summary can be validated in an independent scRNA-seq dataset."
model: opus
---

## Purpose
Given a paper summary, extract all definitions that would need to be checked in the original paper before the summary can be validated in an independent scRNA-seq dataset.

## Key Principle
**The goal is to enumerate what you need to look up — not to answer the questions.** For each piece of the summary, ask: "Can I operationalize this in scRNA-seq, and do I have an unambiguous definition to do it?"

---

## Input/Output Files
```
Outputs/summary.txt    # Input: paper summary
Working/definitions_needed.txt        # Output: Definition extraction report
```

---

## Workflow Overview

Phase 1: Sentence-by-sentence summary scan → Phase 2: Apply decision logic per entity → Phase 3: Deduplicate and output

---

## Process

### Phase 1: Sentence-by-Sentence Summary Scan

Read `Outputs/summary.txt` carefully.

Break the summary into individual sentences or clause-level units. For each unit, identify every entity that appears:
- Cell types or subtypes
- Gene sets, pathways, or signatures
- Phenotypes or biological states
- Single genes
- Molecular events (protein modification, metabolite change, biophysical property)

When the paper measures an entity by a method that is NA for scRNA-seq (ChIP, Co-IP, immunofluorescence), that does not make the entity NA. Ask independently whether the entity's abundance has a transcriptional proxy. A complex measured by ChIP in the paper can still be proxied by its subunit's mRNA in scRNA-seq — flag the proxy; do not inherit the paper's assay as the reason to skip.
Your job is to enumerate what can be checked, not to decide whether checking it is worthwhile. If an entity has a transcriptional proxy, list it in the master output, even if the specific claim around it (e.g. a spatial or occupancy claim) cannot be fully validated. 

### Phase 2: Apply Decision Logic Per Entity

For each entity identified, walk through the following decision tree:

#### Step 1: Can this be observed in scRNA-seq at all?

Skip (mark as NA) if the entity is:
- A **biophysical property** (phase separation, membrane potential, lysosomal acidity)
- A **metabolite measurement** (e.g., NAD+/NADH ratio, lactate concentration, intracellular ATP levels)
- A **protein-level behavior or modification** (phosphorylation state, glycosylation pattern, binding affinity, nuclear localization, protein cleavage)
- A **functional assay with no transcriptional readout** (transwell migration, wound healing, tumor volume by caliper, colony formation)

**Important distinction:** Protein-level *behavior/modification* is not observable in scRNA-seq, but protein *expression/abundance* can be approximated by mRNA level. For example:
- SMAD3 nuclear localization → skip (post-translational localization)
- SMAD3 expression level → checkable (mRNA proxy)
- Ligand-receptor binding affinity → skip (protein interaction)
- TGFBR2 expression on stromal cells → checkable (mRNA proxy)
A named protein complex (a polymerase, a chromatin-remodeling complex, the ribosome) is not a single gene, but its abundance can often be proxied by a defining subunit's mRNA. Do not skip the complex outright — flag it as "check the paper's defining subunit; proxy by that subunit's mRNA."

If the entity cannot be observed in scRNA-seq → mark as **NA** with a brief reason (e.g., "biophysical property, skip" or "metabolite-level, skip").

If it can → proceed to Step 2.

#### Step 2: Is it a single gene?

If the entity is a single named gene (e.g., TGFB1, MYC, TP53, NOTCH1, VEGFA, COL1A1) → **no definition needed**. Single genes are unambiguous.

If not → proceed to Step 3.

#### Step 3: Is it a cell type?

- **Broad consensus cell types** with well-established, field-standard markers (CAF, CD8+ T cell, macrophage, NK cell, dendritic cell, stromal cell, epithelial cell) → **no definition needed**, mark as "general cell type"
- **Subtypes or context-specific cell states** (e.g., FOLR2+ tissue-resident macrophages, CD36-high pericytes, SPP1+ tumor-associated macrophages, LAMP3+ mature dendritic cells) → **definition needed**. Different papers may define these differently; you need the exact marker combination or criteria this paper used.
- **Mouse-specific markers** (e.g., Ly6G, F4/80, Siglec-F) → additionally flag: need human equivalent if the target dataset is human.

Note: Even "general" cell types that are notoriously poorly standardized (e.g., MDSC, M2 macrophage) should be flagged for definition check, because the field does not agree on what these are.

If not a cell type → proceed to Step 4.

#### Step 4: Is it a gene set, pathway, or signature?

- If the text lists **example genes** but implies there are more (e.g., "acute-phase genes (SAA1, CRP, HP)", "glycolysis genes", "antioxidant pathways") → flag as **"check if the listed genes are the complete set or if more exist in the paper/supplementary"**
- If a **pathway name** is referenced without a gene list ("MAPK/ERK pathway genes", "Wnt signaling") → flag as **"check whether the paper provides an explicit gene list or references a database (MSigDB, KEGG, Reactome, etc.)"**
- If a **scoring method** is implied ("XX score", "exhaustion signature") → flag as **"check scoring method (ssGSEA, AUCell, average z-score, etc.) and the exact gene list"**

**Key framing:** Do NOT assume gene lists are complete or incomplete. Use neutral language: "check if complete" rather than "need the full list of 50 genes."

If not a gene set → proceed to Step 5.

#### Step 5: Is it a phenotype or biological state?

For phenotypes like proliferation, senescence, apoptosis, epithelial-mesenchymal transition, angiogenesis, fibrosis, drug resistance, stemness, autophagy, ferroptosis:

Ask: **"Does the paper define this with a gene list/signature that lives in the transcriptome, or only by experimental measurement?"**

- "Senescence" → could be a gene signature (which one? Fridman? SASP genes?) or SA-β-gal staining — flag as "check how defined"
- "Proliferation" → could be MKI67/cell cycle genes or a BrdU assay — flag as "check how defined"
- "Angiogenesis" → likely functional assay (tube formation) — flag as "check if transcriptional proxy exists"
- "Ferroptosis" → could be lipid peroxidation measurement or gene signature — flag as "check if gene-level characterization exists or if purely functional"
- "Sumoylation" → post-translational modification but may have associated enzyme expression (SUMO ligases) — flag as "check if related genes are defined"

**The question is always "is there a definition that lives in the transcriptome?" — not "what is the definition?"**

#### Step 6: Has this already been flagged?

- If a term was already flagged in an earlier sentence (e.g., tumor growth, proliferation, a specific gene list) → do NOT re-flag. Instead write: "mentioned before, no new def needed"
- **Conclusion or consequence sentences** that restate earlier findings without introducing new measurable entities → mark as **NA**

---

### Phase 3: Deduplicate and Output

After processing all sentences:

1. Compile the sentence-by-sentence table
2. At the end, produce a **deduplicated master list** of all unique definitions needed, grouped by type:
   - Cell type/subtype definitions
   - Gene set/pathway/signature definitions (with "check if complete" notes)
   - Phenotype definitions (with "check if transcriptional proxy exists" notes)
   - Single genes
   - proxies
   
Every entity with a transcriptional proxy or needing a definition goes in the master list, each with any limitation noted. Do not omit an entity because its surrounding claim is only partly checkable.

---

## Output Format

### `Working/definitions_needed.txt`

#### Part 1: Sentence-by-Sentence Breakdown

For each summary sentence, produce:

```
SENTENCE: [exact sentence from the summary]
DEFINITIONS NEEDED: [what needs checking, or NA with reason]
```

#### Part 2: Master Definition Checklist

```
=== CELL TYPE / SUBTYPE DEFINITIONS ===
1. [cell type] — need: [what to check]
2. ...

=== GENE SET / PATHWAY DEFINITIONS ===
1. [gene set name] — need: [check if complete / check source database]
2. ...

=== PHENOTYPE DEFINITIONS ===
1. [phenotype] — need: [check if transcriptional definition exists]
2. ...

=== SINGLE GENES ===
1. [gene]
2. ...

=== PROXIES ===
1. [proxy] — [entity it measures, any limitation]
2. ...
```

---

## Examples

These examples use unrelated biological contexts to illustrate the annotation logic.

### Example: Good annotation (cell subtype needing definition)

```
SENTENCE: FGF2 signaling activates CD36-high pericytes in the tumor vasculature, inducing a tip-cell-like endothelial phenotype.
DEFINITIONS NEEDED: CD36-high pericytes — need marker definition for scRNA-seq (what threshold for "high"? which additional pericyte markers?). Tip-cell-like endothelial phenotype — poorly standardized state, need exact definition used in this paper.
```

### Example: Correctly skipping (biochemical/biophysical)

```
SENTENCE: PRMT5 symmetrically dimethylates histone H4R3, altering nucleosome accessibility at Hox gene promoters.
DEFINITIONS NEEDED: NA — symmetric dimethylation is a post-translational modification, not observable in scRNA-seq.
```

### Example: Gene set check (partial list given)

```
SENTENCE: STAT3 activation upregulates acute-phase response genes (SAA1, CRP, HP) in hepatocytes during systemic inflammation.
DEFINITIONS NEEDED: Acute-phase response genes — SAA1, CRP, HP are listed as examples. Check if this is the complete list or if additional genes are reported in the paper/supplementary.
```

### Example: Phenotype check (may or may not have transcriptional proxy)

```
SENTENCE: Loss of LATS1 causes cytokinesis failure, leading to multinucleation and aneuploidy in cardiomyocytes.
DEFINITIONS NEEDED: Cytokinesis failure, multinucleation, aneuploidy — check if these are characterized by gene lists/signatures or only by imaging/flow cytometry.
```

### Example: Not re-flagging (already captured earlier)

```
SENTENCE: Transplantation of GATA4-expressing fibroblasts is sufficient to drive cardiac hypertrophy in recipient mice.
DEFINITIONS NEEDED: NA — cardiac hypertrophy definition was flagged in earlier sentence.
```