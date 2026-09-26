# 01: Remove all measures and the Borough_Reader role

**What to build:** The semantic model carries no measures and no security roles, clearing the way for the remodel (D5, D10). Measures come back in a separate spec. This is the one ticket that touches the model only, so it can be synced to Dev on its own.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [x] Every measure is removed from all fact tables; no measure is repaired, renamed or added
- [x] Role `Borough_Reader` and its model reference are deleted
- [ ] TMDL-first: edited locally, committed, pushed; Pat syncs Dev (Update All) — the model-only exception to the Update All hold
- [ ] After sync and refresh, a DAX `COUNTROWS` query on each fact returns rows (model still serves)

## Comments
- 2026-09-26 (CC): removed all 29 measures (fact_crashes 18, fact_crash_vehicle 6, fact_persons 5) and `roles/Borough_Reader.tmdl` + its `ref role` in `model.tmdl`. Pure deletions, no other TMDL touched. Awaiting push, then Pat's Dev Update All + refresh + COUNTROWS check.
