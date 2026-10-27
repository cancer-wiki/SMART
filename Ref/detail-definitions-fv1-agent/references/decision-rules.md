# Phase 3: Decision Rules for Final Definitions

## Goal
For every term (both RESOLVED and CHECK_SUPP), apply these rules to produce a final definition that is usable on another scRNA-seq dataset.

## Precondition
Apply these rules to ALL terms, including routed ones. For Route A terms, write `external ref (pending)` as the placeholder definition — the pipeline will run the external agent separately and update the file later. For Route B terms, write `external package (pending)` as the placeholder. Do NOT fabricate gene lists or coerce routed terms into a KEGG/MSigDB pathway name.

---

## STRICT OUTPUT RULES

**These rules are absolute. No exceptions.**

**0. Definition Type MUST be one of these exact values — no inventing new types:**
   - `general cell type`
   - `gene list from paper`
   - `gene list from supp`
   - `KEGG/MSigDB`
   - `single gene`
   - `external ref (pending)`
   - `external package (pending)`

   NEVER use values like "proxy pathway", "composite functional phenotype", "paper-validated", "no transcriptomic definition", "cell line identity", etc. If the term needs a proxy pathway, the type is `KEGG/MSigDB`. If the paper validated a gene list, the type is `gene list from paper`.

1. If Definition Type = `general cell type` → Final Definition = literally `general cell type`. NOTHING ELSE. No markers, no genes, no mouse/human conversion, no parenthetical notes. Paper Definition column should also be brief.
2. If Definition Type = `KEGG/MSigDB` → Final Definition = **exactly one** KEGG or MSigDB pathway name (e.g., `HALLMARK_G2M_CHECKPOINT`). NEVER list individual genes. NEVER mix genes and pathway names. NEVER give two pathway options with "or". Pick ONE.
3. If Definition Type = `gene list from paper` → Final Definition = the exact genes the paper highlighted.
4. If Definition Type = `gene list from supp` → Final Definition = the genes extracted from the supplementary file.
5. If Definition Type = `single gene` → Final Definition = just that one gene symbol. No aliases, no parenthetical protein names.
6. **ONE definition per term.** Never give two options. Never say "X or Y". Never say "supplement with KEGG" on top of a gene list. Pick one.
7. Gene list definitions CAN include mouse/human notes and "(self-proposed)" labels when the definition is converted from experiment-based markers to scRNA-seq gene symbols.
8. **Composite terms → one final definition per component.** If a term is an umbrella covering multiple distinct biological processes or subtypes, break it into separate rows — one per component. This applies to:
   - Supp tables with multiple subtype columns → one row per subtype
   - Composite functional phenotypes that bundle distinct biological processes → one row per process, each with its own definition or proxy
   - Never flatten distinct components into one row. Label sub-rows as `3a`, `3b`, `3c` or `Term: Component`.
   - **Decide the split early.** When you identify a composite term during Phase 1/2, write the split in the DECISION line of `definitions_detail.txt`. For example, if a term covers both metabolic activity and cell motility, the DECISION should already list each component with its own proxy (e.g., "Composite — split into Na: metabolic component → KEGG_PATHWAY_X, Nb: motility component → HALLMARK_PATHWAY_Y"). Do not collapse into one row later.
9. **Do NOT self-exclude entries the paper explicitly highlighted.** If the paper names a gene (in text, in a figure label, in a heatmap, or in any highlighted location) as part of the answer for a term, include it — even if you personally think it doesn't fit the biological category. The paper's framing wins over your category judgment.

---

## RELIABILITY HIERARCHY (when multiple definition sources exist)

When a term has MORE THAN ONE candidate definition (e.g., paper-highlighted subset + supp list + pathway name), pick the single most reliable source. Rank sources by reliability:

```
TIER 1 (highest reliability):
  • Gene list that was specifically validated by a follow-up experiment
    (qPCR, Western, knockdown, IHC, ChIP-seq, ChIP-PCR, RT-qPCR, etc.)
  • Gene list that the paper selected out of a broader enrichment result
    and then did further experiments on (this INCLUDES cases where a
    pathway was enriched and the paper then validated N specific genes
    from that pathway — use the validated gene list, not the pathway)
  • A pathway the paper explicitly singled out as THE finding and did
    NOT further validate any gene subset of it

TIER 2:
  • A supp list that is category-specific (all genes are in one clean category
    matching the term)
  • A gene list highlighted in the main text with a clear, specific reason

TIER 3:
  • A pathway or gene set mentioned in passing in the main text
    (no follow-up experiment, no gene validation)

TIER 4 (lowest reliability — avoid unless nothing else is available):
  • A big mixed supp DE table (not category-specific)
  • A vague enrichment list with many pathways
```

**Selection rule:** always pick the highest-tier source available and use ONLY that. Never merge across tiers. Never say "use X, supplement with Y".

**Key question to decide between a pathway and a gene list:**
> Did the paper do ANY follow-up experiment on a specific subset of genes after mentioning the pathway?
>
> - YES → use the validated gene list (Tier 1). The pathway was just the bridge to find them; the validated genes are the finding.
> - NO → use the pathway (it was the terminal finding).

This applies EVEN IF:
- The paper lists the pathway first and prominently
- The pathway has a clean, well-known KEGG/MSigDB name
- The validated gene set is small (even 2–3 genes is enough if they were the target of a dedicated experiment)
- The paper mentions validated genes only as "examples" of the pathway — if an experiment was done on them, they are not mere examples

**Common conflict patterns:**

| Situation | Pick |
|-----------|------|
| Paper highlights small validated subset + supp has huge mixed DE table | The validated subset (Tier 1 beats Tier 4) |
| Paper reports pathway enrichment + then validates N genes from it by qPCR / ChIP / knockdown / rescue | The validated gene list (Tier 1 beats Tier 3) |
| Paper gives illustrative examples + supp has clean category-specific list | The clean supp list (Tier 2 beats Tier 3) |
| Paper names one specific pathway + a broader enrichment list in supp | The specific pathway (Tier 1 beats Tier 4) |
| Paper gives a gene list + a pathway name for the same concept, AND the gene list was validated by experiment | The gene list (Tier 1) |
| Paper gives a gene list + a pathway name, gene list is purely illustrative and NO experiment was done on them | The pathway (Tier 2/3 beats illustrative gene list) |

---

## HIGHLIGHT vs FULL LIST RULE (for gene lists)

When the paper highlights a subset of genes in the text AND a supp file has the complete list:

```
Did the paper highlight the subset for a specific reason?
  │
  ├── YES (e.g., they did further experiments on the subset,
  │    validated by qPCR/Western/IHC, or specifically discussed them)
  │     → Use the HIGHLIGHTED SUBSET only
  │
  └── NO (the paper just mentioned a few as examples,
       no special reason for choosing those over others)
        │
        └── Does the complete list in supp contain ONLY
            relevant genes (i.e., all the same category)?
              │
              ├── YES (e.g., supp list is all TGF-β pathway genes,
              │    all cytokines, all TFs of the same pathway)
              │     → Use the FULL LIST from supp
              │
              └── NO (supp list contains mixed/unrelated genes,
                   or genes outside the scope of the term)
                    → Use the HIGHLIGHTED SUBSET only
```

**Examples (illustrative patterns — do not treat as ground truth):**

Example 1 — Use highlighted subset:
- Paper: "Among pathway-X genes, GeneA and GeneB were further validated by IHC (Fig. 5a)"
- Supp has 20 pathway-X related genes, with the 2 validated ones among them
- Decision: Use GeneA, GeneB only (they were specifically validated)

Example 2 — Use full supp list:
- Paper: "Pathway-X signaling genes including GeneA, GeneB, and GeneC were upregulated (Supp Table 4)"
- Supp Table 4 contains GeneA through GeneJ — all pathway-X genes
- No further experiment on the highlighted subset
- Decision: Use full list (all 10 genes)

Example 3 — Use highlighted subset (supp is mixed):
- Paper: "Key immune genes including GeneA, GeneB, and GeneC were upregulated (Supp Table 2)"
- Supp Table 2 is a dump of 500 DEGs including many non-immune genes
- Decision: Use GeneA, GeneB, GeneC only (supp list is not all the same category)

---

## SAME-SENTENCE SUBSET RULE

When two or more Section 2 terms come from the SAME sentence in the paper AND have the SAME grammatical treatment, they MUST receive the SAME Definition Type.

**How to identify a same-sentence group:**
- During Phase 1 grep, both (or all) terms appeared in the same grep-hit sentence
- Each term was followed by the same kind of descriptor (e.g., all introduced by "for example" + gene list, or all named as pathways without gene lists, or all validated by the same experiment)

**Why:** The paper's own framing treats these terms as peers. Choosing a gene list for one and a pathway for another breaks the parallel structure the paper intended, and produces inconsistent downstream results.

**Rule:**
1. Identify the whole same-sentence group first.
2. Determine the most appropriate definition type for the group as a whole, using the rest of the decision rules.
3. Apply that SAME definition type to every term in the group.

**Illustrative patterns:**

Pattern A — all same-sentence terms introduced by "for example" + genes:
- Sentence: "Cluster Q reflects diverse processes including pathway-P1 (for example, geneA, geneB), pathway-P2 (for example, geneC, geneD), and pathway-P3 (for example, geneE, geneF)."
- The paper is giving illustrative examples for each pathway, not defining them by those genes.
- Decision: Apply Definition Type = `KEGG/MSigDB` to ALL three terms (use the standard pathway name for each).

Pattern B — all same-sentence terms are operational gene lists:
- Sentence: "We defined group-P1 as geneA+geneB+, group-P2 as geneC+geneD+, and group-P3 as geneE+geneF+."
- The paper is operationally defining each group by specific markers.
- Decision: Apply Definition Type = `gene list from paper` to ALL three terms.

**Edge case:** If one term in a same-sentence group has independent strong evidence elsewhere in the paper (e.g., a dedicated validation experiment) that promotes it to a different definition type, you may break the parallel for that term only, but document the reason in the detail table.

---

## NOT-DIRECTLY-MEASURABLE-IN-SCRNA RULE (propose a proxy)

Some Section 2 terms refer to phenotypic processes or biological behaviors that cannot be read off single-cell expression directly. In these cases, propose the closest proxy gene set / pathway that captures the process.

**Patterns that usually need a proxy:**
- Behavioral/phenotypic processes (cell migration, invasion, adhesion, motility)
- Functional states defined by an assay output (e.g., "active secretion", "high proliferation index")
- Anything where the paper described the process but never listed marker genes or pathways for it

**Proxy selection:**
1. Use a well-known KEGG or HALLMARK pathway name. There is almost always a standard pathway that fits. Match the biological process name to its most obvious standard pathway — do not reason about the paper's specific mechanism or try to connect it to other terms in the paper.
2. The Final Definition MUST be a single pathway name — not a gene list, not "pathway OR gene list", not multiple options. ONE pathway name only.
3. Label the final definition with `(proxy)` as a suffix in the Final Definition column so downstream users know it was not explicitly listed in the paper.
4. In the detail table, note: `Not directly measurable in scRNA; proposed proxy: <pathway>`.

**Rule of precedence:** If the paper itself provides a gene list or pathway for the process, USE THAT — do not propose a proxy. Proxies are only for terms the paper mentions but does not operationalize.

**One definition only:** Even with a proxy, still only one final definition per term.

---

## Decision Tree

```
Is this term directly measurable in scRNA-seq?
  ├── NO (phenotypic process with no gene list in paper)
  │     → Definition Type: "KEGG/MSigDB"
  │       Final Definition: best-fit pathway name + "(proxy)"
  │       (see NOT-DIRECTLY-MEASURABLE-IN-SCRNA rule)
  │
  └── YES → continue below
            │
Is it part of a same-sentence group?
  ├── YES → note the group, and after finishing all group members,
  │         force them to share the same Definition Type
  │         (see SAME-SENTENCE SUBSET RULE)
  │
  └── NO / or continuing per-term:

Is it a general/well-known cell type?
  ├── YES → Definition Type: "general cell type"
  │         Final Definition: "general cell type"
  │         Paper Definition: brief, e.g., "general cell type"
  │         STOP. Nothing else. No markers. No genes.
  │         Examples: Treg, CD8 T cell, Macrophage, NK cell, B cell,
  │         Monocyte, Dendritic cell, Fibroblast
  │
  └── NO → How was it defined? Apply RELIABILITY HIERARCHY,
           pick the most reliable source, then:
            │
            ├── By experiment only (IHC, flow, Western, qPCR, etc.)
            │     and NO gene list provided in paper
            │     → Definition Type: "KEGG/MSigDB"
            │       Final Definition: a KEGG or MSigDB pathway name
            │
            ├── By experiment, but paper names specific genes/markers
            │     used in the experiment (e.g., "flow showed X+Y+Z+")
            │     → Definition Type: "gene list from paper"
            │       Final Definition: those gene symbols
            │       CAN include mouse/human notes and (self-proposed)
            │
            ├── By enrichment analysis only
            │     → Definition Type: "KEGG/MSigDB"
            │       Final Definition: a KEGG or MSigDB pathway name
            │       If paper points to supp with many pathways →
            │         use a standard well-known pathway name
            │       If paper explicitly names exactly one pathway →
            │         use that specific term
            │
            ├── By both experiment AND pathway
            │     → Definition Type: "KEGG/MSigDB"
            │       Final Definition: a KEGG or MSigDB pathway name
            │       Exception: if the experiment specifically validated
            │       a subset of genes (e.g., knockdown), use gene list
            │
            ├── By a gene list highlighted in the paper text
            │     → Apply HIGHLIGHT vs FULL LIST RULE above
            │       If using paper subset: Definition Type = "gene list from paper"
            │       If using supp full list: Definition Type = "gene list from supp"
            │
            ├── By a gene list in the supp only (paper says "see Supp Table X")
            │     → Definition Type: "gene list from supp"
            │       Final Definition: genes extracted from the supp
            │       If supp is a multi-column subtype table: record each
            │         subtype on its own row (see Multi-subtype rule below)
            │       If supp is a big mixed DE table and paper highlighted
            │         a clean subset: DOWNGRADE — use the paper subset instead
            │
            ├── By gene expression threshold (e.g., "X-high cells")
            │     → Definition Type: "gene list from paper"
            │       Final Definition: record as "X high" or "X high, Y high"
            │       Use official gene symbol, NOT alias
            │
            └── By a single gene
                  → Definition Type: "single gene"
                    Final Definition: just that one gene symbol
                    No aliases, no parenthetical protein names
                    If the paper refers to one protein/concept but multiple
                    genes encode it (e.g., isoforms, family members detected
                    by a pan-antibody), use "gene list from paper" instead
```

---

## Rule Details

### Rule 1: General Cell Types → ONLY "general cell type"

If the term is a commonly recognized cell type, write EXACTLY:
```
Definition Type: general cell type
Final Definition: general cell type
```

**This is absolute. Stop thinking. Ignore what the paper says about this term.** It does not matter if the paper defines these cells by cell lines, by markers, by CNV inference, by flow cytometry, or by any other method. The Final Definition is always literally `general cell type` — nothing else. No markers, no genes, no mouse/human equivalents, no parenthetical notes, no subcluster details, no cell line names, no CNV methods, no "for scRNA-seq application" instructions.

The downstream pipeline already knows how to identify general cell types. Your job is only to recognize the term as a general cell type and label it.

**Examples of general cell types:** Treg, CD8+ T cell, CD4+ T cell, NK cell, B cell, Macrophage, Monocyte, Dendritic cell, Neutrophil, Fibroblast, CAF, Epithelial cell, Endothelial cell, Malignant/cancer cells, Normal cells, Tumor cells

### Rule 2: KEGG/MSigDB → ONLY a Pathway Name

When definition type is KEGG/MSigDB, the final definition must be a single pathway name. Examples:
- `HALLMARK_G2M_CHECKPOINT` (for proliferation)
- `KEGG_GLYCOLYSIS_GLUCONEOGENESIS` (for glycolysis)
- `KEGG_OXIDATIVE_PHOSPHORYLATION` (for OXPHOS)
- `HALLMARK_INFLAMMATORY_RESPONSE` (for inflammation)
- `HALLMARK_TNFA_SIGNALING_VIA_NFKB` (for TNF signaling)
- `KEGG_CELL_CYCLE` (for cell cycle)
- `HALLMARK_INTERFERON_GAMMA_RESPONSE` (for IFN-gamma response)
- `KEGG_TGF_BETA_SIGNALING_PATHWAY` (for TGF-β signaling)

**NEVER** list individual genes when definition type is KEGG/MSigDB.

**Pathway selection rule:** If the paper points to supp with many enriched pathways → use a standard well-known pathway name. If the paper explicitly names exactly one pathway → use that specific term. Never copy a GO term ID when a KEGG/MSigDB equivalent exists and the paper was vague.

### Rule 3: Gene List → Apply Reliability Hierarchy + Highlight vs Full List

When multiple gene lists are available:
1. First check the RELIABILITY HIERARCHY — if one source is clearly higher tier, use it.
2. If both sources are at similar reliability, apply the HIGHLIGHT vs FULL LIST rule.
3. Was the highlighted subset further validated/experimented on? YES → subset only.
4. No validation + supp is all same category → full supp list.
5. No validation + supp is mixed → subset only.

**Special case:** If the paper mentions both a pathway and a gene list, and the gene list was singled out by an experiment → use the gene list. If the gene list is just illustrative → use the pathway.

### Rule 4: Experiment-Based Gene Definitions → Self-Proposed OK

When the paper uses experiment markers (e.g., flow cytometry: X+Y+Z+), and you convert them to scRNA-seq gene symbols:
- CAN include mouse/human gene name notes
- CAN label as "(self-proposed)"
- This is the ONE exception where extra annotation is allowed

### Rule 5: Single Gene → Just the Symbol

- Right: `CD274`
- Wrong: `CD274 (PD-L1)`

### Rule 6: ONE Definition Per Term

Never give two options. Never say "use X, supplement with Y". Pick one definition. If both a gene list and a pathway are available, apply Rule 3's special case plus the RELIABILITY HIERARCHY to decide.

### Rule 7: Always Use Official Gene Symbols

When the paper uses a gene alias or protein name, always convert to the official gene symbol:
- Paper says "PD-L1 high" → record as `CD274 high`
- Paper says "F4/80+" → record as `ADGRE1 high`

### Rule 8: Multi-Subtype Supp Tables → One Definition Per Subtype

If Phase 2 identified a supp table where each column represents a distinct subtype of one umbrella group, you MUST NOT merge columns:

- If the Section 2 term names the umbrella group and the downstream user almost certainly wanted the subtypes resolved separately, produce one Final Definition row per subtype (e.g., one row for each column), labeling each with its subtype name.
- If the Section 2 term names one specific subtype, use only that column.
- Never flatten all columns into a single gene list — this mixes distinct sub-populations.

### Rule 9: Same-Sentence Subsets Share a Definition Type

See SAME-SENTENCE SUBSET RULE above. Terms introduced in the same sentence with the same grammatical treatment must share the Definition Type.

### Rule 10: Propose a Proxy for Non-Measurable Processes

See NOT-DIRECTLY-MEASURABLE-IN-SCRNA RULE above. For processes the paper mentions but never operationalizes with genes or pathways, propose the closest KEGG/MSigDB proxy and label with `(proxy)`.

### Rule 11: Validated Gene Subset BEATS the Enriched Pathway It Came From

When a paper reports a pathway enrichment AND then performs follow-up experiments on a specific gene subset drawn from that pathway, the validated gene subset is the correct final definition — NOT the pathway name.

Follow-up experiments that trigger this rule include (but are not limited to):
- RT-qPCR / qPCR validation
- ChIP-seq / ChIP-PCR
- Knockdown / knockout / overexpression
- Rescue experiments
- Western blot
- IHC
- Any directed assay on a specific gene set

The paper's logic is: "pathway was enriched → we validated these N genes from it." The pathway was a discovery tool; the validated genes are the actual finding. Use the validated genes.

**If there are multiple validation steps with different gene counts** (e.g., 33 candidates → 24 downregulated → 8 bound by ChIP), use the largest set that was experimentally addressed. This is typically the set the paper identifies as "the pathway-associated genes" after all validation. If the paper ambiguously reports several stages, default to the candidate set that entered validation (not the final smallest stratum), unless the paper explicitly concludes with only that smallest stratum.

**Do NOT fall back to the pathway name just because:**
- The pathway has a cleaner, more standardized name
- The gene list looks "messier"
- You feel a pathway would be easier to run on scRNA-seq

The validated gene list IS the definition the paper stands behind.

### Rule 12: No Self-Exclusion of Paper-Highlighted Entries

If a gene (or pathway component) is highlighted by the paper in ANY of the following locations, include it in the definition regardless of your own biological judgment about whether it fits the category:

- Named in the main text as part of the term's description
- Labeled on a figure panel (including heatmaps, volcano plots, bar charts, spatial maps)
- Listed in the supp table for the relevant comparison
- Shown in a validation experiment for the term

**Do NOT silently drop a gene because:**
- It's not a "classical" member of the category by textbook definition
- You think another gene from the same family would be more "correct"
- It's named slightly differently than you'd expect (e.g., a family member, a pseudogene, a related factor)
- It's a recently characterized gene you're less confident about
- A database you're consulting categorizes it differently

**What to do instead:** If a paper-highlighted gene really does not fit, record it anyway and add a short note in the detail table (NOT in the final definition) explaining the paper's choice. The final definition follows the paper.

**The paper's framing wins over your category judgment.** If the paper chose to highlight the gene as part of the term's answer, that is the operational definition for this work.

### Rule 13: Reagent-Defined Targets → Resolve the Reagent, Then Map to RNA

When the paper defines a term ONLY by the reagent it used — a drug, inhibitor, antibody, catalog
number, clone ID — and never states what that reagent acts on, do NOT infer the target from the
reagent's name or label. Resolve what the reagent actually binds or inhibits, then map that resolved
target to RNA.

**Trigger requires BOTH:**
- The paper names a reagent but not what it acts on (no gene, isoform, or subunit given)
- The reagent is the only definition available after Phase 1 + Phase 2

**Step 1 — Resolve the reagent.** Establish what it acts on: one gene product, a family, or a complex.
Check these sources in order, stopping at the first that answers:

  a. **The paper itself** — grep BOTH `Inputs/paper1_text.txt` AND `Inputs/paper1_method.txt` for the
     REAGENT (catalog number, clone ID, drug name), not for the term. Earlier grepping searched the
     term; the methods often name the target beside the reagent where the term never appears.
  b. **The supplementary files** — reagent/antibody tables frequently list targets per catalog number.
  c. **Online** — only if the paper and supp are silent. Use the vendor/manufacturer page or a reagent
     database; prefer the source the paper's own catalog number points to.

Record the reagent identity, the resolved target, AND which source resolved it in
`Working/definitions_detail.txt`, so the resolution can be audited later. This counts as evidence, not
as an experimental detail. A target stated in the paper outranks one obtained externally; an external
resolution must be visible as such. If the paper and an external source disagree, record both, follow
the paper, and flag the mismatch.

**Step 2 — Map according to what the resolution showed:**

| Resolution | Final Definition |
|------------|------------------|
| Acts across a **family**, unable to separate its members | every member it acts on |
| Acts on **one member or subunit** | that member alone, when readable in scRNA-seq |
| Acts on a **complex**, where no single gene captures it | the closest scRNA-seq stand-in — its subunit genes, or a pathway |
| Acts on something with **no RNA readout** | a proposed stand-in, per the proxy handling elsewhere in this file |

---

## What NOT to Do

| Wrong | Right |
|-------|-------|
| `general cell type (classical monocytes)` | `general cell type` |
| `general cell type` with subcluster details | `general cell type` |
| List individual genes when type is KEGG/MSigDB | Use a pathway name |
| `genes X, Y, Z. Supplement with KEGG_PATHWAY_X` | Pick one — genes OR pathway, based on reliability hierarchy |
| Using paper's highlighted 3 genes when supp has full relevant list (same category, no validation) | Use full supp list |
| Using full supp list when paper validated a subset by experiment | Use validated subset only |
| Using big mixed supp DE table when paper highlighted a clean subset | Use the paper's highlighted subset (Tier 1/2 beats Tier 4) |
| Choosing the pathway name when the paper validated a specific gene subset from within that pathway | Use the validated gene subset (Tier 1 beats Tier 3) |
| Silently dropping a paper-highlighted gene because it's "not classical" for the category | Keep every paper-highlighted gene; the paper's framing wins |
| Flattening a multi-column subtype supp table into one flat list | Record each subtype separately |
| Assigning different definition types to terms from the same sentence with the same grammatical treatment | Force them to share the same definition type |
| Refusing to define a phenotypic process because paper has no gene list | Propose a proxy KEGG/MSigDB pathway with `(proxy)` label |
| Copy the paper's exact GO term ID when paper listed many pathways | Use standard KEGG/MSigDB name |
| Copy KEGG name when paper explicitly named one specific GO term | Use that specific GO term |
| Give two definitions for one term | Pick one definition |
| `PD-L1 high` | `CD274 high` (use official gene symbol) |

---

## Writing the Final Output

### definitions_detail.txt
Update all rows with the Final Definition column filled in. For multi-subtype supp tables, expand into one row per subtype.

### definitions_final.txt
Create a clean output file. Example skeleton (patterns are illustrative only):
```
# Final Definitions

| # | Term | Definition Type | Final Definition |
|---|------|----------------|------------------|
| 1 | <general-type term>          | general cell type    | general cell type |
| 2 | <experiment-marker term>     | gene list from paper | GENE_A high, GENE_B high (self-proposed; mirrors paper's flow cytometry markers) |
| 3 | <enrichment-only term>       | KEGG/MSigDB          | HALLMARK_<...> |
| 4 | <phenotypic process term>    | KEGG/MSigDB          | KEGG_<...> (proxy) |
| 5 | <pathway w/ clean supp list> | gene list from supp  | GENE_A, GENE_B, GENE_C, GENE_D, ... |
| 6a| <umbrella group>: Subtype1   | gene list from supp  | <genes from subtype1 column> |
| 6b| <umbrella group>: Subtype2   | gene list from supp  | <genes from subtype2 column> |
| 6c| <umbrella group>: Subtype3   | gene list from supp  | <genes from subtype3 column> |
| 7 | <validated subset term>      | gene list from paper | GENE_A, GENE_B, GENE_C (validated by experiment — preferred over mixed supp DE table) |
| 8 | <single gene term>           | single gene          | GENE_X |
```
