# Common Errors in Definition Checking

## Error Types

### 1. Defining General Cell Types Unnecessarily

**Pattern:** Agent creates a custom marker list for a well-known cell type.

**Example:**
- Paper: "Tregs were identified as CD4+FOXP3+CD25+ cells"
- Wrong: `Final def: CD4+, FOXP3+, CD25+`
- Right: `Final def: general cell type`

**Why:** General cell types are identifiable by standard scRNA-seq annotation. Custom markers from one paper may not transfer well.

---

### 2. Using Paper's Exact Enrichment Pathway

**Pattern A — Paper mentions multiple pathways / points to supplementary files:**
- Paper: "widespread enrichment across oxidative phosphorylation and related processes (GO:0006119, FDR < 0.001); see Supplementary Table 3 for all enriched pathways"
- Wrong: `Final def: GO:0006119`
- Right: `Final def: KEGG_OXIDATIVE_PHOSPHORYLATION`

Use a common, well-known standardized pathway instead of the paper's specific enrichment term.

**Pattern B — Paper explicitly names one specific pathway:**
- Paper: "enrichment specifically in the mTORC1 signaling pathway (GO:0031929, FDR < 0.001)"
- Wrong: `Final def: KEGG_MTOR_SIGNALING_PATHWAY`
- Right: `Final def: GO:0031929`

If the paper singles out exactly one pathway as their finding, use that specific term — it reflects what the authors explicitly identified.

**Why:** We want standardized, well-known gene sets when the paper is vague or pointing to a broad result across many pathways. But when authors explicitly highlight a single pathway, that specificity is intentional and should be preserved.

> **See also:** Error 14 — same "was it singled out for a reason?" logic applies when choosing between a gene list and a pathway.

---

### 3. Wrong Choice Between Highlighted Subset and Full Supp List

**Pattern A: Using full list when paper validated a subset.**

**Example (pattern only):**
- Paper: "We identified 500 DEGs (Supp Table 3). qPCR validation confirmed a small subset (Fig. 4b)"
- Wrong: Records all 500 genes from Supp Table 3
- Right: Records only the subset confirmed by qPCR
- Why: The paper highlighted these for a reason (validation). Use the validated subset.

**Pattern B: Using highlighted subset when full list is available and relevant.**

**Example (pattern only):**
- Paper: "Pathway-X proteins including a few named examples were downregulated (Supp Table 2)"
- Supp Table 2 contains the full list, all belonging to pathway-X, no validation experiment on the named examples
- Wrong: Records only the 2–3 genes mentioned in the text
- Right: Records the full supp list (all same category, nothing was specifically validated)
- Why: The paper just mentioned a few as examples; the supp has the complete relevant set.

**Decision rule:** Was the subset highlighted for a specific reason (experiment, validation)? → use subset. No special reason + supp list is all same category? → use full supp list. Supp list is mixed/unrelated? → use subset.

> **See also:** Error 7 — if the paper points to supp with no highlighted subset at all, always go check it. Error 15 — if the supp itself turns out to be a big mixed list, the paper's highlighted subset becomes more reliable.

---

### 4. Using Cluster Marker Genes Directly

**Pattern:** Agent records all marker genes from a cluster analysis supp table.

**Example (pattern only):**
- Paper: "Cluster-Q was enriched for <some-category> genes (Supp Table 1)"
- Supp Table 1 has hundreds of marker genes for Cluster-Q
- Wrong: Records all marker genes
- Right: Use the main text description — e.g., if the paper says the cluster represents a specific biological program, propose a standardized pathway name that captures that program

**Why:** Cluster markers are too specific to one dataset. The biological description in the text transfers better.

---

### 5. Missing Genes from the Paper Sentence

**Pattern:** Agent records some but not all genes mentioned in the grep result.

**Example (pattern only):**
- Grep result lists 5 markers of a population
- Wrong: Records only 3 of them
- Right: Records all 5

**Why:** If the paper lists specific genes, the definition should include ALL of them.

---

### 6. Ignoring Supp Reference When No Subset Is Highlighted

**Pattern:** Paper says "full list in Supp Table X" with no follow-up experiment, but agent skips the supp.

**Example (pattern only):**
- Paper: "Key factors are listed in Supp Table 4", no follow-up experiment mentioned
- Wrong: Skip supp, record nothing
- Right: Mark as CHECK_SUPP, go to Supp Table 4, extract the gene list

> **See also:** Error 3 — once you have the supp list, apply the subset vs full list decision rule.

---

### 7. Confusing Experiment Type with Definition Type

**Pattern:** Agent records the experiment method as the definition, or fails to distinguish between well-defined and poorly-defined cell types.

**Pattern A — Well-known cell type confirmed by experiment:**
- Paper: "Flow cytometry confirmed canonical-marker+ canonical-cell-type cells"
- Wrong: `Final def: <markers used in flow>`
- Right: `Final def: <canonical cell type>` (well-established, no need to list markers)

**Pattern B — Poorly defined cell type confirmed by experiment:**
- Paper: "Flow cytometry confirmed <non-canonical>-markers+ '<novel label>' cells"
- Wrong: `Final def: flow cytometry`
- Right: `Final def: <the markers>` (the label is vague, so the markers ARE the definition)

**Why:** The experiment validates the biology. For well-known cell types, use the canonical label. For loosely defined cell types, the gene/marker expression pattern is the meaningful definition.

> **See also:** Errors 1 and 9 — all three deal with when to use a canonical label vs a custom definition.

---

### 8. Not Checking Multiple Grep Hits (or Only One File)

**Pattern:** Agent uses only the first grep result when there are multiple relevant sentences, OR only greps the main text and ignores the methods file.

**Example (pattern only):**
- First grep hit in main text is vague
- Second grep hit (missed) in main text or methods is more specific
- Wrong: Stops at first hit
- Right: Check ALL grep hits in BOTH `paper1_text.txt` AND `paper1_method.txt`

---

### 9. Over-Specifying When Paper Is Vague

**Pattern:** Agent invents a precise definition when the paper only gives a vague description.

**Example (pattern only):**
- Paper: "<canonical cell type> were observed in the microenvironment" with no markers listed
- Wrong: Invents a marker list
- Right: Use the canonical cell type label as-is

**Why:** If the paper does not provide explicit markers, do not fabricate a definition. Canonical cell type labels with specific biological meaning can be recorded as-is (not as `general cell type`), but do not invent markers.

> **See also:** Errors 1 and 7 — the distinction between `general cell type` and a canonical label is that the latter has a specific biological meaning the paper is pointing to, while the former is a fully standard scRNA-seq-annotatable population.

---

### 10. Adding Extra Info to "general cell type" (MOST IMPORTANT COMMON ERROR)

**Pattern:** Agent writes "general cell type" but then adds markers, mouse/human equivalents, or parenthetical notes.

**Example:**
- Wrong: `general cell type (regulatory T cells); markers: FOXP3+, CD25+; also known as Tregs`
- Wrong: `general cell type; CD8+ cytotoxic T cells expressing granzyme B`
- Right: `general cell type`

**Why:** "general cell type" means EXACTLY those three words and nothing else. Any addition defeats the purpose.

---

### 11. Listing Genes When Definition Type Is KEGG/MSigDB (MOST IMPORTANT COMMON ERROR)

**Pattern:** Agent picks KEGG/MSigDB as the definition type but then lists individual genes instead of a pathway name.

**Example:**
- Wrong: Definition Type = `KEGG/MSigDB`, Final Definition = `GENE_A, GENE_B, GENE_C (some-process markers)`
- Right: Definition Type = `KEGG/MSigDB`, Final Definition = a pathway name like `HALLMARK_<...>`

**Why:** If the type is KEGG/MSigDB, the output MUST be a pathway name. If you want to list genes, the type should be "gene list from paper".

---

### 12. Using Gene Alias Instead of Official Gene Symbol

**Pattern:** When a paper uses a gene alias or alternative name, agent records the alias instead of the official gene symbol.

**Example (pattern only):**
- Paper uses an old alias or protein name for a gene
- Wrong: Records the alias
- Right: Records the official gene symbol

**Why:** Always use the official gene symbol in the final definition.
(Exception: experiment-based gene definitions CAN include mouse/human notes and "(self-proposed)" labels.)

---

### 13. Giving Two Definitions or "Supplement With" Suggestions

**Pattern:** Agent provides one definition and then suggests adding another on top.

**Case A — Paper highlights a specific gene list for a reason:**
- Paper highlights a small gene list validated by knockdown, alongside a broader pathway name
- Wrong: `<genes>. Supplement with <PATHWAY> for broader coverage`
- Right: `<genes>` (the knockdown experiment singles these out — use the specific gene list)

**Case B — Paper mentions a gene list with no particular reason, alongside a pathway:**
- Paper: "<pathway> signaling including a few illustrative genes was enriched"
- Wrong: `<genes>. Supplement with <PATHWAY> for broader coverage`
- Right: `<PATHWAY>` (the gene list is illustrative; use the broader standardized pathway)

**Why:** One definition per term. Apply the reliability hierarchy — pick one.

> **See also:** Error 2 — the same "singled out for a reason?" logic applies when choosing between GO terms and KEGG pathways. Error 15 — applies when choosing between a paper subset and a big mixed supp table.

---

### 14. Flattening a Multi-Column Subtype Supp Table

**Pattern:** Agent opens a supp table where each column represents a distinct subtype of one umbrella group, then merges all columns into one flat gene list.

**Example (pattern only):**
- Umbrella group in paper is mentioned (e.g., an immune population with several subtypes)
- Supp table has one column per subtype, each with its own gene list
- Wrong: Flattens every column into one combined gene list
- Right: Record each column as a separate subtype entry. In the final output, produce one row per subtype:
  - `<umbrella>: Subtype1 → <genes from col1>`
  - `<umbrella>: Subtype2 → <genes from col2>`
  - `<umbrella>: Subtype3 → <genes from col3>`

**Why:** Flattening mixes distinct sub-populations and destroys the categorical structure the paper intended. The downstream user almost always wants the subtypes resolved separately.

> **See also:** Phase 2.5 routing check and Decision Rule 8.

---

### 15. Picking the Wrong Source When Multiple Definitions Exist

**Pattern:** Agent picks a less reliable source when a more reliable one is available, or merges sources instead of choosing one.

**Example A — Supp is big and mixed; paper highlighted a clean subset:**
- Paper highlights a small category-specific gene list with a specific reason
- Supp table exists but is a huge DE table across many unrelated categories
- Wrong: Uses the supp table because "it has more genes"
- Right: Uses the paper's highlighted subset (Tier 1/2 beats Tier 4 in the reliability hierarchy)

**Example B — Paper has a validated subset and also a pathway name:**
- Paper names both a validated gene subset AND a broader pathway
- Wrong: Uses the pathway as "safer"
- Right: Uses the validated gene subset (Tier 1 beats Tier 3)

**Example C — Paper has an illustrative gene list and a clean supp of the same category:**
- Paper: illustrative "for example" gene list, no validation
- Supp: clean category-specific list, same category as the term
- Wrong: Uses the illustrative paper genes
- Right: Uses the clean supp list (Tier 2 beats Tier 3)

**Why:** The reliability hierarchy in decision-rules.md is designed to pick the source that most faithfully represents the paper's actual finding for that term.

> **See also:** Decision Rules — RELIABILITY HIERARCHY; Error 3 and Error 13.

---

### 16. Same-Sentence Subsets Given Different Definition Types

**Pattern:** Multiple Section 2 terms appear in the same sentence with the same grammatical treatment, but the agent assigns different Definition Types to them.

**Example (pattern only):**
- One sentence introduces three peer processes, each followed by the same type of descriptor (e.g., "...including process-A (for example, geneA, geneB), process-B (for example, geneC, geneD), and process-C (for example, geneE, geneF)")
- Wrong: Definition Type for process-A = "KEGG/MSigDB", for process-B = "gene list from paper", for process-C = "gene list from supp"
- Right: All three share the SAME Definition Type (in this case, "KEGG/MSigDB", because the gene names after "for example" are illustrative, not definitional)

**Why:** The paper's own framing treats same-sentence peers as parallel. Breaking the parallel introduces arbitrary inconsistency.

**Edge case:** If one of the peers has independent strong evidence (e.g., a dedicated validation experiment elsewhere in the paper) that promotes it to a different tier, you may break the parallel for that term only and document the reason.

> **See also:** Decision Rules — SAME-SENTENCE SUBSET RULE.

---

### 17. Failing to Propose a Proxy for Non-Measurable Processes

**Pattern:** A Section 2 term refers to a phenotypic process (e.g., cell migration, invasion, motility, adhesion behaviors) that cannot be read off scRNA-seq expression directly. The paper does not provide a gene list or pathway. The agent either leaves the definition blank, writes "not applicable", or invents a gene list.

**Example (pattern only):**
- Term: a phenotypic process that is measurable by functional assay but not by gene expression alone
- Paper mentions it but does not operationalize it
- Wrong: leaves definition blank / writes "not applicable" / invents a marker list
- Right: Propose the closest well-known KEGG/MSigDB pathway that captures the process and label the Final Definition with `(proxy)`

**Why:** Downstream users need something to run on scRNA-seq. A labeled proxy is always more useful than nothing, and the `(proxy)` label flags it as not explicit in the paper.

**Precedence:** If the paper itself provides a gene list or pathway for the process, USE THAT — proxies are only for terms the paper mentions but does not operationalize.

> **See also:** Decision Rules — NOT-DIRECTLY-MEASURABLE-IN-SCRNA RULE.

---

### 18. Picking the Pathway Name When the Paper Validated Genes From That Pathway

**Pattern:** The paper reports a pathway enrichment (e.g., "pathway-X was the top-ranked enriched pathway") and then performs follow-up experiments on a specific subset of genes drawn from that pathway. The agent picks the pathway name as the final definition instead of the validated gene list.

**Example (pattern only):**
- Paper: "KEGG analysis identified pathway-X as top-ranked. N genes in pathway-X were candidates; we validated them by RT-qPCR and ChIP-PCR, confirming M of them are bound and regulated (Fig. 4)"
- Supp figure shows all M validated genes on its axis
- Wrong: Definition Type = `KEGG/MSigDB`, Final Definition = `<pathway-X name>`
- Right: Definition Type = `gene list from paper`, Final Definition = the validated M (or N) genes

**Why:** The pathway enrichment was the discovery tool; the validated gene list is the finding the paper stands behind. The paper's rhetorical structure — "we identified pathway X, and these specific genes from it drive the phenotype" — means the genes are the answer, not the pathway.

**Signals that trigger this rule:**
- Paper phrases the pathway as where something "ranks first" or "was top"
- Paper then names specific genes "in the pathway" or "targeted by X"
- Paper performs ANY follow-up experiment on those genes (qPCR, ChIP, knockdown, rescue, Western, etc.)
- A supp figure or main figure explicitly labels the validated genes

**Multi-stage validation:** If the paper narrows a candidate set through successive experiments (e.g., N candidates → M down-regulated → K bound), use the set that represents the paper's final claim about "pathway-X-associated genes" — usually the post-validation set. If ambiguous, prefer the candidate set that entered validation over the smallest post-hoc stratum.

> **See also:** Decision Rules — RELIABILITY HIERARCHY (Tier 1 beats Tier 3); Rule 11; Error 13.

---

### 19. Self-Excluding Paper-Highlighted Genes Based on Agent's Own Category Judgment

**Pattern:** The paper highlights a specific gene (in text, in a figure, in a heatmap, or in a supp table) as part of the answer for a term, but the agent drops it because it doesn't match the agent's internal idea of what belongs to that biological category.

**Example (pattern only):**
- Term: a biological category (e.g., a signaling family, a class of secreted factors, a cytokine class)
- Paper highlights several genes including one member that is a family-adjacent or non-canonical entry
- Agent decides "that one isn't a real <category> member" and silently drops it
- Wrong: Final definition omits the paper-highlighted gene
- Right: Keep every gene the paper highlighted as part of the term's answer — the paper's framing defines the category for this work

**Why:** Biological categories are not strictly bounded, and papers often include family-adjacent, isoform, or functionally related genes deliberately. Dropping them overrides the authors' judgment with the agent's own, which is out of scope for a definition-extraction task. The downstream user wants what the paper said, not what a database says.

**What counts as "highlighted by the paper":**
- Named in the main text as part of the answer for the term
- Labeled on a figure (heatmap, volcano, bar chart, spatial map, schematic)
- Listed in the supp table for the relevant comparison as significant / upregulated / validated
- Shown in a validation experiment for the term

**Allowed exception:** None for the final definition. If a paper-highlighted gene seems anomalous, note the anomaly in the detail table's Paper Says / Supp Result column, but keep it in the final definition.

**Specifically do NOT exclude because:**
- The gene is "not classical" for the category by textbook definition
- The gene is a pseudogene, a recently characterized gene, or a family-adjacent factor
- A database categorizes it differently than the paper does
- The gene's name is slightly different from what you'd expect

> **See also:** Decision Rules — Strict Output Rule 9; Rule 12; Error 5 (missing genes from paper sentence).

---

### 20. Not Escalating to check-external-ref-v1-agent When the Paper Defers to a Reference (Route A missed)

**Pattern:** The definition is not in this paper and not in the supp, but the paper explicitly points
to a *referenced paper* for it (e.g., "as defined in ref. 23", "using the signature from Author et al.").
The agent either leaves the term blank, invents a definition, or forces a proxy without first checking
the cited source.

**Example (pattern only):**
- Paper: "We scored cells for the <program> signature as defined in Author et al. (ref. 31)"
- No gene list in this paper or its supp
- Wrong: leave blank / invent genes / jump straight to a proxy
- Right: RECORD the citation, write it to `routing.json` as Route A, and mark as `external ref (pending)` in definitions_final.txt. The pipeline runs the external agent separately.

**Why:** The paper deliberately outsourced the definition to a specific source. The referenced paper
holds the real answer; a proxy is only appropriate if the reference cannot be resolved.

**Note:** If the term is undefined AND no reference is cited, this is NOT Route A — fall through to
Phase 3 (proxy rule or flag to user).

> **See also:** Phase 2.5 — Route A; Decision Rules — Precondition.

---

### 21. Writing a Normal Definition for a Function-Computed Term (Route B missed)

**Pattern:** The definition is produced by a non-standard package/method (not KEGG/MSigDB, not a plain
or simply-weighted gene set scorable by `AddModuleScore` / `score_genes`, not trivially codeable — e.g.,
computed with a dedicated tool like Senepy). The agent coerces it into a KEGG/MSigDB pathway name or a
flat gene list instead of escalating.

**Example (pattern only):**
- Paper: "Senescence was scored per cell using **Senepy**"
- Wrong: Definition Type = `KEGG/MSigDB`, Final Definition = `HALLMARK_...`, OR a flat gene list
- Right: RECORD the package + what it computes, write it to `routing.json` as Route B, and mark as `external package (pending)` in definitions_final.txt. The pipeline runs the external agent separately.

**Why:** The method IS the definition. Forcing it into a pathway name or gene list silently changes what
the paper actually did and will not reproduce on another dataset.

**Do NOT trigger Route B just because a gene set has weights** — a weighted set still scores with
`AddModuleScore` / `score_genes` and stays in Phase 3.

> **See also:** Phase 2.5 — Route B; Decision Rules — Precondition.

---

### 22. Giving Multiple Pathway Options with "or"

**Pattern:** Agent picks KEGG/MSigDB as the definition type but then lists multiple pathways separated by "or", "alternatively", or semicolons instead of picking one.

**Example:**
- Wrong: `KEGG_GLYCOLYSIS_GLUCONEOGENESIS or MSigDB Hallmark HALLMARK_GLYCOLYSIS`
- Wrong: `Hallmark G2M_CHECKPOINT + E2F_TARGETS`
- Wrong: `MKI67 or standard proliferation signature, e.g., Tirosh et al.`
- Right: `HALLMARK_GLYCOLYSIS (proxy)`
- Right: `HALLMARK_G2M_CHECKPOINT (proxy)`

**Why:** ONE definition per term. Pick the single best-fit pathway. The downstream pipeline needs exactly one pathway name to score, not a menu of options.

---

### 23. Proposing Custom Gene Lists as Proxy When a Standard Pathway Exists

**Pattern:** The paper defines a term by functional assays only (no gene signature). Instead of using a standard KEGG/MSigDB pathway as proxy, the agent invents a custom gene list (e.g., "MKI67, TOP2A, PCNA, MCM2, ...").

**Example:**
- Wrong: Definition Type = `proxy gene list`, Final Definition = `MKI67, TOP2A, PCNA, MCM2, MCM3, ...`
- Right: Definition Type = `KEGG/MSigDB`, Final Definition = `HALLMARK_G2M_CHECKPOINT (proxy)`

**Why:** When the paper doesn't provide a gene list, we prefer standard pathway names over custom-assembled gene lists. Standard pathways are reproducible and well-defined. Custom gene lists are arbitrary — different agents would pick different genes. The `(proxy)` label already signals this is not from the paper.

**Rule:** If a standard KEGG or Hallmark pathway exists for the process, always use that. Never invent a gene list as proxy.

---

### 24. Collapsing a Composite Functional Phenotype into One Row

**Pattern:** A term bundles multiple distinct biological processes (e.g., the paper defines it by several different functional assays measuring different things), but the agent picks one proxy pathway and puts everything in a single row.

**Example:**
- Paper defines a term by three assays: cell growth assay, migration assay, and metabolic assay
- Wrong: One row with a single pathway proxy that only covers one of the three processes
- Right: Split into separate rows, one per distinct process, each with its own proxy pathway

**Why:** Different biological processes need different pathway proxies. Collapsing them into one row loses components. If a term covers both a growth process and a motility process, those are two different pathways — they cannot be represented by a single proxy.

**How to catch:** During Phase 1 grep, if the paper defines a term by multiple distinct assays, mark it as `COMPOSITE: [component A], [component B]` in the evidence row. Then in the final table, produce one row per component (e.g., `4a`, `4b`).

---

## Verification Checklist
For each term, ask:

| Check | Question |
|-------|----------|
| Both files greped? | Did I grep BOTH paper1_text.txt AND paper1_method.txt? |
| General type? | Is this a well-known cell type? → "general cell type", nothing else |
| All genes? | Did I record ALL genes from the paper sentence? |
| Highlight rule? | Was the subset highlighted for a reason? → use subset. No reason + supp is same category? → use full supp list |
| Supp needed? | Does the paper point to supp with no subset? → CHECK_SUPP |
| Route A? | Undefined in this paper + supp but a referenced paper is cited? → record citation, write to routing.json, mark as `external ref (pending)` |
| Route B? | Requires a dedicated classifier or non-standard package? → record package, write to routing.json, mark as `external package (pending)` |
| Multi-subtype supp? | Is the supp a multi-column subtype table? → record each subtype separately, don't flatten |
| Reliability hierarchy? | If multiple sources exist, did I pick the most reliable tier and use ONLY it? |
| Validated genes vs pathway? | Did the paper validate specific genes from an enriched pathway? → use the validated genes, NOT the pathway name |
| No self-exclusion? | Did I keep EVERY gene the paper highlighted, even ones I personally think don't fit the category? |
| Composite term? | Does this term bundle multiple distinct biological processes? → split into separate rows, one proxy per process |
| Cluster markers? | Is the supp a marker gene table? → ignore, use text |
| Pathway? | Did I use KEGG/MSigDB instead of the paper's GO term when appropriate? |
| Experiment vs def? | Did I record the expression pattern, not the method? |
| One def only? | Did I give exactly ONE definition, not two options? |
| Same-sentence group? | If peers from the same sentence exist, do they share the same Definition Type? |
| Not measurable? | If the term is a phenotypic process with no paper-provided genes, did I propose a `(proxy)`? |
| Clean output? | No parenthetical aliases (except self-proposed experiment defs)? |

If any check fails → fix before finalizing.
