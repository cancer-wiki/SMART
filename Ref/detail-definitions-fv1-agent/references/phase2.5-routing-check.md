# Phase 2.5: Routing Check — Write routing.json

## Goal
After Phase 1 (grep) and Phase 2 (supp), decide which terms need external agents to resolve.
**DO NOT trigger or simulate sub-agents.** Just write a JSON flag file.

## Two Routes

- **Route A** — definition NOT in this paper and NOT in supp, but paper cites a referenced paper for it
- **Route B** — definition uses a non-standard package/method (not KEGG/MSigDB, not AddModuleScore/score_genes)

If neither applies → term goes straight to Phase 3.

## The Routing Decision (per term)

```
For each term after Phase 2:

Q1. Is the definition complete and actionable?
    (Gene list fully available, or maps to a standard KEGG/MSigDB pathway)
     │
     ├── YES → Phase 3
     │
     └── NO → What is missing?
              │
              ├── Paper references a CLASSIFIER PACKAGE that produces
              │   categorical labels (subtypes, groups)
              │   → ROUTE B (package must be installed + guide written)
              │
              ├── Paper references a NON-STANDARD PACKAGE that bundles
              │   gene lists not available elsewhere
              │   → ROUTE B (package must be installed to extract gene lists)
              │
              ├── Paper cites an EXTERNAL REFERENCE as the source of
              │   a gene list or cell type definition
              │   → ROUTE A (gene list must be extracted from referenced paper)
              │
              └── None of the above
                    → Phase 3 (proxy or flag undefinable)
```

## What to Write

### 1. Record in definitions_detail.txt Section 3

```
## Section 3: Phase 2.5 Routing Log

| # | Term | Route | Ref/Package | Reason |
|---|------|-------|-------------|--------|
| 3 | immune signature | A | ref 22, Smith et al. | gene list defined in referenced paper |
| 7 | tumor subtype | B | SubtypeClassifier R package | classifier producing categorical labels |
```

### 2. Write Working/routing.json

```json
{
  "route_a": [
    {
      "term_number": 3,
      "term_name": "immune cell signature",
      "ref_number": 22,
      "reason": "gene list defined in referenced paper, not in this paper"
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

If no terms need routing: `{"route_a": [], "route_b": []}`

**Always write routing.json, even if empty.** The pipeline checks this file to decide whether to run external agents.

## Classifier Packages Must Always Route B

**Classifier packages must always be routed to Route B.** If the definition requires running a classifier that produces categorical class labels (subtypes, groups), it MUST go to Route B — even if the paper describes the method in full detail. The purpose is to install the package and write a usage guide for the further-annotate agent. Gene-set scoring (ssGSEA, AddModuleScore, GSVA, module scores) does NOT need Route B — once the gene list is extracted, the code-agent handles all scoring with standardized functions.

## What NOT to Do

| Wrong | Right |
|-------|-------|
| Try to trigger check-external-ref-v1-agent | Just write routing.json |
| Simulate what the sub-agent would return | Write "external ref (pending)" as placeholder |
| Fabricate a gene list for Route A terms | Write the ref citation as the definition |
| Skip writing routing.json when no routing needed | Always write it, even if empty arrays |
| Route B just because a gene set has weights | Weighted sets are standard → Phase 3 |
| Resolve a classifier package inline because the paper describes it | Route B — the package must be installed and a guide written |
