# Batch running

### Single case (sequential)

```bash
cd path/to/case_folder
bash single_case.sh
```

### Single case (step-by-step)

```bash
cd path/to/case_folder

# Phase 1: Summarize (steps 1-5)
claude -p "Launch paper-summary-draft-agent-fv3 agent on Inputs/paper1_text.txt" --dangerously-skip-permissions
claude -p "Launch check-section1-fv1-agent agent on Working/draft_summary1.txt" --dangerously-skip-permissions
claude -p "Launch check-section2-fv1-agent agent on Working/draft_summary2.txt" --dangerously-skip-permissions
claude -p "Launch check-summary-figure-fv1-agent agent on Working/draft_summary3.txt" --dangerously-skip-permissions
claude -p "Launch check-ref-fv1-agent agent on Working/draft_summary4.txt" --dangerously-skip-permissions

# Phase 2: Assemble (step 6)
# Splits into Outputs/summary.txt + Outputs/optional_extra_detail.txt if secondary details exist
if grep -q "^Secondary details:" Working/draft_summary5.txt; then
  sed '/^$/{ N; /\nSecondary details:/{ s/.*//; q; } }' Working/draft_summary5.txt | sed '/^$/{ :a; N; $!ba; s/\n*$//; }' > Outputs/summary.txt
  sed -n '/^Secondary details:/,$p' Working/draft_summary5.txt > Outputs/optional_extra_detail.txt
else
  cp Working/draft_summary5.txt Outputs/summary.txt
fi

# Phase 2.5: Inspect data (only if data_pre.txt not pre-provided)
if [ ! -f Outputs/data_pre.txt ]; then
  claude -p "Launch inspect-data-agent agent on Inputs/data.rds" --dangerously-skip-permissions
fi

# Phase 3: Define (steps 7-9)
claude -p "Launch extract-definitions-v1-agent agent on Outputs/summary.txt" --dangerously-skip-permissions
claude -p "Launch detail-definitions-fv1-agent agent on Outputs/summary.txt" --dangerously-skip-permissions
# Route A (external paper references) — runs only if routing.json has route_a entries
if [ -f Working/routing.json ] && [ "$(jq -r '.route_a | length' Working/routing.json)" -gt 0 ]; then
  claude -p "Launch check-external-ref-v1-agent on $(pwd). Read Working/routing.json for Route A terms." --dangerously-skip-permissions
fi
# Route B (R package classifiers) — runs only if routing.json has route_b entries
if [ -f Working/routing.json ] && [ "$(jq -r '.route_b | length' Working/routing.json)" -gt 0 ]; then
  claude -p "Launch use-extra-function-agent on $(pwd). Read Working/routing.json for Route B terms." --dangerously-skip-permissions
fi

# Phase 4: Gate (step 10)
claude -p "Launch transfer-feasibility-v1-agent agent on Outputs/summary.txt" --dangerously-skip-permissions

# Steps 11-18 only run if feasibility passes
# Phase 5: Annotate (step 11)
claude -p "Launch further-annotate-agent-v2 agent on Inputs/data.rds" --dangerously-skip-permissions

# Phase 6: Plan (steps 12-13)
claude -p "Launch task-plan-agent-step0-v3 agent on Outputs/summary.txt" --dangerously-skip-permissions
claude -p "Launch task-plan-agent-step1-v3 agent on Outputs/summary.txt" --dangerously-skip-permissions

# Phase 7: Execute (steps 14-15)
claude -p "Launch code-agent-v3 agent on Working/plan2.txt" --dangerously-skip-permissions
claude -p "Launch execute-agent agent on Outputs/preprocess.R" --dangerously-skip-permissions

# Phase 8: Report (steps 16-18)
claude -p "Launch report-brainstorm-v5 agent on Working/plan2.txt" --dangerously-skip-permissions
claude -p "Launch final-report-v4 agent on Working/brainstorm_final.txt" --dangerously-skip-permissions
claude -p "Launch report-revision-v2 agent on Outputs/final_report.Rmd" --dangerously-skip-permissions
```

### Batch run (parallel across cases)

Run one stage at a time across all case folders. Adjust concurrency (`>= N`) based on available RAM and API limits.

```bash
# Generic batch runner for any stage
run_stage() {
    local stage_name="$1"
    local cmd="$2"
    local concurrency="${3:-4}"
    echo "=== Starting: $stage_name ==="
    for d in */; do
        [ -d "$d" ] || continue
        (cd "$d" && eval "$cmd") > "${d%/}.log" 2>&1 &
        (($(jobs -r | wc -l) >= concurrency)) && wait -n
    done
    wait
    echo "=== Finished: $stage_name ==="
}

# Example: run summary draft on all cases (6 parallel)
run_stage "summary-draft" \
    'claude -p "Launch paper-summary-draft-agent-fv3 agent on Inputs/paper1_text.txt" --dangerously-skip-permissions' 6

# Example: run a gated stage (only feasible cases missing the output)
for d in */; do
    [ -f "${d}Outputs/feasibility.json" ] || continue
    [ "$(jq -r '.proceed' "${d}Outputs/feasibility.json")" = "true" ] || continue
    [ ! -f "${d}Working/brainstorm_final.txt" ] || continue
    (cd "$d" && claude -p "Launch report-brainstorm-v5 agent on Working/plan2.txt" --dangerously-skip-permissions) > "${d%/}.log" 2>&1 &
    (($(jobs -r | wc -l) >= 4)) && wait -n
done
wait
```

