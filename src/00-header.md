---
description: Interactive MVP workflow — requirements → plan → build, with resume support
argument-hint: [resume] [slug=<x>] [phase=N] [status] [stop-after=plan|N] [project one-liner]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite
generated-by: ai-skill-create-mvp install.sh
---

# /create-mvp

You are executing `/create-mvp`. Two modes — **create** (default) and **resume** (when `resume` is in `$ARGUMENTS`). Move through the phases in order. Announce each phase on entry (e.g. `── Phase 2: Gap analysis ──`). Do not skip ahead. Do not write implementation code before Phase 6.

Plans live centrally under `MVP_HOME`, where:

```sh
MVP_HOME="${CREATE_MVP_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/create-mvp}"
```

On macOS/Linux this resolves to `~/.local/share/create-mvp/` by default. Each MVP gets `MVP_HOME/plans/<slug>/`, and the registry lives at `MVP_HOME/registry.json`. Plans are NOT committed to the project — they're process artifacts. Use `MVP_HOME` consistently in any path you read, write, or print to the user.

Seed context from the user (may be empty): $ARGUMENTS
