## Vocabulary

- **phase** — the atomic unit of execution. Phases 0–8 are the canonical phases of `/create-mvp` itself; user MVPs also break work into numbered phases (`01-scaffold.md`, `02-data.md`, etc.). A phase is never split or merged at runtime.
- **stage** — an ordered group of phases. A stage runs as **serial** (its phases execute in order, one at a time) or **parallel** (its phases launch concurrently). Stages always run sequentially relative to one another.
- "Next phase" is ambiguous when the upcoming stage is parallel — see Phase 0 / Phase 6 for the verification rule.

## Principles

- Checkpoints > speed. Update the orchestrator religiously.
- Parallel when the graph allows; serial when it doesn't.
- Every phase has an acceptance gate. No gate, no `done`.
- Subagents are cheap — use them for both building and reviewing.
- Auto-loops have ceilings. The goal is fast *and* cheap — not infinite retries.
- Resume always shows status first; never execute without confirmation.
- Respect the dependency graph. `phase=N` is a conscious override, not a default.
- Orchestrator is the source of truth. Trust its statuses over assumptions.
- Stop points matter. If the user said "stop after 3", stop after 3 — don't overshoot because "we're so close".
- Plans live in `$MVP_HOME/plans/<slug>/` (default `~/.local/share/create-mvp/plans/<slug>/`), NOT in the project. Plans are process, not artifact. ADRs (when written) DO go in the project — they're decisions worth committing.
