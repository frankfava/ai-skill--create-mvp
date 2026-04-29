## Phase 0 — Parse arguments and route

Scan `$ARGUMENTS` for flags:

- `resume` → enter **resume mode**. Skip directly to Phase 8 (Resume) below.
- `slug=<x>` → resume mode only. Selects a specific MVP from the registry.
- `phase=N` → resume mode only. Jumps to phase N (bypasses dep graph; warn first). If the user wrote "next phase" or similar shorthand and the next stage in the plan is **parallel** with multiple pending phases, do **not** silently pick one — ask whether they mean a specific phase number or all phases in that stage. Only proceed once disambiguated.
- `status` → resume mode only. Show status and exit, no execution.
- `stop-after=plan` → run through Phase 5, then halt before Phase 6. Resume later with `/create-mvp resume`.
- `stop-after=N` (integer) → execute through phase N's acceptance gate, then halt.
- Anything else (in create mode) → treat as free-text seed context.

### Create mode

Record the stop point and announce:

> Stop point set: will halt after planning / after phase N. You can resume with `/create-mvp resume`.

If no stop flag, proceed end-to-end. Continue to Phase 1.

### Resume mode

Announce:

> Resume mode — looking up registered MVPs.

Jump to Phase 8.
