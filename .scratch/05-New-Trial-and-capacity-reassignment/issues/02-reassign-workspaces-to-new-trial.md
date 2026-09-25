# 02: Reassign all four workspaces to the new trial

**What to build:** Pat, signed in as `Jpb_fabric_user8`, bulk-assigns Landing, Dev, Test and Prod to trial capacity `e52c9636-f9c4-4f58-94c7-57568d827005` by following the runbook. If the bulk route fails, `user7` reassigns each workspace from its settings. The old trial `f1b1feea…` is not cancelled.

**Blocked by:** 01 (Draft the capacity reassignment runbook)

**Status:** done (2026-09-25)

- [x] `list_workspaces` reports `capacityId` `e52c9636-f9c4-4f58-94c7-57568d827005` for all four workspaces.
- [x] None of the four shows the "items not migrated" banner under Workspace settings → Workspace type. If one does, retry the reassignment while the old trial is still alive.
- [x] Everything done before 2026-09-28.

## Comments

2026-09-25 (CC): Pre-move `list_workspaces` showed all four on `f1b1feea…`. After Pat bulk-assigned them as `user8` (Admin portal → Capacity settings → Trial), all four report `e52c9636-f9c4-4f58-94c7-57568d827005`. The banner check is still open (Pat).

2026-09-25 (Pat): Signed in as `user7` and checked Workspace settings → Workspace type in all four workspaces. None shows an "items not migrated" banner. The bulk route worked, so the fallback (3.5–3.7) wasn't needed. `user7` still sees a "trial expiring in 3 days" banner. That is `user7`'s own old trial (`f1b1feea…`), expected, and left to expire.

2026-09-25 (CC): Closed. For ticket 06: sign in as `user7` after 2026-09-28 and check that authoring still works. It's not yet known whether `user7`'s old trial also gave that account a license. Add this check to the runbook.
