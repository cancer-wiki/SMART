# Paper Summary Skill

## Purpose
Extract core scientific discoveries from research papers.

## Key Principle
**Comprehension before extraction.** Understand first, extract details later.

---

## Output Format

Write 2 sections to `Working/draft_summary1.txt`:

| Section | Content |
|---------|---------|
| 1. Clinically Relevant Findings | all patient-level findings with figure refs (draft) |
| 2. Mechanism | Causal chain paragraph (draft) |

**Max 300 words total.**

---

## Quick Rules

**Section 1 — Clinically Relevant Findings:**
- Focus on patient-level and translational findings ONLY
- Include: expression differences in patient tissues (disease vs normal), therapeutic agent results (inhibitors, agonists rescuing phenotypes), prognostic associations (survival, prognosis correlation)
- Exclude: mechanistic experiments (knockouts, domain deletions, promoter binding, pathway dissection) — those belong in Section 3 (Mechanism)

**Figure citations:**
- Include subfigure letters: `(Fig. 2a)` not `(Fig. 2)`
- Prefer main figures over extended figures

**Terminology:**
- Use paper's exact terms: "SPP1+ macrophage" not "macrophage"
- Match paper's causal language — don't upgrade "associated" to "causes"

---

## File Structure
```
Inputs/paper1_text.txt    # Input
Working/map.txt           # Phase 1 byproduct
Working/draft_summary1.txt # Final output
```
