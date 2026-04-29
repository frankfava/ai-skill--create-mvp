---

## Phase 4 — Build plan files

Plans go to `~/.claude/meta/create-mvp/plans/<slug>/` — NOT to the project. They're process artifacts, not project artifacts.

### 4a. Resolve project path and pick a slug

Get the absolute project path: run `pwd`. Call this `PROJECT_PATH`.

Compute a default slug:

```sh
default_slug="$(basename "$PROJECT_PATH" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g; s/^-//; s/-$//')-$(printf '%s' "$PROJECT_PATH" | shasum | cut -c1-6)"
```

Ask the user:

> Pick a slug for this MVP. Used for `~/.claude/meta/create-mvp/plans/<slug>/` and the registry.
> Press enter to use default: **`<default_slug>`**

If the user provides a custom slug:
1. Sanitize: lowercase, replace non-`[a-z0-9-]` with `-`, collapse repeats, trim leading/trailing `-`.
2. If empty after sanitization → fall back to `default_slug`.

If the directory `~/.claude/meta/create-mvp/plans/<slug>/` already exists, ask:

> A plan with slug `<slug>` already exists. Options:
> 1. Overwrite (delete and start fresh)
> 2. Pick another slug
> 3. Resume that one (jump to Phase 8)

Honor the user's choice. Record the final slug. Set `PLAN_DIR=~/.claude/meta/create-mvp/plans/<slug>` (use the literal expanded path going forward).

### 4b. Bootstrap directories

```sh
mkdir -p "$PLAN_DIR"
```

The installer should have created `~/.claude/meta/create-mvp/registry.json`, but defensively:

```sh
mkdir -p ~/.claude/meta/create-mvp
[ -f ~/.claude/meta/create-mvp/registry.json ] || printf '{\n  "version": 1,\n  "entries": {}\n}\n' > ~/.claude/meta/create-mvp/registry.json
```

### 4c. Two-pass approach

1. **Sketch pass** — write every phase file as a 5-line stub (objective + placeholder sections).
2. **Fill pass** — expand each stub into the full plan. Go deep.

### 4d. Orchestrator: `<PLAN_DIR>/00-orchestrator.md`

```markdown
# MVP Orchestrator

## Slug
<slug>

## Project path
<absolute path captured above>

## Summary
<one paragraph from Phase 1>

## Longevity
throwaway | outlive

## Requirements
- [ ] <captured requirement>

## Phases
| # | Phase | File | Size | Status | Retries | Depends on |
|---|-------|------|------|--------|---------|------------|
| 1 | Scaffold | 01-scaffold.md | S | pending | 0 | — |
| 2 | Data layer | 02-data.md | M | pending | 0 | 1 |
| 3 | Auth | 03-auth.md | L | pending | 0 | 1 |
| 4 | Core API | 04-api.md | L | pending | 0 | 2, 3 |

## Dependency graph
```mermaid
graph TD
  1 --> 2
  1 --> 3
  2 --> 4
  3 --> 4
```

## Parallel execution groups
- Group A (after 1): [2, 3]
- Group B (after A): [4]

## Model & effort plan
<filled in Phase 5>

## Stop point
<none | after-plan | after-phase-N>

## Checkpoint protocol
After each phase:
1. Run acceptance criteria.
2. Update Status + Retries in the table (write directly to this file).
3. Commit code changes in the project repo: `git commit -m "phase N: <n> complete"`.
4. Update registry `updated_at`.
5. On failure: classify, follow Failure protocol (Phase 7).
```

Status values: `pending` · `in-progress` · `blocked` · `done`.

Phase file paths are **relative to PLAN_DIR** (not the project).

### 4e. Phase plans: `<PLAN_DIR>/NN-<slug>.md`

```markdown
# Phase N: <n>

- **Size:** S | M | L | XL
- **Depends on:** <phases>
- **Status:** pending

## Objective
<one paragraph, outcome-focused>

## Inputs
<what must exist from prior phases>

## Deliverables
<concrete files/artifacts this phase produces>

## Task breakdown
- [ ] step 1
- [ ] step 2

## Acceptance criteria
<testable conditions; this is the checkpoint gate>

## Test strategy
<what gets tested at this phase, how>

## Risks & unknowns
<anything that could derail>

## Iteration ceiling
If this phase exceeds ~<N> TodoWrite updates or <M> tool calls without converging on acceptance, pause and surface to user. (Scale to size: S≈10, M≈25, L≈50, XL≈100.)
```

### 4f. Register the MVP

Update `~/.claude/meta/create-mvp/registry.json`. Read the file, parse JSON, add or update the entry under `entries.<slug>`:

```json
"<slug>": {
  "project_path": "<absolute project path>",
  "summary": "<one-line summary from Phase 1>",
  "longevity": "<throwaway|outlive>",
  "stop_point": "<none|after-plan|after-phase-N>",
  "created_at": "<ISO 8601 UTC timestamp from `date -u +%Y-%m-%dT%H:%M:%SZ`>",
  "updated_at": "<same as created_at on first write>"
}
```

Use `jq` if available (`jq '.entries["<slug>"] = { ... }' registry.json > tmp && mv tmp registry.json`); otherwise read+modify+write the whole JSON via the Write tool.

Subsequent phase completions only update `updated_at`. Progress is derived live from the orchestrator, so it doesn't need to be cached here.

### 4g. Announce

After all files are written, list them and announce:

> Orchestrator and phase plans written to `<PLAN_DIR>` — this MVP is now resumable via `/create-mvp resume`.
> Slug: `<slug>`. Registered.

Then ask for approval before Phase 5.
