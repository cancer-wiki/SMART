# Debug Rules

How to diagnose and patch a failing run. The agent triages on the log file,
then applies one of the patch patterns below.

---

## Triage workflow

0. **First, confirm the run actually finished.** Long-running tasks — DE analysis, GO enrichment, looped correlations across many genes — can each take many minutes on their own; a full plan2 can run for an hour or more. A long silence in the terminal is NOT evidence of a crash. Before opening the log to diagnose:
   - Has the `Rscript` command exited and returned control to the shell? If not, **wait**.
   - If unsure, check that the log file is still being modified (`ls -l Working/...log` — recent mtime means the script is still writing) AND the R process is still alive (`pgrep -af Rscript`). If both are true, the run is still working — keep waiting.
   - Only proceed to step 1 below once `Rscript` has exited.

1. Read the relevant log file (`Working/preprocess.log` or `Working/analysis.log`).
2. Find the **first** unhandled error message. Earlier `[ERROR]` lines from a
   `tryCatch` block in the analysis script are NOT crashes — those are tasks
   that errored but the script kept going. The crash is the LAST line of the log
   (or the first line that prints `Error in ...` outside a tryCatch).
3. Match the error message against the categories below.
4. Apply the patch to a copy of the original script saved as
   `Outputs/preprocess_corrected.R` or `Outputs/analysis_corrected.R`.
5. Append a record to `Outputs/correction_record.txt`.
6. Re-run the corrected script. Stop after at most 3 correction attempts per
   script — beyond that, the issue is likely structural, not patchable.

---

## Category 1 — Wrong msigdbr collection / subcollection name

**The real concern here is the `"CP:KEGG"` → `"CP:KEGG_LEGACY"` rename.** That one
is a hard failure (`Error: Unknown subcollection`). The `category`/`subcategory`
vs `collection`/`subcollection` argument-name change is a deprecation warning,
not a crash — those still work in current msigdbr, they just print a warning.
Don't rewrite working `category =`/`subcategory =` calls unless they're actually
failing.

**Signals in the log:**
- `Error: Unknown subcollection` — almost always means the code uses
  `subcollection = "CP:KEGG"` (or `subcategory = "CP:KEGG"`), which no longer
  exists in msigdbr ≥ 10.0.
- `Error: Unknown collection` — uncommon; usually a typo in the collection
  letter (`"H"`, `"C2"`, `"C5"`).

**Fix:**
- Replace `"CP:KEGG"` → `"CP:KEGG_LEGACY"` (this is what the user almost always
  wants — the classic KEGG sets like `KEGG_GLYCOLYSIS_GLUCONEOGENESIS`).
- DO NOT change a working `"CP:KEGG_LEGACY"` to `"CP:KEGG_MEDICUS"` unless the
  pathway lookup fails on `LEGACY` and Category 2 below kicks in.
- Leave `category =` / `subcategory =` alone if they're working — they're
  deprecated aliases but still functional. Only rewrite to
  `collection =` / `subcollection =` if the script is actually failing on
  those argument names.

---

## Category 2 — Pathway / gene-set name not found

**Signals in the log:**
- An msigdbr call returned 0 genes
- `Error in AddModuleScore(...) : Gene set [...] is empty after filtering`
- `Warning: ... 0 genes found`
- A downstream step that depends on a `_score1` column fails with "column not
  found", and tracing back you find an empty gene list

**Fix:**
1. Note the misnamed pathway (e.g. user wrote `KEGG_GLYCOLYSIS`, but the real
   set name is `KEGG_GLYCOLYSIS_GLUCONEOGENESIS`).
2. Use the helper at
   `~/.claude/agents/Ref/Execute_Agent/references/pathway-helper.R`
   to find the correct name. In a debug R session:
   ```r
   source("references/pathway-helper.R")
   # Step 2a: try exact-name lookup across all sources
   genes <- get_pathway_genes("KEGG_GLYCOLYSIS")
   # → returns character(0) and prints [FAIL]

   # Step 2b: pattern search to discover the real name
   genes <- get_pathway_genes("KEGG_GLYCOLYSIS",
                              fallback_patterns = c("glycolysis", "glucose"))
   # → prints candidate gs_names like KEGG_GLYCOLYSIS_GLUCONEOGENESIS,
   #   REACTOME_GLYCOLYSIS, HALLMARK_GLYCOLYSIS, etc.
   ```
3. Pick the candidate that best matches the user's intent and substitute
   the correct `gs_name` (and the matching `collection` / `subcollection`)
   into the corrected script.
4. Run the corrected msigdbr call once more to confirm a non-empty gene list,
   then re-run the full script.

**Important:** do NOT pick a candidate at random. If multiple candidates are
plausible (e.g. `HALLMARK_GLYCOLYSIS` vs `KEGG_GLYCOLYSIS_GLUCONEOGENESIS`),
prefer the source the original code was already trying to use:
- Original code says `collection = "H"` → keep Hallmark
- Original code says `subcollection = "CP:KEGG_LEGACY"` → keep KEGG legacy
- Original code says `subcollection = "CP:REACTOME"` → keep Reactome

If the original was using a deprecated `"CP:KEGG"`, prefer the `_LEGACY` match.

---

## Category 3 — RAM exhaustion / out-of-memory crash

**Signals in the log** (only consider these AFTER `Rscript` has exited — see
Triage step 0; a script that's still running and has just been silent for a
while is NOT a RAM crash):
- `Error: cannot allocate vector of size X Gb`
- `Error: vector memory exhausted`
- The R process died abruptly with no R-level error message and the OS
  log shows OOM-killer (check `dmesg | grep -i kill` if available)
- The script printed progress through some tasks then stopped mid-task,
  with NO closing `========== ANALYSIS COMPLETE ==========` line, AND
  the `Rscript` command has returned to the shell (not still running)

**Fix — split the script at the crash point:**

1. Identify the last task that completed successfully (its `=== Task ... ===`
   header appears in the log, AND the next task's `=== Task ... ===` header
   either does NOT appear or appears followed by the crash).
2. Open the original script. Find the boundary between the last successful
   task block and the crashing task block.
3. Write `Outputs/analysis_corrected_part1.R`:
   - Copies the entire header (libraries, source, load data, AddMetaData merge,
     mkdir Outputs/...) verbatim.
   - Includes every task block from start through the LAST SUCCESSFUL task.
   - Ends with `cat("Part 1 complete\n")`.
4. Write `Outputs/analysis_corrected_part2.R`:
   - Same header (libraries, source, load data, AddMetaData merge, mkdir).
   - Includes every task block from the CRASHING task onward.
   - Adds an `rm(list = setdiff(ls(), "seurat_obj")); gc()` line right after
     the load+merge block to start with a clean slate.
   - Ends with `cat("Part 2 complete\n")`.
5. The RAM-blow-up task itself often needs an extra fix — see the patterns
   in `ram-split-rules.md`. The most common ones:
   - A DE result that was never `rm()`'d before the crashing task → add
     `rm(result_X); gc()` before the crash.
   - A loop that builds a big object → switch to "summary only" pattern
     (collect rho/p-value into a data.frame, not the full result objects).
   - `subset()` called repeatedly without rm of the previous subset → add
     `rm(sub_obj); gc()` inside the loop.
6. Run part1 first, then part2. Both must finish for the run to count as
   successful.

**Do NOT split a preprocess.R script.** Preprocessing must complete in one
shot because `Working/processed_meta.csv` is the atomic handoff. If
preprocess.R crashes on RAM, look for AddModuleScore on a too-large gene set or
an unintended full-matrix load — patch the offending step rather than splitting.

---

## Category 4 — Other (catch-all)

If the error doesn't fit Categories 1–3, decide whether the fix is local:

**Patchable locally (DO patch):**
- Wrong column name (`Phase` vs `phase`, `sample` vs `Sample`, `MTIL_score` vs
  `MTIL_score1`) — fix by reading `Working/processed_meta.csv` to see the real
  column names, then substitute.
- Gene symbol typo (`MYC1` should be `MYC`) — confirm against
  `rownames(seurat_obj)` and patch.
- `subset(seurat_obj, condition = "X")` (single `=`) — change to `==`.
- Missing `dir.create()` for an output directory.
- Forgetting to `null`-check a tryCatch result before `ggsave()`.

**Not patchable locally (DO NOT patch — record and stop):**
- Plan2 asks for an analysis the data can't support (e.g. only 2 cells in the
  target group → DE fails).
- A function in `function_v2.R` or `preprocess.R` itself has a bug (changing
  the function file is out of scope for this agent — flag it in
  `correction_record.txt` and stop).
- The data file `Inputs/data.rds` is missing or unreadable.
- A required R package isn't installed.

For unpatchable issues, write a clear diagnosis to `correction_record.txt`
with the file/line of the original error, what should change to fix it, and
who should change it (the user / the code agent / the dataset owner).

---

## correction_record.txt format

One block per correction attempt, in order. Use this template:

```
=== Correction #N ===
Script:    Outputs/analysis.R   (or preprocess.R)
Trigger:   Working/analysis.log line 47
Category:  1 / 2 / 3 / 4
Error:     [exact error message, one line]

Diagnosis: [one paragraph: what the agent thinks went wrong and why]

Fix:       [what the agent changed; for patches, list every line]
           - line 13: `subcategory = "CP:KEGG"` → `subcategory = "CP:KEGG_LEGACY"`

Result:    [PASS / FAIL after re-run; for FAIL, the new error]
```

If no corrections were needed (clean run on first try), write a single line:
```
No corrections required. Both scripts ran cleanly.
```
