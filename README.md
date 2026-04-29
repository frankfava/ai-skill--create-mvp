# /create-mvp — MVP workflow for Claude Code

A single slash command that turns a vague idea into a checkpointed, parallel-executed MVP — with real stopping points, classified failure handling, optional architecture decision records, and resume support.

```
/create-mvp                    Interactive: requirements → plan → build
/create-mvp resume             Resume an in-progress MVP
```

**The good stuff:**
- Phases that can be developed in parallel are executed concurrently — no serial-only build wall.
- Planning assigns a t-shirt size (S/M/L/XL) per phase and maps it to a suitable model + effort, optimising token usage.
- Advisor subagents review each phase's deliverables against its acceptance criteria — only on phases where complexity warrants it (only on L/XL).
- Proposes a tailored permission wildcard set for the chosen stack, installing it at the project level, so the build doesn't stall on per-tool approval prompts.

---

## Contents

| Path | Purpose |
|------|---------|
| `src/*.md` | Source partials, concatenated at install time into one command file |
| `install.sh` | POSIX installer (macOS, Linux, WSL, Git Bash) |

The runtime command file lives at `~/.claude/commands/create-mvp.md` after install.

---

## Install

Download the repo and run the installer.

eg. `cd ~/Downloads/ai-skill--create-mvp && sh install.sh`

```sh
sh install.sh              # installs to ~/.claude/commands/  (user-level)
sh install.sh --project    # installs to ./.claude/commands/  (current repo)
sh install.sh --dest PATH  # custom command location
sh install.sh --force      # skip overwrite prompts; remove deprecated resume-mvp.md
```

The installer also bootstraps the central plan storage at `MVP_HOME/plans/` and `MVP_HOME/registry.json`. `MVP_HOME` resolves in this order:

1. `$CREATE_MVP_HOME` if set.
2. Otherwise `$XDG_DATA_HOME/create-mvp` if `$XDG_DATA_HOME` is set.
3. Otherwise the XDG default — on macOS and Linux this is `~/.local/share/create-mvp/`.

Plans always go under the resolved `MVP_HOME`, regardless of where the command file is installed.

> **Migrating from an older install?** Plans previously lived under `~/.claude/meta/create-mvp/`. The first time you run the new `install.sh`, it copies plans + registry from there to the new XDG location and prints a `[migrate]` notice. Your old directory is left in place — delete it manually once you're confident the move worked.

---

## Usage

### `/create-mvp [project one-liner] [stop-after=plan|N]`

Runs a 6-phase workflow:

1. **Requirements** — open-ended questions, one at a time. Optionally seed from a PRD/RFC/plan path. Keeps asking *"what else?"* until you say **done**.
2. **Gap analysis** — probes for stack, testing, auth, deployment, security, observability, etc. Asks whether the project is a throwaway or meant to outlive the MVP. If outlive: writes 3–5 ADRs (`adr/NNNN-*.md`) for the major architectural decisions. ADRs go in the project repo.
3. **Plan sketch** — drafts the phase breakdown in chat, with t-shirt sizing (S/M/L/XL), dependency graph, and parallel groups. Iterates until you confirm.
4. **Plan files** — picks a slug (default `<basename>-<6char>`), writes `00-orchestrator.md` and per-phase plan files to `$MVP_HOME/plans/<slug>/`. Registers the MVP. Two-pass: stubs first, then deep fill.
5. **Build prep** — proposes permission wildcards, model mapping (Haiku/Sonnet/Opus driven by size), advisor subagent pattern, execution strategy. Checks if the project is a git repo and offers to initialise. Waits for your **go**.
6. **Execute** — runs phases in parallel where the graph allows. An Opus advisor subagent reviews each phase against its acceptance criteria before marking `done`.

### `/create-mvp resume [slug=<x>] [phase=N] [status] [stop-after=plan|N]`

- Reads `$MVP_HOME/registry.json` for in-progress MVPs.
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
Plans are process artifacts, not project artifacts. They live at `$MVP_HOME/plans/<slug>/` (default `~/.local/share/create-mvp/plans/<slug>/` on macOS/Linux) and don't pollute the project repo. ADRs (when written) DO go in the project — those are decisions worth committing.

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
~/.claude/commands/
└── create-mvp.md                           # single command file (concatenated from src/*)

~/.local/share/create-mvp/                  # = $MVP_HOME (XDG default; override via CREATE_MVP_HOME)
├── registry.json                           # slug → { project_path, summary, ... }
└── plans/
    └── <slug>/
        ├── 00-orchestrator.md              # status, graph, stages
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
- Old plans in `<project>/plans/` won't be auto-migrated. Either copy them manually into `$MVP_HOME/plans/<slug>/`, or just start fresh with `/create-mvp`.
- Plans previously stored at `~/.claude/meta/create-mvp/` are auto-copied to the new XDG location on first install (see the migration note in [Install](#install)).

---

## Authors

Co-authored by **[\frankfava](https://github.com/frankfava)** and **Claude** (Anthropic).
