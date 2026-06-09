## Phase 8 — Resume an in-progress MVP

Reached only when `resume` was in `$ARGUMENTS` (Phase 0 routes here). Never start from scratch in this branch — if no MVP is found, halt and tell the user to run `/create-mvp` (without `resume`).

### 8a. Discover via registry

Read `$MVP_HOME/registry.json` (`MVP_HOME` is defined in the header). If it doesn't exist or has zero entries, **self-heal before giving up** — the registry is a rebuildable cache; the orchestrators are the source of truth. Scan `$MVP_HOME/plans/*/00-orchestrator.md`:

- **One or more found** → ask:
  > Registry is empty but I found <N> plan folder(s) on disk: <slugs>. Rebuild the registry from them? (yes / no)

  On **yes** → for each, run the **Register an MVP from its orchestrator** routine (below), then continue with the rebuilt registry. On **no** → show the "no in-progress MVP" message below and stop.
- **None found** →

  > No in-progress MVP found. You must complete requirements first — run `/create-mvp` (without `resume`) and stay engaged at least through Phase 4, when the orchestrator file is written. Until then there's nothing to resume. (To bring in a folder shared from elsewhere, use `/create-mvp import <path>`.)

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

Set `MVP_PROJECT="$MVP_HOME/plans/<slug>"`. Read `MVP_PROJECT/00-orchestrator.md`. Parse:

- Slug, project path (the **Project path** field — this is `PROJECT_ROOT`)
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

- No phase plan files in `MVP_PROJECT` beyond the orchestrator → jump to Phase 4 (build plan files).
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

---

## Register an MVP from its orchestrator (shared routine)

Reconstructs a registry entry from a plan folder's orchestrator. The orchestrator is the source of truth; the registry is a derived index. Used by import (Phase 9) and by 8a's registry self-heal.

Given a slug folder at `$MVP_HOME/plans/<slug>/`:

1. Read `$MVP_HOME/plans/<slug>/00-orchestrator.md`. If it's missing, skip with a note: `<slug> has no orchestrator — not a valid plan folder`.
2. Parse: **Project path** → `project_path`, **Summary** → `summary`, **Longevity** → `longevity`, **Stop point** → `stop_point`.
3. Timestamps: `updated_at = now` (`date -u +%Y-%m-%dT%H:%M:%SZ`). Preserve `created_at` if the entry already exists; otherwise set it equal to `updated_at`.
4. Write the entry under `entries.<slug>` in `$MVP_HOME/registry.json` — same shape and method as Phase 4f (jq, else read-modify-write via the Write tool).

---

## Phase 9 — Import a shared MVP

Reached only when `import <path>` was in `$ARGUMENTS` (Phase 0 routes here). Brings a plan folder produced on another machine into this machine's `$MVP_HOME` and registers it so it can be resumed. **Never executes build phases** — it ends by pointing the user at `/create-mvp resume`.

### 9a. Resolve the source

`<path>` is the token after `import`. It may be:

- a `.zip` → extract into a temp directory (`unzip -q <path> -d <tmp>`).
- a directory → use in place.

Locate the plan-folder root: the directory that directly contains `00-orchestrator.md` (if the archive wraps everything in a single top-level `<slug>/`, descend into it). If no `00-orchestrator.md` is found anywhere under the source:

> No orchestrator found under `<path>` — that's not a `/create-mvp` plan folder.

Stop.

### 9b. Determine the slug

Read the orchestrator's **Slug** field; sanitize (lowercase, non-`[a-z0-9-]`→`-`, collapse repeats, trim). Fall back to the source folder's basename if the field is missing or empty after sanitizing.

### 9c. Collision check

If `$MVP_HOME/plans/<slug>/` already exists:

> A plan with slug `<slug>` already exists here. Options:
> 1. Overwrite (replace the existing folder)
> 2. Import under a new slug
> 3. Cancel

Honor the choice. On overwrite, remove the existing folder first.

### 9d. Place the folder

```sh
mkdir -p "$MVP_HOME/plans"
cp -R "<resolved-source-root>/." "$MVP_HOME/plans/<slug>/"
```

Remove the temp extraction directory if one was used.

### 9e. Reconcile PROJECT_ROOT

The orchestrator's **Project path** (`PROJECT_ROOT`) points at wherever the repo lived on the *origin* machine. Show it and offer to fix it:

> This MVP was built against `PROJECT_ROOT = <path from orchestrator>`. Where does the repo live on *this* machine?
> - Press enter to keep that path.
> - Or paste the local path.

If the user supplies a new path, rewrite the single **Project path** line in `$MVP_HOME/plans/<slug>/00-orchestrator.md`. Whether kept or changed, if the final path doesn't exist on disk, warn (don't block):

> Note: `<path>` doesn't exist yet — clone the repo there or fix the Project path before executing.

### 9f. Register

Run the **Register an MVP from its orchestrator** routine (above) for `<slug>`.

### 9g. Done

> [imported] `<slug>` — placed at `$MVP_HOME/plans/<slug>/` and registered. Run `/create-mvp resume` to continue.

Stop. Do not auto-execute.

---

## Phase 10 — Export a shared MVP

Reached only when `export` was in `$ARGUMENTS` (Phase 0 routes here). Packages a plan folder into a portable archive for sharing — and **first verifies it's portable**: the only hardcoded absolute path allowed anywhere in the folder is the orchestrator's single **Project path** line; everything else must reference `MVP_PROJECT` / `PROJECT_ROOT`. The counterpart to import (Phase 9). Never executes build phases.

### 10a. Select the MVP

Pick the MVP using the same rules as 8a–8c: a `slug=<x>` arg, else CWD auto-pick against `project_path`, else the picker. Set `MVP_PROJECT="$MVP_HOME/plans/<slug>"`.

### 10b. Verify the symbols (portability lint)

Read the orchestrator. Let `P` = its **Project path** value (the `PROJECT_ROOT` definition) and `D` = the resolved `MVP_PROJECT` path. Scan every file under `MVP_PROJECT/` — orchestrator, phase plans, `adrs/`, `memory/` — for hardcoded paths that should be placeholders:

- Any occurrence of the literal `P` **except** the one on the orchestrator's Project path line (that one is allowed — it defines `PROJECT_ROOT`).
- Any occurrence of the literal `D`.
- Other absolute-path markers: `$HOME`, `~/`, `/Users/`, `/home/`, and the resolved `MVP_HOME`.

Report each hit as `file:line` with the offending text. If hits exist, offer to fix:

> Found <N> hardcoded path(s) that should be placeholders. Rewrite them? (`PROJECT_ROOT` for the repo path, `MVP_PROJECT` for the plan dir) — yes / show / cancel

- **yes** → replace literal `P` → `PROJECT_ROOT` (everywhere but the Project path line) and literal `D` → `MVP_PROJECT`, then re-scan.
- A leak that is neither `P` nor `D` (some unrelated absolute path) can't be auto-rewritten — list it and require the user to fix it manually or explicitly confirm exporting anyway.

A clean scan (or an explicit confirm-anyway) is required before packaging.

**`verify-only`:** if that flag is present, stop here — print a pass/fail summary (clean, or the list of leaks) and do **not** package.

### 10c. Package

```sh
out_dir="<out= arg, default: current directory>"
( cd "$MVP_HOME/plans" && zip -qr "$out_dir/<slug>.zip" "<slug>" )
```

Zipping from `$MVP_HOME/plans` keeps `<slug>/00-orchestrator.md` as the archive's top-level wrapper — exactly what import (9a) expects.

### 10d. Done

> [exported] `<slug>` → `<out_dir>/<slug>.zip` (portability verified). Share it; the recipient runs `/create-mvp import <slug>.zip`.

Stop.
