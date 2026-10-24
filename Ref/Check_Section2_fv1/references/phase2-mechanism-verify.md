# Phase 2: Deep Mechanism Verification

## Goal
Verify and correct all NEEDS_CHECK and NOT_FOUND items from Phase 1 by reading the paper locally.

---

## Process

### Step 1: Read Check Report

Read `Working/check2.txt` to get the list of NEEDS_CHECK and NOT_FOUND items, including their paper line numbers.

### Step 2: Read Paper Locally

For each NEEDS_CHECK item, read the paper lines ±5 around the grep hit:
```bash
sed -n '50,60p' Inputs/paper1_text.txt
```

For NOT_FOUND items, read the full relevant Results or Discussion section to locate (or confirm absence of) the claim.

### Step 3: Verify Each Item Against Six Error Dimensions

Read `~/.claude/agents/Ref/Check_Section2_fv1/references/common-errors.md` for the full error taxonomy. For each NEEDS_CHECK item, systematically check:

A claim may violate more than one dimension. Check all dimensions against every claim; do not stop at the first error found. Record every error type that applies in the Error Type column. 

#### Dimension 1: Causal Direction
- Does the summary get the arrow right? A → B, not B → A?
- Does it confuse upstream drivers with downstream consequences?
- Does it confuse adaptive responses with causal mechanisms?
- Does the summary use an active verb (promotes, drives, recruits, enriches) for a link the paper established only by depletion/knockout? Depletion shows X is required for Y, not that X actively drives Y (Necessity vs Agency, common-errors 10).

#### Dimension 2: Epistemic Register
- Does the summary match the paper's confidence level?
- Paper says "we speculate" → summary must NOT say "drives" or "maintains"
- Paper says "demonstrates" → summary should NOT say "is associated with"
- Paper says "suggesting" or "consistent with" → summary should NOT say "establishes" or "confirms"
- If the claim was flagged for a high-risk strong verb, apply the "High-Risk Strong Verbs" entry in common-errors: confirm the paper's word for that outcome, and replace the claim's verb with the paper's actual word.

**Epistemic register scale (from weakest to strongest):**
```
speculate / propose → suggest / is consistent with / raise the possibility
→ indicate / support → demonstrate / establish / confirm
```

Moving a claim UP this scale = **overstatement**
Moving a claim DOWN this scale = **understatement** (less common, less harmful, but still wrong)

#### Dimension 3: Feedback Loops
- Does the paper describe feedback loops the summary omits?
- Are feedback loops labeled with the correct sign (positive/negative)?
- Are proposed/speculative feedback loops distinguished from demonstrated ones?

#### Dimension 4: Pathway Accuracy
- Does the summary name the correct metabolic or signaling pathway?
- Does it correctly describe the direction of change (up/down/unchanged)?
- Does it confuse a compensatory adaptation with a causal mechanism?

#### Dimension 5: Completeness
- Are there parallel mechanisms in the paper that the summary omits?
- Are there critical negative results (X does NOT cause Y) that the summary omits?
- Are reversibility experiments mentioned if the paper uses them to establish causality?
- For any interaction claim (interacts/binds/associates), does the summary state where the paper localizes it? (Under-Localized Interaction, common-errors 9)

#### Dimension 6: Composite Inference
- Does the summary combine multiple individually-supported findings into a single composite claim that the paper never explicitly makes?
- If so, is the composite inference reasonable, or does it overreach?

### Step 4: Classify Each Item

- **CORRECT** — Mechanism matches the paper in content and epistemic register
- **INCOMPLETE** — Mechanism is partially right but missing key elements (feedback loop, parallel arm, negative result)
- **INCORRECT** — Mechanism mischaracterizes causality, pathway direction, feedback sign, or epistemic register
- **MISSING** — Paper describes a mechanism the summary does not mention at all

### Step 5: Update Check Report

Update the NEEDS_CHECK table in `Working/check2.txt`:

```
## Phase 2: Deep Verification
| # | Claim (brief) | Verdict | Error Types | Paper Says | Suggested Correction |
|---|---------------|---------|------------|------------|---------------------|
| 5 | Enzyme W cleaves substrate V to activate receptor U | INCORRECT | Epistemic Overstatement | Paper: "raising the possibility that cleavage of V may activate U signaling" | Change to: "cleavage of V by enzyme W may activate receptor U signaling" |
| 6 | Regulator A recruits partner B to its target site | INCORRECT | Necessity vs Agency (10); Under-Localized Interaction (9) | Paper: "A co-localizes with B"; "depletion of A decreases B at the target site." No forward experiment shows A actively recruits B. | Change to: "A co-localizes with B, and depletion of A decreases B at the target site, indicating A is required for B there." (resolves both: replaces the agency verb "recruits" with loss-of-function framing, and adds the co-localization the summary omitted) |
```
For each row, before finalizing the Suggested Correction, compare it against your own Paper Says entry. If you recorded something in Paper Says that the summary is missing, the correction should include it. A fact in Paper Says but absent from the correction means the correction is incomplete.

When a claim has more than one error type, the correction must resolve all of them; fixing one does not complete the row. Before finalizing, check the correction against your own Paper Says entry: any fact recorded there that the summary lacks (e.g, a location + the paper's actual verb) must appear in the correction.

### Step 6: Generate Corrected Output

Create `Working/draft_summary3.txt` with all corrections applied.

---

### Step 7: Paragraph Coherence Check

After all claims are corrected, read `Working/draft_summary3.txt` as prose. A paragraph built from correct claims can still mislead through how they are joined.

Do not judge the paragraph as a whole. Go sentence by sentence. For every sentence that joins more than one component (multiple clauses, a chained cause and effect, or a trailing participle like "activating D," "driving D," "leading to D"), do this:

1. List each way the sentence could be read for causal direction, every clause the participle or effect could attach to.
2. Check the paper for which reading is correct.
3. If the sentence's most natural reading does not match the paper, rewrite it so only the paper's reading remains.

- **Misreads:** "A binds B and interacts with C, and loss of A decreases C at B, activating D." This can be read two ways: (i) A binding B and interacting with C activates D, or (ii) loss of A activates D. The trailing "activating D" attaches to the nearest clause, giving reading (ii), the inverse of the mechanism. The paper supports (i).
- **Fix:** "A binds B and interacts with C to activate D; loss of A decreases C at B."

4. When reattaching a participle to its cause, do not introduce an active verb the paper doesn't support. If the paper's evidence for the link is depletion (loss of X decreases Y), keep the depletion framing rather than writing "X promotes/drives Y."

Enumerate the readings explicitly before deciding; do not pass a multi-component sentence on the impression that it reads correctly. Fix only sentence structure, not verified content. Record any fix in `Working/check2.txt` under `## Paragraph Coherence`.

---

## Correction Guidelines

| Issue Type | How to Correct |
|------------|----------------|
| Epistemic overstatement | Downgrade verb to match paper's register |
| Epistemic understatement | Upgrade verb to match paper's register |
| Missing feedback loop | Add feedback loop with correct sign and paper's epistemic framing |
| Reversed causality | Swap the direction of the causal arrow |
| Adaptive response miscast as driver | Reframe as adaptation/consequence, not cause |
| Missing parallel mechanism | Add the missing arm if it is central to the paper's model |
| Composite inference overreach | Split into individually supported statements, or add appropriate hedging |
| Missing negative result | Add the negative result if it rules out an obvious alternative |
| Structural/placement error | Move the claim to the correct position in the causal chain |

---

## Common Error During Deep Check

**Pattern:** Agent correctly identifies an epistemic overstatement but then over-corrects by hedging everything, including claims the paper states as demonstrated fact.

**Example:**
- Paper: "Knockout of channel Q abolished calcium influx in cardiomyocytes (Fig. 3d)"
- Agent over-corrects to: "Knockout of channel Q may reduce calcium influx"
- RIGHT: "Knockout of channel Q abolished calcium influx in cardiomyocytes (Fig. 3d)"

**Rule:** Match the paper's register exactly. Don't add hedges the paper doesn't use. Don't remove hedges the paper does use. The goal is fidelity, not caution.

---

## What NOT to Do

| Wrong | Right |
|-------|-------|
| Hedge every claim "to be safe" | Match the paper's exact epistemic register |
| Flag a claim as INCORRECT just because it combines two findings | Only flag if the combination creates a claim the paper doesn't support |
| Add mechanisms the summary doesn't cover | Only add if a CRITICAL parallel arm is missing (Error Type 4b) |
| Rewrite the summary in your own style | Preserve original structure and voice; change only what is wrong |
| Ignore the Discussion section | The Discussion often contains feedback loops, speculative models, and epistemic framing that the Results alone don't capture |
