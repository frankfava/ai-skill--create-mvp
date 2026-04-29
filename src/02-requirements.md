---

## Phase 1 — Requirements (open-ended loop)

Goal: draw out a complete picture of what the user wants built, without proposing solutions.

On entry, tell the user exactly this:

> I'll ask open-ended questions to capture the requirements. When your list feels complete, say **done** and I'll start planning. Otherwise I'll keep asking **"what else?"**.
>
> Heads up: this session can't be resumed until requirements are captured and the orchestrator file is written (end of Phase 4). Stay engaged until then.

### Optional starting point — existing doc

Before the loop, ask exactly:

> Do you have an existing plan, RFC, or PRD I can use as a starting point? Paste one path, or say **none**.

Branch on the answer:

- **none** → skip to the first open-ended question below.
- **Path can't be read** (file missing or unreadable) → tell the user *"Couldn't read that path — continuing without it."* and skip to the first open-ended question.
- **Readable path** →
  1. Read the document.
  2. Extract requirements into the internal running list (same shape the loop produces — group by users/flow/must-haves/constraints/data/integrations where the doc covers them).
  3. Show a concise bulleted summary back to the user, then ask exactly:
     > Is this requirements list complete?
  4. Branch:
     - **No** → enter the open-ended loop with this list as seed context. Rotate only through threads the doc didn't cover. Use the doc-aware entry question below.
     - **Yes** → ask exactly *"To confirm, type `done` to close requirements and move to Phase 2."* The user typing `done` is the normal exit condition (below).

### First open-ended question

Pick the entry question based on what you have so far:

- **No doc provided (or unreadable)** — ask:
  > In one or two sentences, what problem does this MVP solve and who is it for?

- **Doc provided, user said "No" (list incomplete)** — ask:
  > What's missing from the requirements I extracted?

  Only fall back to *"In one or two sentences, what problem does this MVP solve and who is it for?"* if the doc didn't make problem + audience clear.

After each answer, either dig one level deeper on that thread **or** ask **"What else?"**. Rotate through these threads naturally — do NOT recite them as a checklist:

- Users & core job-to-be-done
- End-to-end user flow ("walk me through it from open to aha")
- Must-haves vs nice-to-haves
- Definition of "done enough to ship"
- Constraints: time, budget, team, deployment target
- Data: what's stored, where it comes from, who owns it
- Integrations: third-party services, APIs, auth providers

Rules:
- One question per message in Phase 1. Never batch.
- Never assume. If the user says "it has auth", ask what kind.
- Keep an internal running list. Show it on request.
- If the user contradicts an earlier answer, flag it: *"Earlier you said X — want to revise that?"*

**Exit condition:** user types `done`. Proceed to Phase 2 immediately, no ceremony.
