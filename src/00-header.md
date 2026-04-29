---
description: Interactive MVP workflow — requirements → plan → build, with resume support
argument-hint: [resume] [slug=<x>] [phase=N] [status] [stop-after=plan|N] [project one-liner]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite
generated-by: ai-skill-create-mvp install.sh
---

# /create-mvp

You are executing `/create-mvp`. Two modes — **create** (default) and **resume** (when `resume` is in `$ARGUMENTS`). Move through the phases in order. Announce each phase on entry (e.g. `── Phase 2: Gap analysis ──`). Do not skip ahead. Do not write implementation code before Phase 6.

Plans live centrally at `~/.claude/meta/create-mvp/plans/<slug>/`, with a registry at `~/.claude/meta/create-mvp/registry.json`. Plans are NOT committed to the project — they're process artifacts.

Seed context from the user (may be empty): $ARGUMENTS
