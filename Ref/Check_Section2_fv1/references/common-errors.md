# Common Errors in Section 2: Mechanistic Descriptions

## Error Types

### 1. Missing Feedback Loops — CRITICAL COMMON ERROR

**Pattern:** The paper describes a feedback loop (positive or negative) within the mechanism, but the summary presents the pathway as a simple linear chain, omitting the loop entirely.

**Subtypes:**

#### 1a. Missing Positive Feedback Loop

**Pattern:** A downstream product or consequence feeds back to amplify an upstream step. The summary describes only the forward direction.

**Example:**
- Paper: "Activated platelet-derived PDGF-BB stimulates vascular smooth muscle cell (VSMC) proliferation. Proliferating VSMCs in turn release thromboxane A2, which promotes further platelet activation and PDGF-BB release, forming a positive feedback loop that sustains neointimal growth (Fig. 5c,d)."
- Summary: "Platelet-derived PDGF-BB stimulates VSMC proliferation (Fig. 5c,d)."
- Problem: Omits the positive feedback where VSMC-derived thromboxane A2 amplifies platelet activation.
- Fix: "...stimulates VSMC proliferation. Proliferating VSMCs release thromboxane A2, which promotes further platelet activation and PDGF-BB release, forming a positive feedback loop (Fig. 5c,d)."

#### 1b. Missing Negative Feedback Loop

**Pattern:** The mechanism includes a self-limiting or homeostatic loop, but the summary describes it as unidirectional.

**Example:**
- Paper: "Excess hepatic iron activates hepcidin transcription via BMP6 signaling. Hepcidin degrades ferroportin on enterocytes, reducing dietary iron absorption and forming a negative feedback loop that prevents iron overload (Fig. 2a–c)."
- Summary: "Excess hepatic iron activates hepcidin transcription via BMP6 (Fig. 2a–c)."
- Fix: "...activates hepcidin transcription, and hepcidin in turn degrades ferroportin to reduce iron absorption, forming a negative feedback loop (Fig. 2a–c)."

#### 1c. Missing Speculative Feedback — With Epistemic Mismatch

**Pattern:** The paper proposes a speculative feedback loop (using "we speculate," "may," "could"), and the summary either omits it entirely OR includes it but presents it as established.

**Example (omission):**
- Paper: "We speculate that the resulting accumulation of ceramide in the outer mitochondrial membrane could impair cytochrome c release, dampening apoptotic signaling and thereby sustaining the ceramide-producing enzyme activity."
- Summary: [no mention of ceramide-mediated feedback on apoptotic signaling]
- Fix: Add with matching hedge: "The authors speculate that ceramide accumulation in the outer mitochondrial membrane could impair cytochrome c release, potentially dampening apoptotic signaling in a self-sustaining loop."

**Example (overstatement):**
- Paper: "We speculate that ceramide accumulation could impair cytochrome c release."
- Summary: "Ceramide accumulation impairs cytochrome c release, stabilizing the anti-apoptotic state."
- Problem: Paper speculates; summary states as fact.
- Fix: "Ceramide accumulation is proposed to impair cytochrome c release, which could stabilize the anti-apoptotic state."

---

### 2. Epistemic Overstatement — CRITICAL COMMON ERROR

**Pattern:** The summary presents a claim with greater certainty than the paper supports. This is the single most frequent error in mechanism summaries.

**Subtypes:**

#### 2a. Hypothesis Stated as Fact

**Pattern:** The paper frames a finding as "suggesting," "consistent with," or "we hypothesize," but the summary presents it as an established mechanism.

**Example:**
- Paper: "Reduced incorporation of deuterium-labeled serine into sphingolipids, coupled with increased incorporation into nuclear histones, is consistent with the possibility that one-carbon units are diverted from sphingolipid headgroup synthesis toward histone methylation (Fig. 7d,e)."
- Summary: "One-carbon units are diverted from sphingolipid synthesis toward histone methylation (Fig. 7d,e)."
- Problem: Paper says "consistent with the possibility"; summary states as accomplished fact.
- Fix: "...consistent with the possibility that one-carbon units are diverted from sphingolipid synthesis toward histone methylation (Fig. 7d,e)."

**Detection method:** Grep for these paper phrases near the claim's key terms:
- "suggest(s/ing)", "consistent with", "raise(s) the possibility", "might", "may", "could"
- "we hypothesize", "we speculate", "we propose", "it is conceivable", "it is possible"
- "remains unclear", "remains to be defined", "warrants further investigation"

If ANY of these appear in the paper's statement of this mechanism, the summary MUST preserve the hedge.

#### 2b. Composite Inference Overstatement

**Pattern:** The summary combines two or more individually supported findings into a single composite claim that the paper never explicitly makes as one statement. Each piece is correct, but the assembled statement goes beyond what any single paper sentence states.

**Example:**
- Paper finding 1: "Deacetylase SIRT3 binds scaffold protein X independently of NAD+ (Co-IP, Fig. 4a)"
- Paper finding 2: "Scaffold protein X localizes to the outer mitochondrial membrane in a cardiolipin-dependent manner (Fig. 4c)"
- Paper finding 3: "SIRT3 depletion reduces cardiolipin synthase activity at the outer membrane (Fig. 4e)"
- Summary: "The SIRT3–scaffold X complex localizes to the outer mitochondrial membrane in a cardiolipin-dependent manner, where SIRT3 activates cardiolipin synthase."
- Problem: The paper shows SIRT3 binds X, X localizes cardiolipin-dependently, and SIRT3 loss reduces cardiolipin synthase activity — but never shows the preformed complex localizes as a unit or that SIRT3 directly activates the synthase at that location.
- Rule of thumb: If the composite requires assuming a mechanism the paper did not test (e.g., the complex arrives as a preformed unit), flag as NEEDS_CHECK and note the inference. If the composite simply restates what the paper's combined data clearly show, it is acceptable.

#### 2c. Demonstrated Result Presented as Mere Association

**Pattern:** The paper says "demonstrates" or "confirms" but the summary downgrades to "is associated with" or "correlates with." Less common but still an error.

---

### 3. Mischaracterizing Metabolic or Physiological Pathway Shifts — CRITICAL COMMON ERROR

**Pattern:** The summary incorrectly describes what a metabolic or physiological change actually is, or confuses its functional role.

**Subtypes:**

#### 3a. Confusing Adaptation with Causal Mechanism

**Pattern:** The summary states that a compensatory pathway change is the *cause* or *maintenance mechanism* of an upstream perturbation, when it is actually a downstream adaptation that supports survival.

**Example:**
- Paper: "Cardiomyocytes subjected to chronic pressure overload upregulate fatty acid oxidation genes as a compensatory response to maintain ATP output despite impaired glucose uptake (Fig. 8b,c)."
- Summary: "Upregulated fatty acid oxidation drives pressure-overload hypertrophy (Fig. 8b,c)."
- Problem: FAO upregulation is a compensatory adaptation TO pressure overload, not a driver OF it.
- Fix: "Cardiomyocytes adapt to chronic pressure overload by upregulating fatty acid oxidation to maintain ATP output (Fig. 8b,c)."

#### 3b. Naming the Wrong Metabolic Shift

**Pattern:** The summary names an incorrect pathway or metabolite.

**Example:**
- Paper: "Astrocytes shift from glutamine export to GABA shunt flux under hyperammonemia (Fig. 3a)."
- Summary: "Astrocytes shift from glutamine export to lactate shuttling under hyperammonemia (Fig. 3a)."
- Problem: The shift is to GABA shunt flux, not lactate shuttling.
- Fix: Match the paper's pathway name exactly.

#### 3c. Confusing Unchanged with Changed

**Pattern:** The paper shows a metabolite or enzyme is NOT changed (a critical negative result ruling out an alternative mechanism), but the summary omits this or implies it is changed.

**Example:**
- Paper: "Levels of acetyl-CoA, NAD+/NADH ratio, and ACLY protein were unchanged between treated and control hepatocytes (Fig. 4a, Supplementary Fig. 5a), ruling out canonical acetylation-driven mechanisms."
- Problem if omitted: The reader might assume the standard acetylation pathway is responsible, when the paper's key insight is that it is NOT.
- Fix: Include the negative result, as it establishes what the mechanism is NOT.

---

### 4. Omitting Critical Components or Parallel Mechanisms — CRITICAL COMMON ERROR

**Subtypes:**

#### 4a. Missing Reversibility Evidence

**Pattern:** The paper uses reversibility experiments to validate the causal chain. The summary omits this.

**Example:**
- Paper: "Genetic re-expression of phosphatase PP2A or pharmacologic treatment with okadaic acid restored baseline ERK phosphorylation and normalized downstream transcriptional output (Fig. 6d–f), confirming PP2A loss as the upstream driver."
- Summary: "PP2A loss increases ERK phosphorylation and alters transcription."
- Fix: Include reversibility: "Re-expression of PP2A or okadaic acid treatment restored ERK phosphorylation and transcription toward baseline (Fig. 6d–f), confirming PP2A loss as the upstream driver."

#### 4b. Missing Parallel Pathway

**Pattern:** The paper describes two or more parallel arms of a mechanism. The summary covers only one.

**Example:**
- Paper describes both: (i) transcriptional repression of gene set A via promoter hypermethylation, AND (ii) post-translational stabilization of repressor protein B via reduced ubiquitination. Both contribute to the phenotype.
- Summary: Only mentions promoter hypermethylation arm.
- Fix: Include both arms.

#### 4c. Missing Critical Negative Result

**Pattern:** The paper rules out an alternative mechanism, and this negative result is important for establishing which branch of a pathway is operative. The summary omits it.

**Example:**
- Paper: "Inhibition of receptor tyrosine kinase A had no effect on cell migration, whereas blockade of G-protein-coupled receptor B abolished it, indicating that GPCR-B (not RTK-A) mediates the chemotactic signal (Fig. 5e)."
- Summary: "Blockade of GPCR-B abolished cell migration (Fig. 5e)."
- Fix: "Inhibition of RTK-A had no effect, whereas GPCR-B blockade abolished migration, indicating GPCR-B (not RTK-A) as the operative receptor (Fig. 5e)."

#### 4d. Missing Generalization Evidence

**Pattern:** The paper shows the mechanism operates in multiple independent models, establishing generalizability. The summary mentions only one model.

---

### 5. Incorrect Causal Direction — IMPORTANT COMMON ERROR

**Subtypes:**

#### 5a. Reversed Causality

**Pattern:** Summary says A → B; paper shows B → A.

**Example:**
- Paper: "Loss of claudin-7 disrupts tight junction integrity, leading to increased paracellular permeability (Fig. 2f)."
- Summary: "Increased paracellular permeability causes claudin-7 loss (Fig. 2f)."
- Fix: Reverse the arrow.

#### 5b. Confusing Upstream Driver with Downstream Consequence

**Pattern:** The summary places a downstream event as the initiating cause.

#### 5c. Ambiguous Positioning of a Claim in the Causal Chain

**Pattern:** The summary inserts a finding at the wrong position, so it appears to be a cause when it is a parallel consequence, or vice versa.

**Example:**
- Summary: "Kinase X activates transcription factor Y, which upregulates both target gene set A — accompanied by cytoskeletal remodeling — and target gene set B."
- Paper: Cytoskeletal remodeling is driven by kinase X directly (not via TF-Y or gene set A). Inserting it parenthetically within the TF-Y clause implies a dependency the paper does not support.
- Fix: Separate the cytoskeletal claim from the TF-Y/gene-set clause.

---

### 6. Structural and Placement Errors — MODERATE COMMON ERROR

**Pattern:** A claim is factually correct but placed in a position within the summary sentence that implies a relationship (specificity, causality, temporal order) that the paper does not support.

**Example:**
- Summary: "Transcription factor Z activates inflammatory genes across Th1, Th2, and Th17 subsets — accompanied by enhanced antigen presentation — and metabolic-reprogramming genes."
- Paper: Enhanced antigen presentation is a separate consequence of TF-Z activity in dendritic cells, not a feature of Th-cell gene activation. The parenthetical placement implies it is specific to T helper subsets.
- Fix: Move the antigen presentation claim to its own sentence outside the T-cell-specific clause.

---

### 7. Distributed Overclaim Across a List — IMPORTANT COMMON ERROR

**Pattern:** A single strength or causal word is applied to a list of outcomes, but the paper supports it for some outcomes and not others. Verify the predicate against the paper for each outcome separately, and match the paper's actual language for each — the paper may support the strong word for some outcomes and only a weaker one for others.

**Example:**
- Summary: "Loss of X eliminates A, B, C, D, and E."
- Paper: X loss eliminates A, B, and C, but only reduces D and E.
- Fix: "Loss of X eliminates A, B, and C, and reduces D and E."

---

### 8. High-Risk Strong Verbs — CRITICAL COMMON ERROR

**Pattern:** A claim uses a strong completeness verb for an outcome where the paper's word is weaker. The strong verb says the effect goes to zero; the paper often shows the process still runs, just reduced or not boosted. A shared direction (both "went down") is not enough — the strength must match.

**High-risk strong verbs:** abolishes, eliminates, blocks, prevents, abrogates, ablates, completely, fully.

**Weaker words the paper may actually use:** reduces, attenuates, decreases, impairs, suppresses, partially, did not affect, is not sufficient to, fails to increase.

**The check:** for each strong verb, find the paper's word for that specific outcome. If the paper's word is weaker, replace the claim's verb with the paper's actual word, or mark NEEDS_CHECK.

**Example:**
- Summary: "Loss of X eliminates A and B."
- Paper: X loss eliminates A, reduces B.
- Fix: "Loss of X eliminates A and reduces B."

---

### 9. Under-Localized Interaction — IMPORTANT COMMON ERROR

**Pattern:** The summary states an interaction (A interacts with / binds / associates with B) but omits where the paper localizes it. Interaction verbs often drop the spatial fact, meaning where in the cell the association occurs, which is a real mechanistic constraint, not evidential detail.

**The check:** for each interaction claim, check whether the paper places the interaction at a location: a compartment, a structure, a specific site, or co-localization. If the paper localizes it and the summary does not, add the location. Even when the summary already implies the location, still state it explicitly for better downstream understanding.

**Example:**
- Summary: "A interacts with B."
- Paper: A interacts with B, and A and B co-localize.
- Fix: "A interacts and co-localizes with B."

---

### 10. Necessity vs Agency — CRITICAL COMMON ERROR

**Pattern:** The summary uses an active-agency verb (promotes, drives, recruits, enriches, enhances, causes) for a link the paper established only by loss-of-function (depletion or knockout reduces Y). A depletion result shows X is *required for* Y (necessity); it does not show X *actively drives* Y (agency). The active verb selects one mechanism out of several the depletion data allow: X might actively drive Y, or merely stabilize it, or keep an upstream state that Y depends on, or act indirectly. All produce "loss of X decreases Y," but only the first is "X promotes Y."

**The check:** what is the paper's evidence for this link? If it is loss-of-function (loss of X decreases Y), the faithful statement is "X is required for Y," or state the depletion result directly. Reserve active verbs (promotes, drives, recruits) for links where the paper shows the forward, gain-of-function result.

**Example:**
- Summary: "X promotes Y."
- Paper: depletion of X decreases Y; no forward experiment showing X drives Y.
- Fix: "X is required for Y" or "depletion of X decreases Y."

---

## Verification Checklist

For each claim, ask:

| Check | Question |
|-------|----------|
| Causal direction | Does the arrow point the right way? |
| Epistemic register | Does the claim match the paper's confidence level? |
| Feedback loops | Are all feedback loops present with correct sign and epistemic framing? |
| Pathway identity | Is the named pathway/metabolite correct? |
| Direction of change | Is up/down/unchanged stated correctly? |
| Negative results | Are important "X does NOT cause Y" results included? |
| Parallel arms | Are all arms of the mechanism represented? |
| Reversibility | Is causal validation via reversibility mentioned if the paper uses it? |
| Composite inference | Does combining findings create a claim the paper doesn't explicitly make? |
| Placement | Is the claim positioned correctly in the causal chain? |
| Strong verbs | Are strong verbs (abolishes/eliminates/completely) matched by an equally strong word in the paper for that outcome? |

If any check fails → NEEDS_CHECK
