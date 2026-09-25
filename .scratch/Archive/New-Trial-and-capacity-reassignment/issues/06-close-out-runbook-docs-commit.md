# 06: Close out: correct the runbook, update docs, commit

**What to build:** The repo records the new capacity and the lessons from the move, so the next rotation (~2026-11-24) starts from an accurate state.

**Blocked by:** 03, 04, 05 (all validation tickets)

**Status:** done (2026-09-25)

- [x] The runbook is corrected with whatever differed on move day.
- [x] After the old trial expires (2026-09-28), `user7` can still open and author in all four workspaces. Add this post-expiry check to the runbook. *(Check added as runbook section 6; Pat runs it on or after 2026-09-29.)*
- [x] `Context/environment-reference.md` has the new capacity ID, SKU and expiry; a note that `user8` is capacity/Fabric admin only and in no workspace; and a new re-verification date.
- [x] The memory index is updated to cover the trial rotation.
- [x] The parent spec's acceptance criteria are ticked, and its status is set to done.
- [x] Committed as `CC Commit: envref_capacity_reassignment_trial2`, together with the pending `CONTEXT.md` glossary terms.

## Comments

2026-09-25 (CC): Closed.

- **Runbook:** added a rotation-3 Parameters column, step 1.6 (`NEW_OWNER` holds no workspace role), the rotation-2 `Files/raw` baseline, GUID-based Livy paths (the Stage Lakehouse is at `Tables/dbo/<table>`), a note that 4.5's exit map can't be read via MCP, banner-check sign-in, section 6 (post-expiry check) and a move log.
- **Post-expiry check:** written as runbook section 6. It can't run before 2026-09-28, so Pat runs 6.1 on or after 2026-09-29.
- **Env-reference:** new capacity, SKU, expiry, re-verify-by date 2026-11-17, `user8` role note. `roleAssignments` confirmed `user8` is in no workspace, but found `Jpb_fabric_user6` as Admin in Dev. That's recorded as an open discrepancy, not changed.
- **CONTEXT.md:** the **Capacity** / **Capacity reassignment** glossary terms were already committed in `4f218c7`, so nothing was left pending.
- Not updated: `DIagrams/Arch_NYC_VehicleCrashes_v3.drawio` still shows the old capacity ID (the diagrams are documentation only).
