# Section 2 Checker - Quick Reference

## Purpose
Verify and correct mechanistic descriptions in the Mechanism section of paper summaries.

## Files
| Type | Path |
|------|------|
| Input | `Working/draft_summary2.txt` |
| Input | `Inputs/paper1_text.txt` |
| Output | `Working/check2.txt` |
| Output | `Working/draft_summary3.txt` |

## Workflow
```
Phase 1: Claim extraction + keyword/figure grep → Phase 2: Deep mechanism verify → Phase 3: Corrected output
```

## Quick Rules
- **Phase 1:** Extract every causal claim, grep paper for key terms AND figure refs to get line numbers
- **Phase 2:** Read paper lines ±5 around each hit; compare causal direction, hedge level, feedback loops
- **Phase 3:** Fix only what is wrong — preserve original structure and style
- **Don't** add mechanisms the summary doesn't cover (unless a critical parallel arm is missing)
- **Don't** upgrade the paper's hedged language to certainty, or downgrade demonstrated claims to speculation
- **Do** fix causal direction errors, missing feedback loops, overstatements, composite inferences
- **Do** match the paper's epistemic register (speculates → speculates, demonstrates → demonstrates)
- **Do** grep figure references (e.g., "Fig. 4a") when the summary cites them — the surrounding sentence is often the exact source of the claim
