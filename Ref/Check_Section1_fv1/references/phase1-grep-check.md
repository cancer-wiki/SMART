# Phase 1: Grep-Based Quick Check

## Goal
Quickly verify each claim using grep, without reading the full map.txt or paper.

---

### Before Starting Phase 1

Create `Working/check1.txt` with the header:
\```
# Verification Report for Section 1

## Completely Correct
| # | Claim Summary | Figure Ref | Paper Line | Grep Result Match |
|---|---------------|------------|------------|-------------------|

## Needs Double-Check
| # | Claim Summary | Figure Ref | Paper Line | Paper Lines (±2) | Issue | Grep Evidence |
|---|---------------|------------|------------|------------------|-------|---------------|

## Candidate Clinical Claims (from Mechanism)
| # | Mechanism Finding | Clinical Part | Figure Ref | Why It Qualifies |
|---|-------------------|---------------|------------|------------------|
\```

### For Each Claim (sequentially):
1. Grep for all figure refs
2. Extract ALL refs from grep result parenthetical
3. Compare against claim's refs
4. **Immediately append the result row to the appropriate table in check1.txt**
5. Then move to next claim

## Process

For each claim in the Clinically Relevant Findings section of `Working/draft_summary1.txt`:

### Step 1: Identify Figure References

Extract all figure refs from the claim. Examples:
- `(Fig. 2a)` → grep "Fig. 2a"
- `(Fig. 2a-c)` → grep "Fig. 2a", "Fig. 2b", "Fig. 2c"
- `(Fig. 2d,e, Extended Data Fig. 3g)` → grep "Fig. 2d", "Fig. 2e", "Extended Data Fig. 3g"

### Step 2: Grep Map.txt for Figure

For main figures:
```bash
grep "Fig. 2a" Working/map.txt
```

For extended figures:
```bash
grep "Extended Data Fig. 3g" Working/map.txt
```

For supplementary figures:
```bash
grep "Supplementary Fig. 1a" Working/map.txt
```

### Step 3: Grep Original Paper for Line Number

Take the full sentence from map.txt grep result and search the original paper with `-n`:
```bash
grep -n "full sentence from map result" Inputs/paper1_text.txt
```

Example:
- Map.txt grep returns: `Fig. 6b    Western blot analysis confirmed decreased phosphorylation of ERK1/2 in treated hepatocytes compared to vehicle controls (Fig. 6b).`
- Then grep paper: `grep -n "Western blot analysis confirmed decreased phosphorylation of ERK1/2 in treated hepatocytes compared to vehicle controls (Fig. 6b)." Inputs/paper1_text.txt`
- Result: `53:...`
- Record: Paper Line = 53, Paper Lines range = 51-55 (±2)

### Step 4: Interpret Grep Results

**Case A: Exact match**
- Grep returns a sentence that matches our claim, AND every ref inside that
  sentence's reference parenthetical already appears in our claim
- → Mark as CORRECT
- If the sentence matches but its parenthetical contains ANY ref not in our
  claim, Case A does NOT apply. Go to Case C.
- The reference parenthetical is the one containing "Fig."/"Figs."/"Table" —
  not the statistics parentheticals. It is usually the LAST one in the
  sentence. Read it before choosing a case.

**Case B: No result for middle subfigure**
- Example: Claim says "Fig. 2a-c", grep "Fig. 2b" returns nothing
- But grep "Fig. 2a" shows "Fig. 2a-c" in the paper
- → This is OK, mark as CORRECT

**Case C: Grep shows additional refs NOT in claim → ALWAYS NEEDS_CHECK**
- This includes Supplementary Fig., Extended Data Fig., Supplementary Table
- These are NOT optional. If the paper groups them in the same parenthetical, 
  the summary must include them.
- Example: Claim says "(Fig. 1a, b)" but grep shows "(Fig. 1a, b and Supplementary Fig. 1d)"
  → NEEDS_CHECK — missing Supplementary Fig. 1d

**Case D: Content mismatch**
- Grep result describes different observation than our claim
- → Mark as NEEDS_CHECK (wrong figure or wrong claim)

**Case E: Grep shows table ref**
- Example: Grep shows "Fig. 1c and Supplementary Table 2"
- Our claim only mentions "Fig. 1c"
- → Mark as NEEDS_CHECK (missing table ref)

**Case F: Claim asserts a source or setting → NEEDS_CHECK**
- If the claim names or implies a specific source or setting (dataset, cohort, model, sample, or assay), flag it NEEDS_CHECK even when the figure ref matches.
- Reason: these details are verified against the caption/body in Phase 2, not by grep. A correct figure ref does not confirm the surrounding detail is correct.

### Step 5: Build Check Tables

Write to `Working/check1.txt`:

**For Completely Correct claims:**
```
## Completely Correct

| # | Claim Summary | Figure Ref | Paper Line | Parenthetical from grep |
|---|---------------|------------|------------|-------------------------|
| 1 | STAT3 phosphorylation increased after IL-6 treatment | Fig. 4a,b, Supp 3c and 4d | 45 | (Fig. 4a, b, Supp 3c and 4d) |
```

**For Needs Double-Check claims, include Paper Lines range (±2):**
```
## Needs Double-Check

| # | Claim Summary | Figure Ref | Paper Line | Paper Lines (±2) | Issue | Grep Evidence |
|---|---------------|------------|------------|------------------|-------|---------------|
| 3 | Knockout mice showed reduced hepatic steatosis | Fig. 5c | 52 | 50-54 | Missing Extended Data Fig. 7a,b | grep shows "Fig. 5c and Extended Data Fig. 7a,b" |
| 4 | ... | ... | ... | ... | ... | ... |
```

### Step 6: Scan the Mechanism Section for Misplaced Clinical Content

Read the Mechanism section of `Working/draft_summary1.txt`. For each finding stated there, ask:

**Does it contain a MEASURED result of one of these kinds?**
- a patient sample or patient cohort
- a response to a clinically used drug
- a patient outcome (survival, prognosis, treatment response)
- tumor growth in an animal or organoid model
- a change in expression of X at a defined disease stage or on transition to disease (e.g. X is low or absent in normal tissue and induced in lesions)

**If yes, is that specific result already stated in the clinical section?**
- If already stated → ignore, no action.
- If not stated → add a row to the **Candidate Clinical Claims** table.

**Do NOT flag a mechanism finding on the basis of:**
- a clinical implication, framing, or "suggests a therapeutic vulnerability" sentence
- a pathway agonist or inhibitor used to establish which pathway mediates an effect
- a knockout or rescue used to establish a dependency
- a correlation between two genes, or between a gene and a gene signature

Record only the clinical part of the finding, not its mechanistic explanation.

```
## Candidate Clinical Claims (from Mechanism)

| # | Mechanism Finding | Clinical Part | Figure Ref | Why It Qualifies |
|---|-------------------|---------------|------------|------------------|
| 1 | X represses Y, and X-null tumors fail to grow in mice | X-null tumors show reduced growth in vivo | Fig. 6a,b | in vivo tumor growth readout |
```

All CANDIDATE rows carry forward to Phase 2 for deep verification.

---

## What NOT to Do

| Wrong | Right |
|-------|-------|
| Read entire map.txt | Only use grep |
| Read entire paper | Only use grep -n for line numbers |
| Skip subfigures in ranges | Grep each: 2a, 2b, 2c |
| Ignore "Supplementary Table" in grep | Flag as NEEDS_CHECK |
| Mark as wrong if 2b returns nothing | Check if 2a shows "2a-c" range |
| Forget to get paper line number | Always grep paper with -n for line location |
| Flag a mechanism finding for its clinical implication | Flag only for a measured clinical result |
