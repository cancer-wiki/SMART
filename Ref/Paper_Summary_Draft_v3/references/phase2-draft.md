# Phase 2: Write Draft Summary

## Goal
Capture the paper's story in structured format based on your understanding.

---

## Steps Overview

Write Section 1 → Write Section 2 → Output: draft_summary1.txt

---

## Process

Write both sections to `Working/draft_summary1.txt`

### Section Status

| Section | Write from... | Status |
|---------|---------------|--------|
| 2. Clinically Relevant Findings | Understanding | **Draft** |
| 3. Mechanism | Understanding | **Draft** |

---

## Section 1: Clinically Relevant Findings (Draft)

**What to put here:** Patient-level and translational findings that highlight the clinical relevance of the discovery. This section is NOT for mechanistic evidence — it captures findings that matter at the patient or therapeutic level.

Important: if the paper doesn't have anything relevant, just put 'No clinical relevance reported in this paper' in this section.

Contain all the clinically relevant findings.

**Rules (apply to every category below):**
1. Capture every qualifying finding, not just the strongest one. If a paper reports several markers, survival endpoints, drugs, or cell types, each is a separate finding. Before finishing a category, re-scan for same-type findings you may have skipped as secondary.
2. Capture negative or null results when they are a deliberate finding (e.g. expression does not differ between tumor and normal, or does not predict prognosis), especially when they motivate the paper's main claim.
3. When a paper reports a result together with its negative counterpart (e.g. elevated in the authors' cohort but not in a public dataset, or predicts response to one drug but not another), capture both halves as one finding. Dropping the negative half is an error even when the positive half is stronger.
4. When a finding rests on a comparison, state both arms, not just the one that shows the effect.
5. Capture correlations of X with clinical or tumor features (stage, grade, MSI status, age), even when they appear as a secondary clause attached to a larger finding.
6. When citing part of a figure, check the remaining panels of that figure. Related results(including controls and comparison arms) are often in adjacent panels, and belong in the finding.
7. When a result mixes clinical and mechanistic content, capture the clinical part here and leave the rest to Mechanism. Do not drop it because the result as a whole looks mechanistic.

**Focus on these categories:**

**1. Expression in patient tissues:**
- Differences between disease vs normal tissue, or between disease subgroups (e.g. higher- vs lower-grade tumors, stage, metastatic vs primary, cancer vs healthy, precancerous vs invasive, early vs advanced), in patient samples (e.g. tissue, blood, organoids) at the level of expression or genomic alteration (mutation, amplification, deletion frequency) 
- Example: X is highly expressed in cancer tissues compared to normal (Fig. 1a). X is present in cancer but absent in healthy (Fig. 5m). If the same difference is shown in more than one sample type or cohort, capture them all.

**2. Therapeutic response — drug acts ON the target:**
- A drug, inhibitor, or agonist that directly targets X (or its immediate pathway) reverses or rescues disease-relevant phenotypes, in cells or in animal/organoid models.
- Example: Inhibitor Y reverses malignant phenotypes in X-overexpressing cells and/suppresses tumor growth in xenografts/patient organoids (Fig. 3a-k). If the same effect is shown in more than one model or experimental condition (cells, xenograft, organoid), capture them all.

**3. Prognostic associations:**
- X correlation with patient outcomes, survival, or prognosis, or with response to a specific therapy (predictive biomarker, where X predicts whether a particular drug will work). X can be an expression level, a post-translational modification, an activity state, etc.
- Example: X predicts poor patient prognosis (Fig. 8l-n); high X predicts non-response to anti-PD-1 (Fig. 6c-d). If the same outcome association is shown in more than one cohort or dataset, capture them all.

**4. Modulation of therapy sensitivity / resistance — gene changes response to a standard drug:**
- Depleting, overexpressing, or mutating X changes how cells respond to a clinically used drug, making them more sensitive or more resistant. When X affects response to one drug but not another, capture both — the drug with no change is part of the finding, not a reason to drop it.
- Example: X overexpression confers resistance to gemcitabine in tumor cells (Fig. 5c). If the same effect is shown across more than one drug or cell model, capture them all.

**5. Genetic modulation drives tumor growth in vivo:**
- Knockdown, overexpression, or mutation of X changes tumor growth in animal or organoid models (xenograft/CDX/PDX/PDO).
- Example: X mutant suppresses xenograft tumor growth vs wild-type (Fig. 8j-n). If the same effect is shown in more than one in vivo model, stage, or setting, capture them all.

**6. Biomarker performance:**
- How well X performs as a clinical test: reproducibility, discrimination (AUROC/C-index), or added value over existing markers. This is how reliably X works as a test, distinct from whether it correlates with outcome (category 3).
- Example: X classifies patients reproducibly across repeat samples and adds predictive value beyond existing markers (Fig. 1b-d). If the same result is shown across more than one cohort or validation set, capture them all.

**What does NOT belong here (put these in Section 3 — Mechanism instead):**
- Domain deletions, knockouts, or overexpression experiments used to dissect molecular function
- Promoter binding, transcriptional regulation
- Phosphorylation of downstream enzymes, metabolic flux measurements
- Pathway agonist/inhibitor experiments used purely to confirm a signaling mechanism

**The key distinction:** If a finding tells you something about the *patient* — expression pattern, treatment response, prognosis, or how a standard therapy will work — it goes here. If it tells you something about *how the molecule works*, it goes in Mechanism.

**Easy-to-miss findings, check for these explicitly:**
- When the paper states at what phase X appears or becomes active, capture that as a finding: it defines the window in which targeting X is relevant.
- Results from public or external datasets that disagree with the authors' own data, including ones that read as non-findings (e.g. a marker is elevated in the authors' cohort but shows no difference in a public dataset).
- Broad or setup findings that are prognostic in their own right but get overshadowed when the paper narrows to a specific subset (e.g. e.g. total lymphocyte infiltration predicts survival, then CD4 T cells becomes the highlight; still report the broad finding, not just the subset).
- Validation analyses showing the marker works as a usable test, not just that it correlates once (e.g. it stays consistent across independent samples or cohorts).
- Findings from mechanistic-looking experiments that the paper frames as a therapeutic target or vulnerability (e.g. removing X selectively harms disease cells).
- Background drawn from cited literature (e.g. a factor's known role or expression in other tissues or developmental stages) should be captured and labeled "cited, not shown here". When such background is needed to interpret the paper's own finding, state both in one claim: the background attributed as cited, the measured part with its figure.

---

## Section 2: Mechanism (Draft)

**What to put here:** The central mechanism the paper describes - what causes what and what leads to what.

You understand the mechanism from reading in phase 1. Write it now.

Summarize the central mechanism as a concise causal chain in a paragraph.

**Requirements:**
- State what causes what and what leads to what
- Include causal chains, parallel pathways, and feedback loops correctly
- Focus on the core regulatory logic — what controls the system, what activates or represses it, and what the functional outcome is
- Prioritize mechanistic insight over comprehensive listing — do not list every chemokine, receptor, or gene unless essential to understanding the mechanism
- Include therapeutic or experimental interventions (e.g., knockouts, inhibitors) if they reveal how the system can be modulated

**Rules:**
- Use paper's exact cell type names
- Match paper's causal language (don't upgrade "associated" to "causes")

---

## What NOT to Do in Phase 2

| Wrong | Right |
|-------|-------|
| Look at figures to get exact p-values | If numeric results not reported in the main text, leave as draft |
| Put mechanistic experiments in Section 1 | Mechanistic experiments go in Section 2 |
| Put patient-level findings only in Section 2 | Patient-level findings go in Section 1 |

---

## Final Output

Save completed draft to `Working/draft_summary1.txt`
Max 300 words

This is the final output of the workflow.
