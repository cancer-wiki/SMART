# Phase 1: Claim Extraction and Keyword/Figure Grep

## Goal
Decompose the summary into atomic causal claims, locate each in the paper via grep (using both keywords and figure references), and quick-classify before deep reading.

---

### Before Starting Phase 1

Create `Working/check2.txt` with the header:
```
# Verification Report for Section 2

## Phase 1: Grep Results
| # | Claim (brief) | Grep Keywords / Fig Ref | Paper Line | Quick Status |
|---|---------------|------------------------|------------|--------------|
```

### Step 1: Decompose Summary into Atomic Causal Claims

Read the Mechanism section of `Working/draft_summary2.txt`. Break every sentence into its smallest causal units.

**Decomposition rules:**
- Each claim = one causal arrow (A → B) or one stated fact
- Compound sentences get split: "A causes B, which drives C" → Claim 1: A → B, Claim 2: B → C
- Feedback loops are their own claims: "C feeds back to amplify A" → separate claim
- Epistemic framing is part of the claim: note whether the summary says "drives," "is associated with," "is proposed to," etc.
- Reversibility evidence = separate claim: "Restoring X reverses Y" → its own claim
- When one predicate governs several objects (e.g. "X reduces A, B, C, D, and E"), split it into one claim per object. Each object is verified separately, because the paper may support the predicate for some objects but not others.

**Example decomposition:**
Summary: "Kinase X phosphorylates adaptor Y at Ser-118, enabling Y to recruit ubiquitin ligase Z to the lysosomal membrane (Fig. 6a,b)."
→ Claim 1: Kinase X phosphorylates adaptor Y at Ser-118 (Fig. 6a)
→ Claim 2: Phosphorylated Y recruits ubiquitin ligase Z to the lysosomal membrane (Fig. 6b)

### Step 2: Grep Paper for Each Claim — Keywords AND Figure References

For each claim, run TWO types of grep:

**A. Keyword grep** — use 2–3 distinctive terms:
```bash
grep -n "adaptor Y" Inputs/paper1_text.txt
grep -n "Ser-118" Inputs/paper1_text.txt
grep -n "ubiquitin ligase Z" Inputs/paper1_text.txt
```

**B. Figure reference grep** — if the summary cites a figure, grep it directly:
```bash
grep -n "Fig. 6a" Inputs/paper1_text.txt
grep -n "Fig. 6b" Inputs/paper1_text.txt
```

**Why grep figure refs?** The sentence containing a figure reference is almost always the paper's primary statement of that result. This gives you the paper's exact phrasing and epistemic register in one step.

**Grep strategy:**
- Always grep figure refs first when available — they are the fastest path to the source sentence
- Use keyword grep as backup when no figure ref is cited, or when the figure ref returns multiple hits
- If too many keyword hits, combine: `grep -n "adaptor Y.*Ser-118\|Ser-118.*adaptor Y" Inputs/paper1_text.txt`
- For feedback claims, grep the downstream-to-upstream connection term
- Record the line number(s) where the paper discusses this claim

### Step 3: Extract Paper's Exact Phrasing

For each grep hit, record:
1. **Paper line number**
2. **Paper's exact causal verb**: does it say "drives," "suggests," "is consistent with," "we speculate," "remains unclear"?
3. **Paper's epistemic register**: demonstrated / suggested / hypothesized / speculated / proposed / unknown

### Step 4: Quick-Classify

**CORRECT** — Grep result matches claim in content AND epistemic register
**NEEDS_CHECK** — One of:
  - Claim uses stronger language than the paper, in certainty (e.g. claim says "drives," paper says "suggests") or magnitude (e.g. claim says "eliminates," paper says "reduces")
  - Claim uses weaker language than paper (e.g., claim says "is associated with" but paper says "demonstrates")
  - Grep shows the paper mentions additional context (feedback loop, parallel mechanism, negative control) that the claim omits
  - Claim combines multiple paper findings into a single composite statement that may overreach
  - Causal direction is ambiguous from grep alone
  - Figure ref grep returns a sentence with different content than the claim attributes to that figure
  - If the claim uses a high-risk strong verb (abolishes, eliminates, blocks, prevents, abrogates, ablates, completely, fully; see common-errors) and the paper's grepped sentence uses any weaker word for that outcome (reduces, attenuates, decreases, impairs, did not affect), mark NEEDS_CHECK. A shared direction is not enough; the strength must match.
  - If the claim uses an interaction verb (interacts, recruits, binds, associates) with no location attached, mark NEEDS_CHECK to check for a spatial qualifier. The interaction may be correctly stated but missing where it occurs.
**NOT_FOUND** — No grep hit for this claim's core terms or figure refs; claim may be inferred or fabricated


**Immediately append each result row to check2.txt before moving to the next claim.**

---

## What NOT to Do

| Wrong | Right |
|-------|-------|
| Read the entire paper in Phase 1 | Use grep to locate, read locally in Phase 2 |
| Skip the figure-ref grep and rely only on keywords | Figure refs are the fastest, most precise locator — always grep them when available |
| Classify everything as CORRECT because the biology is roughly right | Check epistemic register and completeness, not just biology |
| Skip feedback loop claims because they're "just elaboration" | Feedback loops are mechanistic claims — verify them |
| Assume composite inferences are fine if each piece is individually supported | Flag composites as NEEDS_CHECK — the combination may overreach |
| Ignore the paper's hedge words ("we speculate," "it is possible") | Hedge words determine the epistemic register of the claim |
