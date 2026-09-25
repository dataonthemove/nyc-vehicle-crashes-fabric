# 02: Reassign all four workspaces to the new trial

**What to build:** Pat, signed in as `Jpb_fabric_user8`, bulk-assigns Landing, Dev, Test and Prod to trial capacity `e52c9636-f9c4-4f58-94c7-57568d827005` by following the runbook. If the bulk route fails, `user7` reassigns each workspace from its settings. The old trial `f1b1feea…` is not cancelled.

**Blocked by:** 01 (Draft the capacity reassignment runbook)

**Status:** ready-for-human

- [ ] `list_workspaces` reports `capacityId` `e52c9636-f9c4-4f58-94c7-57568d827005` for all four workspaces.
- [ ] None of the four shows the "items not migrated" banner under Workspace settings → Workspace type. If one does, retry the reassignment while the old trial is still alive.
- [ ] Everything done before 2026-09-28.
