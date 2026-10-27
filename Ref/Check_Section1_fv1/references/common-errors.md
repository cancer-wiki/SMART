# Common Errors in Section 1

## Error Types

### 1. Missing Co-References, IMPORTANT COMMON ERROR

**Pattern:** Paper cites multiple figures together, summary only mentions one.

**Example:**
- Paper: "Western blot analysis confirmed reduced phosphorylation of AKT in treated cells (Fig. 3a and Extended Data Fig. 4b,c)"
- Summary: "AKT phosphorylation was reduced in treated cells (Fig. 3a)"
- Fix: "AKT phosphorylation was reduced in treated cells (Fig. 3a and Extended Data Fig. 4b,c)"

### 2. Missing Table References, IMPORTANT COMMON ERROR

**Pattern:** Paper cites figure + supplementary table, summary omits table.

**Example:**
- Paper: "Pathway analysis identified 85 differentially expressed genes involved in lipid metabolism (Fig. 4d and Supplementary Table 5)"
- Summary: "85 genes were differentially expressed in lipid metabolism pathways (Fig. 4d)"
- Fix: "85 genes were differentially expressed in lipid metabolism pathways (Fig. 4d and Supplementary Table 5)"

### 3. Incorrect Subfigure Range

**Pattern:** Summary uses wrong subfigure letters.

**Example:**
- Paper: "Knockout mice displayed impaired glucose tolerance (Fig. 6a,b)"
- Summary: "Knockout mice showed impaired glucose tolerance (Fig. 6a-c)"
- Fix: "Knockout mice displayed impaired glucose tolerance (Fig. 6a,b)"

### 4. Redundant Figure References

**Pattern:** Summary combines figures that describe different observations.

**Example (INCORRECT):**
- Paper sentence A: "siRNA knockdown reduced protein expression (Fig. 7a)"
- Paper sentence B: "Cell viability assay showed decreased proliferation (Fig. 7c)"
- Summary: "siRNA knockdown reduced protein expression (Fig. 7a,c)" ← Wrong! Fig. 7c is about proliferation, not protein expression
- Fix: Either "siRNA knockdown reduced protein expression (Fig. 7a)" OR split into two claims

**Example (CORRECT):**
- Paper: "Drug treatment reduced tumour volume and decreased Ki67 staining indicating reduced proliferation (Fig. 8a-c)"
- Summary: "Drug treatment reduced tumour volume and proliferation (Fig. 8a-c)"
- This is correct because the paper itself groups these observations together with Fig. 8a-c

**Key distinction:** If paper groups observations X and Y together with "(Fig. 2a,b)", combining them in one claim is correct. If paper describes X with "(Fig. 2a)" and Y separately with "(Fig. 2b)", don't combine.

### 5. Imprecise Language

**Pattern:** Summary uses weaker/stronger language than paper.

**Example:**
- Paper: "significantly attenuated inflammatory response"
- Summary: "attenuated inflammatory response"
- Fix: "significantly attenuated inflammatory response"

**Example:**
- Paper: "associated with poor prognosis"
- Summary: "caused poor prognosis"
- Fix: "associated with poor prognosis" (don't upgrade association to causation)

### 6. Wrong Figure Attribution

**Pattern:** Claim is correct but attributed to wrong figure.

**Example:**
- Paper: "Survival analysis demonstrated improved outcomes (Extended Data Fig. 9a,b)"
- Summary: "Survival analysis showed improved outcomes (Fig. 9a,b)"
- Fix: "Survival analysis demonstrated improved outcomes (Extended Data Fig. 9a,b)"

### 7. Overclaiming Scope

**Pattern:** Claim says "multiple models" but figure only shows one model.

**Example:**
- Paper: "Drug X reduced liver fibrosis in the CCl4-induced mouse model (Fig. 7a), as well as in the bile duct ligation and high-fat diet models (Extended Data Fig. 9a,b)"
- Summary: "Drug X reduced liver fibrosis in multiple mouse models (Fig. 7a)"
- Fix: Either cite both "Fig. 7a and Extended Data Fig. 9a,b" OR change to "in the CCl4-induced mouse model (Fig. 7a)"

### 8. Wrong Source / Setting Attribution, IMPORTANT COMMON ERROR

**Pattern:** Claim assigns a result to the wrong source or setting (dataset, cohort, model, sample, or assay) — often because the detail is in the figure caption, not the body text.

**Example:**
- Caption: "...in dataset/model A"
- Summary: "...in dataset/model B"
- Fix: match the source the paper or caption states

**Rule:** Verify the source or setting a claim names against what the paper states, including the figure caption. Do not relabel one source or setting as another (e.g. dataset A as dataset B, or one model/assay as another).

### 9. Fact Cited to the Wrong Figure, IMPORTANT COMMON ERROR

**Pattern:** A claim's statement is true and supported somewhere in the paper, but cited to a figure that does not show it. The statement should be re-attributed, not deleted, and not accepted on the wrong reference.

**Example:**
- Paper: "Treated mice lost significantly less weight than controls (Fig. 2c). Liver enzyme levels were also normalised (Fig. 4a)."
- Summary: "Treatment reduced weight loss and normalised liver enzymes (Fig. 2c)"
- WRONG fix A: delete "normalised liver enzymes" (the fact is real, just mis-cited)
- WRONG fix B: keep the sentence as-is on Fig. 2c (that figure does not show enzyme data)
- RIGHT fix: "Treatment reduced weight loss (Fig. 2c) and normalised liver enzymes (Fig. 4a)"

**Rule:** When one part of a claim is supported by a different figure than the one cited, split the citation so each part points to the figure that actually shows it. Delete a statement only when no figure or reference in the paper supports it.
---

## Verification Checklist

For each claim, ask:

| Check | Question |
|-------|----------|
| Content match | Does grep result describe the same observation? |
| Co-references | Does grep show additional figures not in claim? |
| Table refs | Does grep show "Supplementary Table X"? |
| Subfigure precision | Does claim match paper's exact subfigure notation? |
| Language | Does claim use same precision as paper (significantly, correlated, etc.)? |
| Grouping | If multiple figures, does paper group them together? |
| Split attribution | If a claim has multiple parts, does each part cite the figure that actually shows it? |

If any check fails → NEEDS_CHECK