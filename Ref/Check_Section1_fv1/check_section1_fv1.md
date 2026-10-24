# Summary Section 1 Checker Agent

# name: check-section1-fv1-agent
# model: opus

## Purpose
Verify and correct figure references and claim accuracy in the Clinically Relevant Findings section of paper summaries, and surface clinical content misplaced in the Mechanism section.

## Key Principle
**Grep first, read later.** Use targeted grep to quickly verify, only read full paper and Working/map.txt for unclear cases.

---

## Skill Reference

Read `~/.claude/agents/Ref/Check_Section1_fv1/SKILL.md` for quick reference on files and workflow.

---

## Input/Output Files
```
Working/draft_summary1.txt            # Input: contains both Clinically Relevant Findings and Mechanism
Working/map.txt                       # Reference: grep only in Phase 1
Inputs/paper1_text.txt                # Reference: Phase 2 only
Working/check1.txt                    # Output: Verification report
Working/draft_summary2.txt            # Output: Corrected summary
```

---

## Workflow Overview

Phase 1: Grep-based quick check + mechanism scan → Phase 2: Deep verification → Output: check1.txt + corrected summary

---

## Process

### Phase 1: Grep-Based Quick Check

Read `~/.claude/agents/Ref/Check_Section1_fv1/references/phase1-grep-check.md` for detailed instructions.

**Do NOT read map.txt directly.** Use grep only.

For each claim in the clinical section of the input file:
1. Identify all figure refs in the claim (e.g., "Fig. 2a-c" means grep 2a, 2b, 2c)
2. Grep each figure reference
3. Compare and categorize as CORRECT or NEEDS_CHECK

Then scan the Mechanism section for findings that contain a measured clinical result, and list them as CANDIDATE clinical claims.

### Phase 2: Deep Verification

Read `~/.claude/agents/Ref/Check_Section1_fv1/references/phase2-deep-check.md` for detailed instructions.

For NEEDS_CHECK items and CANDIDATE items:
1. Read `Inputs/paper1_text.txt`
2. Read `Working/map.txt`
3. Verify and correct

---

## Output

1. `Working/check1.txt` - Verification report with tables
2. `Working/draft_summary2.txt` - Corrected summary
