# Phase 1: Scaffold

- **Size:** S
- **Depends on:** —
- **Status:** pending
- **Stage:** 1 (serial)

## Objective
Create the empty project tree and pin tooling versions so subsequent phases have a stable base.

## Inputs
- Confirmed requirements from Phase 1 of `/create-mvp`.
- Chosen stack (e.g. Vite + SQLite + Hono).

## Deliverables
- `package.json`, lockfile, `.gitignore`, `README.md` stub.
- Empty directories: `src/`, `public/`, `db/`.

## Task breakdown
- [ ] step 1 — `npm init` and pin Node version via `.nvmrc`.
- [ ] step 2 — install runtime + dev deps; commit lockfile.
- [ ] step 3 — write minimal `README.md` (project name + one-line summary).

## Acceptance criteria
- `npm install` succeeds on a fresh checkout.
- `git status` is clean after the initial commit.

## Test strategy
Manual: clone the repo into a tmp dir, run install, confirm exit 0.

## Risks & unknowns
None at this size.

## Iteration ceiling
~10 TodoWrite updates. If exceeded, surface to user.
