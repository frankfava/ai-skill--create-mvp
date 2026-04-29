---

## Phase 2 — Gap analysis + longevity check

### 2a. Longevity check (first question in Phase 2)

Ask exactly:

> Quick branching question: is this a **throwaway prototype** (validate an idea, probably toss the code), or do you expect it to **outlive the MVP** (become a real product, onboard others, need to be maintained)?

Record the answer. If **outlive**, you will write ADRs during this phase. If **throwaway**, skip ADRs entirely.

### 2b. Gap questions

For each topic below not explicitly covered in Phase 1, ask a targeted question. Batch 2–3 related gaps per message. Accept "skip for MVP" as a valid answer — record it.

- **Stack** — language, framework, runtime, package manager
- **Data layer** — DB, schema approach, migrations
- **Auth** — who authenticates, how (if any)
- **Testing** — unit / integration / e2e, coverage target
- **Documentation** — README, API docs, inline, ADRs
- **Deployment** — local, VPS, serverless, container platform
- **CI/CD** — automated checks, deploy pipeline
- **Error handling & logging**
- **Security basics** — secrets, input validation, CORS, rate limits
- **Performance / scale** — expected load, latency targets
- **Accessibility** (if UI)
- **Observability** — monitoring, metrics, alerts

### 2c. ADRs (only if outlive = true)

As gap answers come in, write a short ADR for each **major** architectural decision — cap at 3–5 total. ADR-worthy: stack choice, data layer choice, auth approach, deployment target, major third-party dependency. Skip operational trivia.

ADRs are project artifacts (committed alongside the code), so write them to `<project root>/adr/NNNN-<slug>.md`:

```markdown
# NNNN: <title>

- **Status:** Accepted
- **Date:** <YYYY-MM-DD>

## Context
<1–3 sentences: why this decision is being made now>

## Decision
<1–2 sentences: what was chosen>

## Alternatives considered
- <option>: <why not>
- <option>: <why not>

## Consequences
<trade-offs accepted; what this locks in or forecloses>
```

When all gaps have explicit answers, proceed to Phase 3.
