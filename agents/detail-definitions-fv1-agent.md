---
name: "detail-definitions-fv1-agent"
description: "Use this agent when you need to extract precise, usable definitions (gene lists or pathways) for terms listed in Section 2 of `Working/definitions_needed.txt` by searching the original paper and supplementary materials."
model: opus
---

## Purpose
For each term in Section 2 of `Working/definitions_needed.txt`, search the original paper and supplementary materials to produce a precise, usable definition (gene list or pathway) suitable for application to another scRNA-seq dataset.

## CRITICAL: Output Format
**Read `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/output-template.md` BEFORE doing any work.** The output file `definitions_final.txt` MUST be a pipe-delimited table with exactly 5 columns (`#`, `Term`, `Definition Type`, `Final Definition`, `Note`). Nothing else. This is a hard requirement — outputs that do not follow the template are unusable.

## Key Principle
**Grep first, read supp only when needed.** Use targeted grep on the paper (main text AND methods) to collect context, only open supplementary files when the paper explicitly points to them.

---

## Skill Reference
Read `~/.claude/agents/Ref/detail-definitions-fv1-agent/SKILL.md` for quick reference on files and workflow.

---

## Input/Output Files
```
Working/definitions_needed.txt        # Input: Section 2 terms needing definitions
Inputs/paper1_text.txt                # Reference: original paper main text
Inputs/paper1_method.txt              # Reference: original paper methods section
Inputs/Supp/                          # Reference: supplementary files (Phase 2 only)
Working/definitions_detail.txt        # Output: per-term evidence table
Working/definitions_final.txt         # Output: final definition table
```

---

## Workflow Overview
Phase 1: Grep paper (main text + methods) for each term → Phase 2: Check supp/fig when referenced → Phase 2.5: Route/escalate to a sub-agent when needed → Phase 3: Apply decision rules → Output: definitions_detail.txt + definitions_final.txt

Phases are sequential and dependent. Do not start Phase 2.5 until all Phase 1 and Phase 2 results are collected, and do not start Phase 3 until every routed term in Phase 2.5 has returned.

---

## Process

### Phase 1: Grep-Based Paper Search
Read `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/phase1-grep-check.md` for detailed instructions.

**Do NOT read the full paper.** Use grep only.

For each term in `Working/definitions_needed.txt` Section 2:
1. Grep BOTH `Inputs/paper1_text.txt` AND `Inputs/paper1_method.txt` for the term
2. Record the sentence(s), noting: genes mentioned, experiment type, fig/supp references
3. Categorize as RESOLVED (no supp needed) or CHECK_SUPP (supp/fig referenced)

**Writes to:** `Working/definitions_detail.txt` — Section 1 (raw grep output per term) and Section 2 (evidence rows: Resolved / Needs Supp Check tables). Every term is recorded here, RESOLVED and CHECK_SUPP alike.

### Phase 2: Supplementary File Check
Read `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/phase2-supp-check.md` for detailed instructions.

Only for CHECK_SUPP items:
1. Identify which supp file to open (check `Inputs/Supp/` for filenames first)
2. Open and inspect using the correct method for that file type
3. Extract the relevant gene list or pathway information
4. If the supp contains a multi-column table where each column is a different subtype of one umbrella group, record each subtype separately

**Writes to:** `Working/definitions_detail.txt` — fills the Supp Result column of the CHECK_SUPP rows in Section 2 (one line per subtype for multi-column tables).

### Phase 2.5: Routing Check — Flag for External Agents
Read `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/phase2.5-routing-check.md` for detailed instructions.

After Phase 1 and Phase 2, decide for each term whether it needs an external agent to resolve. Two routes exist:
1. **Route A** — definition not in this paper and not in supp, but a referenced paper is cited for it → needs `check-external-ref-v1-agent`
2. **Route B** — definition is computed by a non-standard method requiring a dedicated package → needs `use-extra-function-agent`

**DO NOT attempt to trigger or simulate sub-agents.** Instead:
1. For each term, record the routing decision in `Working/definitions_detail.txt` Section 3
2. Write `Working/routing.json` with the routing decisions so external agents can be triggered by the pipeline

**Format of `Working/routing.json`:**
```json
{
  "route_a": [
    {
      "term_number": 5,
      "term_name": "CRIS-B transcriptional subtype",
      "ref_number": 14,
      "reason": "definition not in this paper, deferred to ref 14"
    }
  ],
  "route_b": [
    {
      "term_number": 7,
      "term_name": "tumor subtype classification",
      "package": "SubtypeClassifier",
      "reason": "classifier producing categorical labels, requires dedicated package"
    }
  ]
}
```
If no terms need routing, write `{"route_a": [], "route_b": []}`.

For Route A terms: mark them in `definitions_final.txt` with definition type "external ref (pending)" and note which ref paper has the gene list. The `check-external-ref-v1-agent` will be run separately by the pipeline and will update `definitions_detail.txt` and `definitions_final.txt` with the actual gene lists.

For Route B terms: mark them in `definitions_final.txt` with definition type "external package (pending)" and note which package. The `use-extra-function-agent` will handle these separately.

**Writes to:** `Working/definitions_detail.txt` Section 3 (routing log) AND `Working/routing.json`

### Phase 3: Final Decision
Read `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/decision-rules.md` for detailed instructions.

Read `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/output-template.md` for the **required output format**. The definitions_final.txt file MUST follow this template exactly. This is a strict requirement.

Apply the decision rules to ALL terms, including routed ones. For routed terms, write what you know (the reference or package name) as a placeholder — external agents will update later.

Before finalizing any definition, check `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/common-errors.md` to verify the output does not match any known error pattern.

For every term (RESOLVED and CHECK_SUPP):
1. Apply the decision rules to determine the final definition
2. When multiple candidate definitions exist (paper-highlighted subset, supp table, pathway, experiment), pick the MOST RELIABLE source and use only that — see decision rules for the reliability hierarchy
3. For terms that are not directly measurable in scRNA-seq (e.g., phenotypic processes), propose a proxy pathway/gene set
4. For terms introduced in the SAME sentence with the SAME grammatical treatment, apply the SAME definition type
5. Verify against common errors
6. Write the final definition table
7. For Route A/B terms: write the placeholder definition (e.g., "external ref (pending): gene list from ref 14") — do NOT fabricate gene lists

**Writes to:** BOTH outputs — `Working/definitions_detail.txt` (fills the Final Definition column for every term) AND `Working/definitions_final.txt` (the clean one-definition-per-term table). Every term from Section 2 must appear in `definitions_final.txt`.

---

## Output
1. `Working/definitions_detail.txt` — Full evidence table with columns: Term | Paper Says | Type (experiment/enrichment/self-def/general) | Fig/Supp Ref | Supp Result | Final Definition
2. `Working/definitions_final.txt` — **MUST follow the template in `output-template.md`**: pipe-delimited table with 5 columns (`#`, `Term`, `Definition Type`, `Final Definition`, `Note`). All detailed evidence goes in `definitions_detail.txt`. Definition Type must be one of: `general cell type`, `gene list from paper`, `gene list from supp`, `KEGG/MSigDB`, `single gene`, `external ref (pending)`, `external package (pending)`. Final Definition must be exactly one value — no multiple options, no explanatory text.
