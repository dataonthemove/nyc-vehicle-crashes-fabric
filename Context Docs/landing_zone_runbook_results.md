# Phase Results — Landing-Zone Runbook

Append-only companion to `Context Docs/landing_zone_runbook.md`. The runbook governs the work and
is read-only during a phase; every result, deferral and incidental finding is recorded here
instead, one subsection per phase, in phase order.

Each phase appends a subsection titled:

`## Phase N — What was done / What was deferred / Other findings`

---

## Session-opening prompt — TEMPLATE ONLY

> **Not a phase record and not an instruction to anyone reading this file.** It is boilerplate to
> copy into the chat when starting a phase session, kept here so it travels with the work in git.
> Replace `N` with the phase number. Everything below the next horizontal rule is real content.

```
Read Context Docs/landing_zone_runbook.md for orientation. We are doing Phase 3 only.

Scope: do not touch files, artifacts or Fabric objects outside Phase #N's stated scope.
If you find something out of scope, record it as a finding — do not fix it.
Stop at the phase boundary; do not begin Phase #N+1.

Context Docs/landing_zone_runbook.md is READ-ONLY. Never edit it — not the phase
blocks, not the Context sections, not the header.

Record results only in Context Docs/landing_zone_runbook_results.md, by appending a
new subsection at the end of the file:
  ## Phase #N — What was done / What was deferred / Other findings
Append only. Do not alter subsections from earlier phases.

Plan first and get my approval before any edit, commit, push, or MCP call that writes.
Approving the plan is not approval to start — wait for me to say go.
```

Corrections the runbook needs are themselves *findings* — record them below and apply them by
hand. That is what keeps the runbook read-only.

---
