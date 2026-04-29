# Phase 3: Frontend

- **Size:** M
- **Depends on:** 2 (Config)
- **Status:** pending
- **Stage:** 2 (parallel — runs alongside Phase 4 Backend)

## Objective
Build the public landing page that lists items, plus the admin form for creating them. No styling beyond minimal layout.

## Inputs
- Configured project from Phase 2.
- API contract documented in `docs/api.md` (shared with Phase 4).

## Deliverables
- `src/pages/index.tsx` (list) and `src/pages/admin.tsx` (form).
- `src/lib/api.ts` thin client matching the contract.

## Task breakdown
- [ ] step 1 — render list page from a stubbed fetch (Phase 4 may not be done yet at fetch time, that's fine).
- [ ] step 2 — implement admin form with client-side validation.
- [ ] step 3 — wire the API client; cover happy path + 500 error.

## Acceptance criteria
- Both pages render without console errors against the stubbed API.
- Form submission posts the documented payload.

## Test strategy
- Component tests for the form (validation rules + submit dispatch).
- Snapshot of the rendered list against fixture data.

## Risks & unknowns
- Backend may finalize the API shape after this phase starts. If `docs/api.md` changes, treat as REQUIREMENTS_GAP and replan.

## Iteration ceiling
~25 TodoWrite updates. If exceeded, surface to user.
