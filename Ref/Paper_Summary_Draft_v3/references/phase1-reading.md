# Phase 1: Read & Understand (+ Passive Mapping)

## Goal
Understand what this paper is about.

The map is a **byproduct**, not the focus.

---

## Steps Overview

Step 1: Read for Understanding → Step 2: Run Mapping Command → Output: map.txt

---

## Process

### Step 1: Read for Understanding

Read `Inputs/paper1_text.txt` from start to finish.

**Focus on:**
- What is the main discovery?
- What is the biological mechanism?
- Why does it matter?

**Do NOT focus on:**
- Memorizing every figure reference
- Extracting every statistic
- Deciding which figures to cite

### Step 2: Passive Mapping 

You don't need to do this during reading. After reading, just run this command: 

python3 extract_figures.py Inputs/paper1_text.txt > Working/map.txt

This code automatically grabs every sentence referencing figures into map.txt for later use in other agents. 

No analysis. No decisions. Just run this command, do not read the map.txt right now. 

---

## What NOT to Do

| Wrong | Right |
|-------|-------|
| Analyze which figures are important while reading | Just run the command to copy to map.txt |
| Decide which figures to cite | That's Phase 2 |
| Look at figure images | Not needed for draft |
| Try to remember all statistics | They're in the map for later |

---

## Output

After Phase 1, you should have:

1. **Understanding** of the paper's main story (in your head)
2. **map.txt** file with all figure-referencing sentences (auto-saved to `Working/map.txt`)

---

## Transition to Phase 2

Once you've read the entire paper and run the mapping command:
- You understand the discovery, mechanism, significance
- You have a reference of all figure citations
- Now write the draft summary from understanding