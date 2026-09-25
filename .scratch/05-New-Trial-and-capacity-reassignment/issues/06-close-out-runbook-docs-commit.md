# 06: Close out: correct the runbook, update docs, commit

**What to build:** The repo records the new capacity and the lessons from the move, so the next rotation (~2026-11-24) starts from an accurate state.

**Blocked by:** 03, 04, 05 (all validation tickets)

**Status:** ready-for-agent

- [ ] The runbook is corrected with whatever differed on move day.
- [ ] After the old trial expires (2026-09-28), `user7` can still open and author in all four workspaces. Add this post-expiry check to the runbook.
- [ ] `Context/environment-reference.md` has the new capacity ID, SKU and expiry; a note that `user8` is capacity/Fabric admin only and in no workspace; and a new re-verification date.
- [ ] The memory index is updated to cover the trial rotation.
- [ ] The parent spec's acceptance criteria are ticked, and its status is set to done.
- [ ] Committed as `CC Commit: envref_capacity_reassignment_trial2`, together with the pending `CONTEXT.md` glossary terms.
