## Vocabulary

- **phase** — the atomic unit of execution. Phases 0–10 are the canonical phases of `/create-mvp` itself; user MVPs also break work into numbered phases (`01-scaffold.md`, `02-data.md`, etc.). A phase is never split or merged at runtime.
- **stage** — an ordered group of phases. A stage runs as **serial** (its phases execute in order, one at a time) or **parallel** (its phases launch concurrently). Stages always run sequentially relative to one another.
- "Next phase" is ambiguous when the upcoming stage is parallel — see Phase 0 / Phase 6 for the verification rule.
- **`MVP_PROJECT`** — this MVP's slug folder (canonical `MVP_HOME/plans/<slug>/`). Holds the orchestrator, phase plans, `adrs/`, `memory/`. Use the token in plans; never its expanded path.
- **`PROJECT_ROOT`** — the code repository. The only absolute path in the slug folder, defined once in the orchestrator's **Project path** field. Use the token everywhere else.

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
- Plans live in `$MVP_HOME/plans/<slug>/` (default `~/.local/share/create-mvp/plans/<slug>/`), NOT in the project. Plans are process, not artifact.
- Plans carry no hardcoded absolute paths. They reference `MVP_PROJECT/…` and `PROJECT_ROOT/…`. The one absolute path is the orchestrator's **Project path**; that line is all a dev edits after cloning the repo to a different path.
- ADRs (when written) default to `MVP_PROJECT/adrs/` — for an MVP they're agent context, not yet a product commitment. Commit them into the repo's `adrs/` only if the user opts in. Throwaways skip ADRs.
- `MVP_PROJECT/memory/` carries code-style and workflow conventions in the agent's native memory format, relocated so it travels with the plan. Write conventions there so every subagent inherits them.
