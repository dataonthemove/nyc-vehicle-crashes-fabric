# 04: Validate Dev on the new capacity

**What to build:** Proof that Dev's data survived the move and that a full end-to-end stage load works on the new capacity. That exercises Spark, the stored-procedure activities and `vl_NYC_Crashes`. Row counts are checked **before** the stage load, so the load can't hide any data lost in the move.

**Blocked by:** 02 (Reassign all four workspaces to the new trial)

**Status:** ready-for-agent

- [ ] Before the stage load, the Lakehouse and Warehouse row counts (read by OneLake path from Livy) match the parent spec's baseline.
- [ ] After `refresh_semantic_model`, `/dax-smoke-test` passes.
- [ ] The effective Direct Lake binding (`/datasources`) points at Dev's own Warehouse.
- [ ] One full `pl_stage_load_NYC_Crashes` run succeeds, and the counts still match the baseline afterwards (no new landed data, so nothing should change).
