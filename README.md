# /create-mvp — MVP workflow as a Skill

A single slash command that turns a vague idea into a checkpointed, parallel-executed MVP — with real stopping points, classified failure handling, optional architecture decision records, and resume support.

> Built for Claude Code; also compatible with Cursor and other agents that read Skills/commands from `~/.claude/commands/`.

```
/create-mvp                    Interactive: requirements → plan → build
/create-mvp resume             Resume an in-progress MVP
/create-mvp import <path>      Import a shared MVP folder (.zip or dir) and register it
/create-mvp export             Verify portability and package an MVP for sharing
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
| `install.sh` | POSIX installer for the Claude Code slash command (macOS, Linux, WSL, Git Bash) |
| `export-skill.sh` | POSIX builder that packages the same source as a cloud Claude Skill (`SKILL.md` + `.zip`) |
| `examples/example-orchestrator/` | Illustrative orchestrator showing stages (serial + parallel) and phase files |

The runtime command file lives at `~/.claude/commands/create-mvp.md` after install — the standard Skills/commands path read by Claude Code, Cursor, and other compatible agents.

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

### Build as a cloud Claude Skill

For [cloud Claude Skills](https://support.claude.com/en/articles/12512198-how-to-create-custom-skills) (claude.ai → Settings → Skills), run the export script instead:

```sh
sh export-skill.sh              # builds dist/create-mvp/SKILL.md + dist/create-mvp.zip
sh export-skill.sh --no-zip     # SKILL.md only, skip the archive
sh export-skill.sh --out PATH   # custom output root
sh export-skill.sh --force      # overwrite without prompting
```

The script reuses the same `src/*.md` partials as `install.sh`, but swaps the Claude-Code frontmatter for the cloud-skill format (`name` + `description`) and writes `SKILL.md` (capitalised, as the spec requires). The `.zip` contains `create-mvp/SKILL.md` at the root — drop it into the Skills uploader as-is.

> **Note:** the body of the skill is identical to the Claude Code command and references Claude-Code-specific bits like `$ARGUMENTS` and the local `MVP_HOME` filesystem path. Inside a cloud sandbox those won't substitute the same way; treat the cloud skill as a best-effort copy of the workflow for now.

---

## Usage

### `/create-mvp [project one-liner] [stop-after=plan|N]`

Runs a 6-phase workflow:

1. **Requirements** — open-ended questions, one at a time. Optionally seed from a PRD/RFC/plan path. Keeps asking *"what else?"* until you say **done**.
2. **Gap analysis** — probes for stack, testing, auth, deployment, security, observability, etc. Asks whether the project is a throwaway or meant to outlive the MVP. If outlive: writes 3–5 ADRs (`adrs/NNNN-*.md`) for the major architectural decisions, defaulting to `MVP_PROJECT/adrs/` (opt-in to commit them into the repo instead).
3. **Plan sketch** — drafts the phase breakdown in chat, with t-shirt sizing (S/M/L/XL), dependency graph, and parallel groups. Iterates until you confirm.
4. **Plan files** — picks a slug (default `<basename>-<6char>`), writes `00-orchestrator.md`, per-phase plan files, and a `memory/` folder to `$MVP_HOME/plans/<slug>/`. Registers the MVP. Two-pass: stubs first, then deep fill.
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

### `/create-mvp import <path>`

Brings a plan folder produced on another machine into this machine's `$MVP_HOME` and registers it, so `/create-mvp resume` can pick it up.

- `<path>` is a `.zip` or a directory. The plan folder must contain `00-orchestrator.md`.
- Extracts (if a zip), locates the plan-folder root, and copies it to `$MVP_HOME/plans/<slug>/` (slug taken from the orchestrator; prompts on collision).
- Reconciles `PROJECT_ROOT`: shows the origin machine's **Project path** and lets you point it at wherever the repo lives locally — rewriting that one line. Warns if the path doesn't exist yet.
- Registers the MVP from its orchestrator, then tells you to run `/create-mvp resume`. Never executes build phases itself.

### `/create-mvp export [verify-only]`

Packages a plan folder into a portable `.zip` for sharing — the counterpart to `import`. **Verifies portability first.**

- Selects the MVP the same way `resume` does (`slug=<x>`, CWD auto-pick, or picker).
- **Portability lint** — scans the whole folder (orchestrator, phase plans, `adrs/`, `memory/`) for hardcoded absolute paths. The only one allowed is the orchestrator's **Project path** line; everything else must use `MVP_PROJECT` / `PROJECT_ROOT`. Offers to auto-rewrite obvious leaks (the repo path → `PROJECT_ROOT`, the plan dir → `MVP_PROJECT`); unrelated absolute paths are flagged for manual fix.
- Zips from `$MVP_HOME/plans/` so the archive's top level is `<slug>/…` — exactly what `import` expects.
- `verify-only` runs the lint and reports pass/fail without packaging.

> **Sharing / porting an MVP.** The slug folder is self-describing — the orchestrator carries everything the registry needs (the registry is just a rebuildable local index that doesn't travel with the folder). So sharing is: run `/create-mvp export`, hand over the `.zip`, and the recipient runs `/create-mvp import <zip>`. If a registry is ever lost but the plan folders survive, `/create-mvp resume` offers to rebuild it from the orchestrators on disk.

---

## Design decisions

A few choices that matter:

### Plans live centrally, not in the project
Plans are process artifacts, not project artifacts. They live at `$MVP_HOME/plans/<slug>/` (default `~/.local/share/create-mvp/plans/<slug>/` on macOS/Linux) and don't pollute the project repo.

### Plans carry no hardcoded absolute paths
Plans reference two placeholders: `MVP_PROJECT` (the slug folder) and `PROJECT_ROOT` (the code repo). The only real absolute path in the whole folder is the orchestrator's **Project path** field — the single line a developer edits after cloning the repo to a different path. ADRs and agent memory live under `MVP_PROJECT/`, so they travel with the plan.

### One command, four modes
`/create-mvp`, `/create-mvp resume`, `/create-mvp import <path>`, and `/create-mvp export` are the same command. The Phase 0 router branches on the `resume` / `import` / `export` flags. One file to maintain, one runtime prompt, one cache key.

### Source is split into partials, runtime is one file
`src/00-header.md` through `src/09-principles.md` are authored independently and concatenated by `install.sh` into a single `create-mvp.md`. Modular for humans, monolithic for the model.

### Optional doc seed in Phase 1
If you have an existing PRD/RFC/plan, paste the path. The command reads it, extracts requirements, and asks *"is this complete?"* — only loops on what's missing.

### ADRs are conditional, and default to the plan folder
The longevity branching question in Phase 2 decides whether ADRs get written — throwaway prototypes skip them entirely. When written, they default to `MVP_PROJECT/adrs/`: for an MVP an ADR is agent context (it keeps the build coherent as it progresses), not yet a product commitment. If you expect the project to outlive the MVP, opt in to commit them into the repo's `adrs/` instead.

### Agent memory travels with the plan
`MVP_PROJECT/memory/` mirrors the agent's native project-memory format (one fact per file + a `MEMORY.md` index), relocated into the slug folder so it's portable. Code-style and workflow conventions decided during the build go here, so every subagent inherits them.

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

For a worked illustration of an orchestrator with serial and parallel stages, see [`examples/example-orchestrator/00-orchestrator.md`](examples/example-orchestrator/00-orchestrator.md).

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

/create-mvp import ~/Downloads/todo-app-x7f3a.zip  # import a shared MVP, then resume
/create-mvp import ../shared/todo-app-x7f3a        # import from a directory

/create-mvp export                                 # verify + package the CWD's MVP for sharing
/create-mvp export slug=todo-app-x7f3a out=~/share # package a specific MVP to a path
/create-mvp export verify-only                     # portability lint only, no packaging
```

---

## On-disk layout after install

```
~/.claude/commands/
└── create-mvp.md                           # single command file (concatenated from src/*)

~/.local/share/create-mvp/                  # = $MVP_HOME (XDG default; override via CREATE_MVP_HOME)
├── registry.json                           # slug → { project_path, summary, ... }
└── plans/
    └── <slug>/                             # = MVP_PROJECT
        ├── 00-orchestrator.md              # status, graph, stages; "Project path" = PROJECT_ROOT
        ├── 01-scaffold.md
        ├── 02-data.md
        ├── ...
        ├── adrs/                           # default ADR home (only if "outlive" in Phase 2)
        │   ├── 0001-stack-choice.md
        │   └── ...
        └── memory/                         # code-style & workflow facts, native memory format
            ├── MEMORY.md                   # index
            └── <fact>.md
```

A target project itself stays clean:

```
your-project/                               # = PROJECT_ROOT
├── adrs/                                   # only if you opt to commit ADRs into the repo
│   ├── 0001-stack-choice.md
│   └── ...
└── <your actual code>
```

---

## Requirements

- A compatible agent that reads Skills/commands from `~/.claude/commands/` — primarily [Claude Code](https://claude.ai/code), also Cursor and similar tools.
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
