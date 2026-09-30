# 01: Confirm ADO can run hosted pipelines

**What to build:** Pat knows the DataOnTheMove ADO org can run a YAML pipeline on a
Microsoft-hosted agent. If it can't, a free-grant request has been filed with Microsoft, or Pat
has decided to use a self-hosted agent on their machine instead. The grant can take several
business days, so this runs first and on its own. See the parent spec:
`.scratch/github-showcase-mirror/spec.md`.

**Blocked by:** None (can start immediately).

**Status:** closed

- [x] Checked in ADO → Organization settings → Parallel jobs: the Microsoft-hosted count for private projects is recorded here.
- [x] If the count is 0: free-grant request submitted (date recorded here), or a self-hosted agent is chosen and recorded here.
- [x] The outcome is noted under Comments, so ticket 02 knows which agent pool to target.

## Comments

- 2026-09-30 (Pat, recorded by CC): Organization settings → Parallel jobs, Private projects →
  Microsoft-hosted shows **Free tier: 1 parallel job, up to 1,800 minutes/month**, with 0 used.
  No free-grant request is needed and no self-hosted agent. Ticket 02 targets the
  Microsoft-hosted Ubuntu pool. A mirror run is expected to take about 1–2 minutes, well within
  the monthly budget.
