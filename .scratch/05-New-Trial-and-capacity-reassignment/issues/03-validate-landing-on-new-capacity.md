# 03: Validate Landing on the new capacity

**What to build:** Proof that the Landing workspace's data survived the move and that Spark runs there on the new capacity.

**Blocked by:** 02 (Reassign all four workspaces to the new trial)

**Status:** ready-for-agent

- [ ] The `Files/raw` listing for crashes, persons and vehicles is intact.
- [ ] `etl_watermark` holds the three baseline rows unchanged (all dated 2026-09-10; see the parent spec).
- [ ] One `nb_etl_watermark` job run with `mode=read` succeeds and returns the same map.
