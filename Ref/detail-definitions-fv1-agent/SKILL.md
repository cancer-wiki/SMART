# Definition Checker - Quick Reference
## Purpose
Look up and finalize definitions for cell types / gene sets listed in Section 2, by searching the original paper and supplementary files.
## Files
| Type | Path |
|------|------|
| Input | `Working/definitions_needed.txt` (Section 2: terms needing definitions) |
| Input | `Inputs/paper1_text.txt` (original paper main text) |
| Input | `Inputs/paper1_method.txt` (original paper methods section) |
| Input | `Inputs/Supp/` (supplementary files — xlsx, pdf, docx, figures) |
| Output | `Working/definitions_detail.txt` (per-term grep evidence + supp results) |
| Output | `Working/definitions_final.txt` (final definition table) |
## Workflow
```
Phase 1: Grep paper (main + methods) → Phase 2: Check supp files → Phase 2.5: Route/escalate to sub-agent (optional) → Phase 3: Final decision → Outputs
```
## Quick Rules
- **Phase 1:** Grep BOTH `paper1_text.txt` AND `paper1_method.txt`; collect sentences mentioning the term, note any fig/supp refs; check ALL grep hits, not just the first
- **Phase 2:** Only for terms that reference a supp/fig — open and inspect
- **Phase 2 (multi-subtype table):** If a supp lists one umbrella group as multiple columns, each column being a distinct subtype (e.g., one column per cell subtype of a broader category), record EACH subtype separately — do NOT merge all columns into one flat gene list
- **Phase 2.5 (optional per term):** After supp, decide whether to escalate. Two mutually-exclusive routes; skip if neither fits. Record the routing decision in `definitions_detail.txt` Section 3 and write `Working/routing.json`. Do NOT trigger sub-agents — the pipeline runs them separately. See `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/phase2.5-routing-check.md`
- **Phase 2.5 Route A (other paper):** definition not in this paper AND not in supp, BUT the paper cites a referenced paper for it → record in routing.json. Mark in definitions_final.txt as `external ref (pending)`.
- **Phase 2.5 Route B (extra function):** definition requires a dedicated classifier or non-standard package → record in routing.json. Mark in definitions_final.txt as `external package (pending)`. A weighted gene set alone is still standard → not Route B.
- **Phase 3:** Apply decision rules to ALL terms including routed ones (write placeholders for routed terms), then check `~/.claude/agents/Ref/detail-definitions-fv1-agent/references/common-errors.md` before finalizing
- **Evidence types:** experiment / enrichment / self-def / general
- **general cell type** → final definition = literally `general cell type`, NOTHING else
- **KEGG/MSigDB** → final definition = a pathway name (e.g., `HALLMARK_G2M_CHECKPOINT`), NEVER individual genes
- **gene list from paper** → final definition = the exact genes the paper highlighted
- **gene list from supp** → final definition = genes extracted from the supp file
- **Highlight vs Full List** → if paper highlighted a subset for a reason (experiment/validation), use subset only; if no special reason and supp list is all same category, use full supp list
- **Conflicting sources → pick the most reliable** → if supp is a huge mixed DE table (not category-specific), the paper-highlighted subset is more reliable; if supp is a clean category-specific list and paper only gave examples, the supp is more reliable. Pick ONE source, never merge.
- **Validated genes from an enriched pathway BEAT the pathway name** → if the paper reports a pathway enrichment AND then validates specific genes from that pathway (by qPCR, ChIP, knockdown, rescue, etc.), the final definition is the validated gene list, NOT the pathway name. The pathway was the discovery tool; the genes are the finding.
- **Do NOT self-exclude paper-highlighted genes** → if the paper highlighted a gene (in text, figure label, heatmap, or supp table) as part of the answer, include it — even if you personally think it doesn't fit the category. The paper's framing wins over your biological judgment.
- **Not directly checkable in scRNA-seq?** → for phenotypic processes (e.g., migration, invasion, proliferation phenotype) that cannot be read off expression directly, propose a proxy gene set / pathway (usually KEGG/MSigDB) that captures the process
- **Same-sentence subsets → same criteria** → if multiple sub-terms are introduced in the same sentence with the same grammatical treatment (e.g., "pathway A (for example gene1, gene2), pathway B (for example gene3, gene4)"), apply the SAME definition type to all of them
- **single gene** → final definition = just that one gene symbol
- **ONE definition per term** → never give two options or "supplement with X"
- **Gene aliases** → always convert to official gene symbol (e.g., PD-L1 → CD274, F4/80 → ADGRE1)
- **Marker gene tables from clusters** → ignore (too specific), use main text description only
- **No parenthetical notes** → no aliases, no mouse/human conversion, no explanations (exception: experiment-based gene definitions CAN include "(self-proposed)" labels)
