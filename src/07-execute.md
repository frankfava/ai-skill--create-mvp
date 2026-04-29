## Phase 6 — Execute

1. Orchestrator: phase 1 → `in-progress`.
2. Execute phase 1 inline (scaffold rarely parallelizes).
3. Run acceptance criteria → on pass: commit, mark `done`. On fail: **Failure protocol** (Phase 7).
4. For each subsequent stage (in order):
   - **Serial stage** → execute its phases one at a time, in declared order, applying steps 2–3 to each.
   - **Parallel stage** → if the user said "next phase" without naming one, confirm scope first (single phase number vs. all phases in this stage). Then launch one **Task** subagent per in-scope phase (model per 5b), input = phase plan file path (`<PLAN_DIR>/NN-...md`). Wait for all.
   - Launch **advisor subagent** (Opus) per completed phase to verify acceptance criteria.
   - Update orchestrator. Update registry `updated_at`. Commit code changes in the project repo.
5. Honor stop point: if `stop-after=N` and phase N just finished, halt and announce resume instructions.
6. Continue until every phase is `done`.
7. Final pass: full test suite, README update, one-page summary of what was built + deferred follow-ups.

---

## Phase 7 — Failure protocol (classified + bounded)

When a phase misses acceptance, first **classify the failure**, then apply the matching loop. Increment `Retries` in the orchestrator on every retry. Append a one-line note under the phase describing the failure + class.

### Class 1 — TEST_OR_LINT
Automated check failed (pytest, eslint, tsc, etc.). Mechanical.
- **Action:** 1 auto-retry, same plan. Dispatch the same subagent with the failing output as input.
- **If still failing:** escalate to user.

### Class 2 — ACCEPTANCE_MISS (logic)
Code runs, tests pass, but acceptance criteria not met. Logic/design wrong.
- **Action:** 1 auto-replan of *this phase only* (rewrite its task breakdown, keep its objective), then re-execute. Advisor subagent reviews the replan before execution.
- **If still failing:** escalate to user.

### Class 3 — REQUIREMENTS_GAP
Execution revealed the requirements themselves are wrong, contradictory, or incomplete.
- **Action:** always escalate. No auto-loop. Pause, surface the gap, offer: update Phase 1 requirements → regenerate affected phase files → resume.

### Hard ceilings (protects the "cheap" goal)
- Max 2 total auto-retries per phase across all classes. After that, escalate regardless of class.
- If a phase hits its iteration ceiling (from the phase plan), treat as implicit failure and classify.

### If requirements change mid-build

Pause. Classify as REQUIREMENTS_GAP. Identify affected phase files in `<PLAN_DIR>`. Update them. Re-confirm with the user. Resume.
