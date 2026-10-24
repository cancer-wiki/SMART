# Phase 2: Deep Verification

## Goal
Verify and correct all NEEDS_CHECK items from Phase 1, and verify all CANDIDATE clinical claims before adding them.

---

## Process

### Step 1: Read Check Report

Read `Working/check1.txt` to get the list of NEEDS_CHECK items, including their **Paper Lines (±2)** ranges, and the list of CANDIDATE clinical claims.

### Step 2: Read Full Context

1. Read `Inputs/paper1_text.txt` completely
2. Read `Working/map.txt` completely
3. Read the caption file for each figure cited in a claim under review, from `Inputs/Captions/`. Map the figure to its file: `Fig. 5a` → `Inputs/Captions/Fig5.txt`; `Extended Data Fig. 9b` or `Supplementary Fig. 6a` → `Inputs/Captions/ExtFig{N}.txt`. Captions often carry details not stated in the body text, so read them before verifying the claim.

Now you have full context for verification.

### Step 3: Verify Each NEEDS_CHECK Item

For each item in the NEEDS_CHECK table:

1. **Use the Paper Lines (±2) range** to extract relevant context:
```bash
   sed -n '50,54p' Inputs/paper1_text.txt
```
   This pulls only lines 50-54 from the paper.

2. **Find the exact sentence(s)** in the extracted lines that support this claim
3. **Check figure references** - are they complete?
4. **Check table references** - are any missing?
5. **Check language precision** - does claim match paper's wording?
6. **Check attribution details** — does the claim match what the paper (body or caption) states about the source and setting of the result, e.g. dataset or cohort, sample, model, or assay? Correct any mismatch to what the paper actually reports.

When a statement is supported by a different figure than the one cited, replace the incorrect figure reference with the correct one (e.g. move the citation to the figure that shows it), not merely accept the existing citation.

### Step 4: Verify Each CANDIDATE Clinical Claim

For each row in the Candidate Clinical Claims table:

1. Locate the supporting sentence in `Inputs/paper1_text.txt` and read the relevant caption.
2. Confirm the measured clinical result is real and that the figure ref shown in the paper supports it.
3. Confirm it is not already stated in the clinical section.
4. If all three hold, write the clinical part as a standalone claim with its own figure ref. Keep the mechanistic explanation in the Mechanism section — do not move it.
5. If the paper supports no measured clinical result, or the finding is only a clinical implication, drop the candidate and record why.

### Step 5: Update Check Report

Update the NEEDS_CHECK table in `Working/check1.txt` by adding "Paper Says" and "Correction" columns:
```
## Needs Double-Check (Updated)

| # | Claim Summary | Figure Ref | Paper Line | Paper Lines (±2) | Issue | Grep Evidence | Paper Says | Correction |
|---|---------------|------------|------------|------------------|-------|---------------|------------|------------|
| 3 | Knockout mice showed reduced hepatic steatosis | Fig. 5c | 52 | 50-54 | Missing co-refs | grep shows "Fig. 5c and Extended Data Fig. 7a,b" | "Histological analysis revealed significantly reduced hepatic steatosis in Pparg−/− mice compared to wild-type controls (Fig. 5c and Extended Data Fig. 7a,b)" | Add "and Extended Data Fig. 7a,b" |
| 4 | ... | ... | ... | ... | ... | ... | ... | ... |
```

Update the Candidate table with a "Verdict" column: `ADD` (with final wording and figure ref) or `DROP` (with reason).

### Step 6: Generate Corrected Output

Create `Working/draft_summary2.txt` with all corrections applied and all verified candidates added to the clinical section. Keep the Mechanism section as written.

---

## Correction Guidelines

| Issue Type | How to Correct |
|------------|----------------|
| Missing Extended Data Fig | Add the missing ref |
| Missing Supplementary Table | Add table ref |
| Wrong subfigure range | Fix to match paper exactly |
| Imprecise language | Match paper's exact wording |
| Redundant figure ref | Remove if not in paper |
| Wrong attribution detail | Correct to the source or setting the paper or caption states (dataset/cohort, sample, model, assay) |
| Fact supported by a different figure | If a claim's statement is real but cited to the wrong figure, find the figure or reference that actually supports it and re-attribute, rather than deleting. Delete only if no source in the paper supports it. |
| Candidate clinical claim from Mechanism | Add the clinical part to the clinical section with its own figure ref; leave the mechanistic explanation in Mechanism |

---

## Output Files

1. **check1.txt** - Updated with "Paper Says" column, corrections, and candidate verdicts
2. **draft_summary2.txt** - Corrected summary, ready to use

## Common Error during deep check

**Pattern:** Agent correctly identifies missing co-references but then drops them 
when writing the corrected claim.

**Example:**
- Paper sentence 1: "Drug X inhibited tumor growth in xenograft models (Fig. 4a and Supplementary Table 3)."
- Paper sentence 2: "Histological analysis confirmed reduced Ki67 staining in treated tumors (Fig. 4b and Fig. S3a, b)."
- Original claim: "Drug X inhibited tumor growth and reduced Ki67 staining (Fig. 4a, b)"
- Agent identifies: Table S3 missing, Fig. S3a, b missing
- WRONG correction: "Drug X inhibited tumor growth and reduced Ki67 staining in xenograft models (Fig. 4a, b)"
- RIGHT correction: "Drug X inhibited tumor growth and reduced Ki67 staining in xenograft models (Fig. 4a, Supplementary Table 3, Fig. 4b and Fig. S3a, b)"

**Rule:** When referencing any statement from the original paper, include ALL 
references that the paper cites alongside that statement. If the paper says 
"X occurred (Fig. 4a and Supplementary Table 3)", you must cite both 
Fig. 4a and Supplementary Table 3 — never drop part of a paper's citation 
group when incorporating it into the corrected claim.
