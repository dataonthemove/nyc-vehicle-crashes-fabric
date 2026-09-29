# 07: Post-expiry check and `user6` access in Dev

**What to build:** Confirm the workspaces still work for `user7` after the old trial lapses, and decide what happens to an unexpected Admin in Dev.

**Blocked by:** 06 (Close out). Also, it can't start before 2026-09-29.

**Status:** done (2026-09-29)

- [x] On or after 2026-09-29, Pat runs runbook section 6 (`Context/capacity-reassignment-runbook.md`) and records the outcome in its Move log.
- [x] Pat decides whether `Jpb_fabric_user6` keeps its **Admin** role in Dev (found via `roleAssignments` on 2026-09-25; it's in no other workspace). Update the Workspaces note in `Context/environment-reference.md` to match.

## Comments

2026-09-29 (CC): Closed.

- **Post-expiry check:** `user7` is Free, and its Power BI trial expired with no further trial allowed. The semantic-model SDLC path passed as `user7` (test measure `9cd1bce` / `0fc434e`: Update All, model-only Dev → Test deploy, refresh). Report create/save/delete is blocked by the licence. Logged in the runbook Move log.
- **`user6`:** no longer present in any workspace, so no decision was needed; env-reference updated.
- **Follow-on:** single-account rotation model in `.scratch/Backlog/capacity-rotation-single-account/spec.md`.
