## Phase 5 — Build preparation

Present all five items, then wait for **"go"**. If `stop-after=plan`, halt at the end of this phase and tell the user how to resume.

### 5a. Permissions to pre-approve

Minimal wildcard set for the chosen stack. Prefer narrow wildcards over `Bash(*)`. Example for Node + Postgres:

```
Bash(npm:*), Bash(npx:*), Bash(node:*), Bash(git:*),
Bash(mkdir:*), Bash(ls:*), Bash(cat:*), Bash(echo:*),
Bash(psql:*), Bash(docker:*),
Read(**), Write(**), Edit(**)
```

Tell the user to add these via `/permissions`.

### 5b. Model mapping (driven by t-shirt size)

| Size | Model | Rationale |
|------|-------|-----------|
| S | Haiku | Mechanical, cheap, fast |
| M | Sonnet | Standard implementation sweet spot |
| L | Sonnet + Opus advisor at gate | Cheap bulk, smart review |
| XL | Opus | Architectural weight justifies cost |

**Advisor pattern:** only on L/XL, spin up a short-lived Opus subagent to review the phase's deliverables against its acceptance criteria before marking `done`. Cheap insurance.

### 5c. Execution strategy

- **Task** tool launches parallel subagents — one per phase in the current parallel stage, each given its phase plan file path (`<PLAN_DIR>/NN-...md`).
- **TodoWrite** inside each phase tracks sub-tasks against the iteration ceiling.
- Batch file reads/edits in single messages.
- Commit after every phase (in the project repo, not the plan dir).
- Run full test suite + lint at the end.

### 5d. Summary table

```
Phase  Size  Model          Stage         Advisor
1      S     Haiku          1 (serial)    no
2      M     Sonnet         2 (parallel)  no
3      L     Sonnet         2 (parallel)  yes (Opus)
4      L     Sonnet         3 (serial)    yes (Opus)
```

### 5e. Git initialisation check

Run `git rev-parse --is-inside-work-tree` in the project directory to check if the project is a git repository.

- **Already a repo** → continue.
- **Not a repo** → tell the user:
  > This project isn't a git repository. The build relies on per-phase commits as checkpoints. Initialise it now? (yes / no)

  - **yes** → run `git init`, then `git add . && git commit -m "init: pre-MVP baseline"`.
  - **no** → warn that per-phase checkpointing will fail. Confirm the user wants to proceed without git, then continue.

If `stop-after=plan`:

> Plan complete. Run `/create-mvp resume` to execute from Phase 6.

Otherwise wait for **"go"**.
