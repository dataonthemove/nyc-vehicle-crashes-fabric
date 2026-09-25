# 07: Post-expiry check and `user6` access in Dev

**What to build:** Confirm the workspaces still work for `user7` after the old trial lapses, and decide what happens to an unexpected Admin in Dev.

**Blocked by:** 06 (Close out). Also, it can't start before 2026-09-29.

**Status:** ready-for-human

- [ ] On or after 2026-09-29, Pat runs runbook section 6 (`Context/capacity-reassignment-runbook.md`) and records the outcome in its Move log.
- [ ] Pat decides whether `Jpb_fabric_user6` keeps its **Admin** role in Dev (found via `roleAssignments` on 2026-09-25; it's in no other workspace). Update the Workspaces note in `Context/environment-reference.md` to match.

## Comments
