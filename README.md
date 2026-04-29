# /create-mvp — MVP workflow for Claude Code

A single slash command that turns a vague idea into a checkpointed, parallel-executed MVP — with real stopping points, classified failure handling, optional architecture decision records, and resume support.

```
/create-mvp                    Interactive: requirements → plan → build
/create-mvp resume             Resume an in-progress MVP
```

---

## Contents

| Path | Purpose |
|------|---------|
| `src/*.md` | Source partials, concatenated at install time into one command file |
| `install.sh` | POSIX installer (macOS, Linux, WSL, Git Bash) |

The runtime command file lives at `~/.claude/commands/create-mvp.md` after install.

---

## Install

```sh
sh install.sh              # installs to ~/.claude/commands/  (user-level)
sh install.sh --project    # installs to ./.claude/commands/  (current repo)
sh install.sh --dest PATH  # custom command location
sh install.sh --force      # skip overwrite prompts; remove deprecated resume-mvp.md
```

The installer also bootstraps `~/.claude/meta/create-mvp/plans/` and `~/.claude/meta/create-mvp/registry.json` (the central plan storage). Plans always go under user `~/.claude/meta/`, regardless of where the command file is installed.

---

## Usage

### `/create-mvp [project one-liner] [stop-after=plan|N]`

Runs a 6-phase workflow:

1. **Requirements** — open-ended questions, one at a time. Optionally seed from a PRD/RFC/plan path. Keeps asking *"what else?"* until you say **done**.
2. **Gap analysis** — probes for stack, testing, auth, deployment, security, observability, etc. Asks whether the project is a throwaway or meant to outlive the MVP. If outlive: writes 3–5 ADRs (`adr/NNNN-*.md`) for the major architectural decisions. ADRs go in the project repo.
3. **Plan sketch** — drafts the phase breakdown in chat, with t-shirt sizing (S/M/L/XL), dependency graph, and parallel groups. Iterates until you confirm.
4. **Plan files** — picks a slug (default `<basename>-<6char>`), writes `00-orchestrator.md` and per-phase plan files to `~/.claude/meta/create-mvp/plans/<slug>/`. Registers the MVP. Two-pass: stubs first, then deep fill.
5. **Build prep** — proposes permission wildcards, model mapping (Haiku/Sonnet/Opus driven by size), advisor subagent pattern, execution strategy. Checks if the project is a git repo and offers to initialise. Waits for your **go**.
6. **Execute** — runs phases in parallel where the graph allows. An Opus advisor subagent reviews each phase against its acceptance criteria before marking `done`.

### `/create-mvp resume [slug=<x>] [phase=N] [status] [stop-after=plan|N]`

- Reads `~/.claude/meta/create-mvp/registry.json` for in-progress MVPs.
- If exactly one entry's `project_path` matches your CWD, auto-picks it.
- Otherwise shows a picker.
- Prints current status (done/pending/blocked, retries).
- Detects interrupted runs (anything left `in-progress`) and asks before mutating state.
- Can resume *planning* if the previous run halted before Phase 5 finished.
- `status` shows state and exits.
- `stop-after=N` halts after phase N. `phase=N` jumps to a specific phase (with a dependency warning).
- `slug=<x>` selects a specific MVP from the registry.

---

## Design decisions

A few choices that matter:

### Plans live centrally, not in the project
Plans are process artifacts, not project artifacts. They live at `~/.claude/meta/create-mvp/plans/<slug>/` and don't pollute the project repo. ADRs (when written) DO go in the project — those are decisions worth committing.

### One command, two modes
`/create-mvp` and `/create-mvp resume` are the same command. The Phase 0 router branches on the `resume` flag. One file to maintain, one runtime prompt, one cache key.

### Source is split into partials, runtime is one file
`src/00-header.md` through `src/09-principles.md` are authored independently and concatenated by `install.sh` into a single `create-mvp.md`. Modular for humans, monolithic for the model.

### Optional doc seed in Phase 1
If you have an existing PRD/RFC/plan, paste the path. The command reads it, extracts requirements, and asks *"is this complete?"* — only loops on what's missing.

### ADRs are conditional
The longevity branching question in Phase 2 decides whether ADRs get written. Throwaway prototypes skip them entirely.

### T-shirt sizing, not token estimates
Pre-code token estimates are false precision. S/M/L/XL is coarse enough to be honest and drives real decisions: model choice per phase, and iteration ceilings (S≈10 updates, XL≈100) that surface runaway loops.

### Classified failure loop, bounded
When a phase misses acceptance, failures are classified before retrying:

| Class | Meaning | Action |
|-------|---------|--------|
| `TEST_OR_LINT` | Automated check failed (pytest, eslint, tsc) | 1 auto-retry, same plan |
| `ACCEPTANCE_MISS` | Runs, tests pass, but misses acceptance criteria | 1 auto-replan of the phase, then escalate |
| `REQUIREMENTS_GAP` | Requirements themselves are wrong or incomplete | Always escalate — no auto-loop |

Hard ceiling: **max 2 auto-retries per phase total.** Protects the "cheap" goal from silent burn.

### The orchestrator is the source of truth
Every phase completion updates `<plan_dir>/00-orchestrator.md`: status, retry count, any blocks. Resume mode trusts this file over anything else.

### Advisor subagents at every gate
An Opus subagent reviews each phase's deliverables against its acceptance criteria before it's marked `done`. Cheap insurance against silent drift.

---

## Examples

```sh
/create-mvp
/create-mvp "internal tool for tracking team OKRs"
/create-mvp stop-after=plan                        # just plan, don't build
/create-mvp "todo app with teams" stop-after=3     # halt after phase 3

/create-mvp resume                                 # auto-pick from CWD or show picker
/create-mvp resume status                          # show state, don't run
/create-mvp resume slug=todo-app-x7f3a             # load a specific MVP
/create-mvp resume stop-after=plan                 # finish planning, then stop
/create-mvp resume stop-after=5                    # execute up through phase 5
/create-mvp resume phase=4                         # run phase 4 only (with warning)
```

---

## On-disk layout after install

```
~/.claude/
├── commands/
│   └── create-mvp.md                       # single command file (concatenated from src/*)
└── meta/
    └── create-mvp/
        ├── registry.json                   # slug → { project_path, summary, ... }
        └── plans/
            └── <slug>/
                ├── 00-orchestrator.md      # status, graph, parallel groups
                ├── 01-scaffold.md
                ├── 02-data.md
                └── ...
```

A target project itself stays clean:

```
your-project/
├── adr/                                    # only if "outlive" answer in Phase 2
│   ├── 0001-stack-choice.md
│   └── ...
└── <your actual code>
```

---

## Requirements

- [Claude Code](https://claude.ai/code) installed.
- A POSIX shell for the installer (built-in on macOS, Linux, WSL, Git Bash).
- `shasum` (used to compute the slug hash). Present on macOS, Linux, WSL, Git Bash.

---

## Migration from the old `/create-mvp` + `/resume-mvp` pair

If you previously installed `create-mvp.md` + `resume-mvp.md` from this repo:

- Re-run `sh install.sh`. The installer detects and offers to remove the deprecated `resume-mvp.md`.
- Old plans in `<project>/plans/` won't be auto-migrated. Either copy them manually into `~/.claude/meta/create-mvp/plans/<slug>/`, or just start fresh with `/create-mvp`.

---

## Authors

Co-authored by **[\frankfava](https://github.com/frankfava)** and **Claude** (Anthropic).
