---
description: Interactive MVP workflow — requirements → plan → build, with resume support
argument-hint: [resume] [import <path>] [export [verify-only]] [slug=<x>] [phase=N] [status] [stop-after=plan|N] [project one-liner]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite
generated-by: ai-skill-create-mvp install.sh
---

# /create-mvp

You are executing `/create-mvp`. Four modes — **create** (default), **resume** (when `resume` is in `$ARGUMENTS`), **import** (when `import <path>` is in `$ARGUMENTS`), and **export** (when `export` is in `$ARGUMENTS`). Move through the phases in order. Announce each phase on entry (e.g. `── Phase 2: Gap analysis ──`). Do not skip ahead. Do not write implementation code before Phase 6.

Plans live centrally under `MVP_HOME`, where:

```sh
MVP_HOME="${CREATE_MVP_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/create-mvp}"
```

On macOS/Linux this resolves to `~/.local/share/create-mvp/` by default. Each MVP gets `MVP_HOME/plans/<slug>/`, and the registry lives at `MVP_HOME/registry.json`. Plans are NOT committed to the project — they're process artifacts. Use `MVP_HOME` consistently in any path you read, write, or print to the user.

## Path placeholders

Two placeholders keep plans free of hardcoded absolute paths. Use them in everything you author (orchestrator, phase plans, ADRs, memory); resolve them to real paths only at execution time. Never write a hardcoded absolute path into a plan.

- **`MVP_PROJECT`** — this MVP's slug folder (canonical `MVP_HOME/plans/<slug>/`). Plans reference it symbolically, so no absolute plan path is baked in. Holds the orchestrator, phase plans, `MVP_PROJECT/adrs/`, and `MVP_PROJECT/memory/`. The user may refer to it by name.
- **`PROJECT_ROOT`** — the code repository this MVP builds. It is the **only** absolute path anywhere in the slug folder, written once in the orchestrator's **Project path** field. That field is the single line a developer edits after cloning the repo to a different path. Everything else references `PROJECT_ROOT/…`.

Seed context from the user (may be empty): $ARGUMENTS
