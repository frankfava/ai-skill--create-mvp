---

## Phase 3 — Plan sketch (in chat, not files yet)

Draft the plan structure in chat before writing any files. Output:

1. **Phase inventory** — pick from: Scaffold, Data layer, Auth, Core domain, API, UI, Integrations, Testing, Docs, Deploy. Drop what doesn't apply.
2. **One-liner per phase** — objective + key deliverables.
3. **T-shirt size per phase** — S / M / L / XL (sizing rubric below).
4. **Dependency graph** — ASCII or mermaid.
5. **Parallel groups** — which phases can run concurrently once deps are met.
6. **Risk flags** — phases with unknowns that may need a spike.

**Sizing rubric:**
- **S** — mechanical, one file or a tight scaffold. Boilerplate.
- **M** — standard feature implementation, 2–5 files, known patterns.
- **L** — complex domain logic, cross-cutting concerns, or 5+ files.
- **XL** — architecturally tricky, non-obvious design, or heavy integration surface.

End with:

> Does this structure look right? Anything to add, cut, re-order, or re-parent?

Iterate until confirmed. Then proceed.
