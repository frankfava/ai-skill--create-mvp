## Phase 8 — Resume an in-progress MVP

Reached only when `resume` was in `$ARGUMENTS` (Phase 0 routes here). Never start from scratch in this branch — if no MVP is found, halt and tell the user to run `/create-mvp` (without `resume`).

### 8a. Discover via registry

Read `$MVP_HOME/registry.json` (`MVP_HOME` is defined in the header). If it doesn't exist or has zero entries:

> No in-progress MVP found. You must complete requirements first — run `/create-mvp` (without `resume`) and stay engaged at least through Phase 4, when the orchestrator file is written. Until then there's nothing to resume.

Stop.

For each entry, verify `$MVP_HOME/plans/<slug>/00-orchestrator.md` exists. Auto-prune entries whose orchestrator is missing — surface a one-line note for each pruned, and rewrite the registry.

### 8b. Selection

Decision order:

1. **`slug=<x>` arg** → look up `entries.<x>`. If missing, error and list available slugs. Otherwise select.
2. **CWD auto-pick** → run `pwd`. If exactly one entry has `project_path` matching CWD → auto-select. Announce:
   > Resuming `<slug>` (matched current directory) — <summary>.
3. **Picker** → if multiple entries match CWD (corrupted) or zero match: show 8c picker.

### 8c. Picker

Show a compact table. Read each orchestrator just enough to extract progress:

```
# Slug                 Project                     Summary               Progress    Updated
1 todo-app-x7f3a       /Users/.../todo-app         Todo app with teams   3/6 done    2d ago
2 metrics-tool-b1e2    /Users/.../metrics          Internal metrics      1/8 done    1h ago
```

Ask:

> Which MVP? (number, or `all` for full phase tables)

Wait for selection. If `all`, expand each with its phase table, then re-ask.

### 8d. Load selected MVP

Set `PLAN_DIR="$MVP_HOME/plans/<slug>"`. Read `<PLAN_DIR>/00-orchestrator.md`. Parse:

- Slug, project path
- Summary, longevity
- Requirements
- Phase table (status, retries, size, deps)
- Dependency graph
- Stages (and per-stage mode: serial / parallel)
- Stop point
- Model & effort plan (if present — means planning is complete)

### Sanity checks

- Any phase `in-progress` → warn: *"Phase N was left in-progress. Likely a prior interrupted run. Mark `pending` and redo, or `done` if the work actually completed?"* — require user answer before proceeding.
- Any phase `blocked` → surface block reason and require user decision: retry, revise plan, or skip.
- If Model & effort plan section is empty → planning never finished. Route to **8f. Planning resume** below.

### 8e. Show status and propose next action

Print a concise status block:

```
MVP: <summary>
Slug: <slug>
Project: <project_path>
Longevity: throwaway | outlive
Progress: X/Y phases done
Blocked: <list or none>
Next pending phase(s): <numbers from the first group with all deps met>
Requested stop point: <from args, or none>
```

If `status` arg was passed: stop here. Do not execute.

Otherwise propose the plan:

> I'll execute phases <list> next<, stopping after phase N | before Phase 6 if stop-after=plan>. Proceed? (yes / adjust)

Wait for confirmation.

### 8f. Planning resume (only if planning was incomplete)

If the orchestrator exists but has no Model & effort plan section, the previous run stopped during planning. Resume inside the create flow at the right point:

- No phase plan files in `<PLAN_DIR>` beyond the orchestrator → jump to Phase 4 (build plan files).
- Phase plans exist but no Model & effort section → jump to Phase 5.

Honor `stop-after=plan` here too.

When planning finishes, continue to 8g.

### 8g. Execute remaining phases

Follow Phase 6 exactly, with these resume-specific rules:

#### 8g-i. Starting point
Begin with the first stage whose every phase is `pending` **and** whose dependencies are all `done`. Skip phases already `done`. If that stage is parallel and the user said "next phase" without naming one, confirm scope (single phase vs. whole stage) before launching.

#### 8g-ii. Stop-point honor
- `stop-after=plan` → only meaningful if 8f ran. Halt at the end of Phase 5 — same halt point Phase 5 honors for `stop-after=plan`.
- `stop-after=N` → when phase N is marked `done`, halt. Print:
  > Halted after phase N as requested. Run `/create-mvp resume` again to continue.
- No `stop-after` → run to completion.

#### 8g-iii. Phase jump (`phase=N`)
If set and user confirmed the warning in Phase 0:
- Verify dependencies of phase N are all `done`. If not, refuse and explain which deps are missing.
- Execute only phase N. Do not auto-advance.
- Update orchestrator. Update registry `updated_at`. Halt.

#### 8g-iv. Failure protocol
Same as Phase 7 — classified (TEST_OR_LINT / ACCEPTANCE_MISS / REQUIREMENTS_GAP), bounded (max 2 auto-retries per phase), with advisor subagent review.

### 8h. Close out

When the run halts (either at stop point or because all phases are `done`):

1. Update orchestrator: statuses, retries, any new blocks.
2. Update registry: `updated_at`.
3. Commit project code: `git commit -m "resume: <summary of what ran>"`.
4. Print a compact summary:
   ```
   Ran this session: phases <list>
   Now done: X/Y
   Still pending: <list>
   Blocked: <list or none>
   Next resume command: /create-mvp resume <suggested args>
   ```

If all phases are `done`, also run the final pass from Phase 6, step 7: full test suite, README update, one-page summary.
