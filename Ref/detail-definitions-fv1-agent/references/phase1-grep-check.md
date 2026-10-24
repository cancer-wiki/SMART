# Phase 1: Grep-Based Paper Search

## Goal
For each term in Section 2 of `Working/definitions_needed.txt`, grep the original paper to find how the paper defines or describes it. Collect genes, experiment types, and any supp/fig references.

---

### Before Starting Phase 1

Create `Working/definitions_detail.txt` with the header:
```
# Definition Evidence Table

## Section 1: Raw Grep Results
(For each term, paste the full grep output here before analyzing)

### Term: [term name]
```bash
grep -n -B 2 -A 2 "term" Inputs/paper1_text.txt
```
[paste grep output here]

---

## Section 2: Summary Tables

### Resolved (no supp needed)
| # | Term | Paper Says | Type | Genes Found | Fig/Supp Ref | Final Definition |
|---|------|-----------|------|-------------|--------------|------------------|

### Needs Supp Check
| # | Term | Paper Says | Type | Genes Found | Fig/Supp Ref | Supp Result | Final Definition |
|---|------|-----------|------|-------------|--------------|-------------|------------------|
```

**Important:** For each term, FIRST record the raw grep output in Section 1, THEN analyze and add a row to the appropriate table in Section 2.

---

### For Each Term (sequentially):

1. Grep the paper for the term
2. Read the grep results carefully
3. Record what you find
4. **Immediately append the result row to the appropriate table**
5. Move to the next term

---

## Process

### Step 1: Grep the Paper

```bash
grep -n -B 2 -A 2 "term" Inputs/paper1_text.txt
```

Use variations if needed:
```bash
grep -n -i -B 2 -A 2 "term" Inputs/paper1_text.txt
```

If the term has multiple possible forms (e.g., "Treg" vs "regulatory T"), grep each:
```bash
grep -n -B 2 -A 2 "Treg" Inputs/paper1_text.txt
grep -n -B 2 -A 2 "regulatory T" Inputs/paper1_text.txt
```

### Step 2: Analyze Grep Results

For each grep hit, identify:

**A. Genes mentioned in the sentence**
- Record ALL gene names in the sentence (e.g., "FOXP3, CD25, CTLA4")
- Check if the gene list is complete or if it says "see Supp Table X for full list"

**B. Type of evidence**
Classify as one of:
| Type | Description | Example |
|------|-------------|---------|
| `experiment` | Direct experiment result | "IHC staining showed X was positive" |
| `enrichment` | Pathway/enrichment analysis | "GO analysis revealed enrichment in..." |
| `self-def` | Paper's own definition | "We defined X-high cells as those with..." |
| `general` | Well-known cell type, no special definition | "CD8+ T cells were identified" |

Record the experiment type briefly if applicable: IHC, flow cytometry, Western blot, RNA-seq, etc. Do NOT record experimental details.

**C. Fig/Supp references**
- Record any `Fig. X`, `Extended Data Fig. X`, `Supplementary Fig. X`, `Supplementary Table X` mentioned in the sentence
- These determine whether we need Phase 2

### Step 3: Handle Subset vs Full Set

**Key rule:** If the paper says "full results in Supp Table X" but then highlights a subset for follow-up experiments, record ONLY the subset.

Example:
- Paper: "We identified 200 DEGs (Supplementary Table 3). Among these, we validated GENE1, GENE2, and GENE3 by qPCR (Fig. 4a)"
- Record: GENE1, GENE2, GENE3 (the experimentally validated subset)
- Do NOT go to Supp Table 3 for the full 200

**Exception:** If there is NO follow-up experiment and the paper just says "see Supp Table X", then mark as CHECK_SUPP to get the full list.

### Step 4: Check for Composite Terms

If the grep results show that a term bundles multiple distinct biological processes (e.g., the paper defines it by several different functional assays measuring different things), note the components in the evidence row. Write in the Final Definition column: `COMPOSITE: [component A], [component B], [component C]`. Each component will become its own row in the final table (see decision-rules.md Rule 8).

### Step 5: Categorize

**RESOLVED** — no supp check needed if:
- The paper gives a complete gene list in the text
- The term is a general cell type (Treg, CD8 T, Macrophage, etc.)
- The paper highlights a validated subset with follow-up experiments

**CHECK_SUPP** — supp check needed if:
- Paper says "see Supplementary Table/Fig X" and no subset is highlighted
- Paper references a figure that might contain a gene list
- The gene list in text is incomplete ("including X, Y, Z, among others")

### Step 6: Write to Table

Append each term to the correct table in `Working/definitions_detail.txt`.

---

## What NOT to Do

| Wrong | Right |
|-------|-------|
| Read the entire paper | Only use grep |
| Record full experiment details | Just note type: "IHC", "flow cytometry" |
| Go to supp for everything | Only when paper explicitly references it AND no subset is highlighted |
| Ignore genes in the sentence | Record ALL genes mentioned |
| Skip fig/supp references | Record every fig/supp mentioned in the sentence |
| Record the full 200 DEGs from supp when paper validated 3 | Record only the 3 validated genes |
