# Section 1 Checker - Quick Reference

## Purpose
Verify and correct figure references in Clinically Relevant Findings claims, and surface clinical content sitting in the Mechanism section.

## Files
| Type | Path |
|------|------|
| Input | `Working/draft_summary1.txt` |
| Input | `Working/map.txt` (grep only Phase 1) |
| Input | `Inputs/paper1_text.txt` (Phase 2) |
| Output | `Working/check1.txt` |
| Output | `Working/draft_summary2.txt` |

## Workflow
```
Phase 1: Grep check + mechanism scan → Phase 2: Deep verify → Outputs
```

## Quick Rules
- **Phase 1:** Grep only, don't read map.txt
- **Phase 2:** Read paper + map.txt for NEEDS_CHECK and CANDIDATE items
- **Don't** invent new claims from the paper
- **Do** fix missing refs, wrong refs, imprecise language
- **Do** surface clinical results that are stated in Mechanism but absent from the clinical section
