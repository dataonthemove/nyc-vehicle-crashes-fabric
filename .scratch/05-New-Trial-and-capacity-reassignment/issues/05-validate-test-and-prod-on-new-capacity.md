# 05: Validate Test and Prod on the new capacity

**What to build:** Proof that the Test and Prod stages survived the move with their data, model and deployment-rule bindings intact. There is no stage load, because Dev (ticket 04) already proves the load path.

**Blocked by:** 02 (Reassign all four workspaces to the new trial)

**Status:** ready-for-agent

- [ ] In both stages, the Lakehouse and Warehouse row counts (read by OneLake path from Livy) match the parent spec's baseline.
- [ ] In both stages, `/dax-smoke-test` passes after `refresh_semantic_model`.
- [ ] In both stages, the effective Direct Lake binding (`/datasources`) matches that stage's deployment rule: server and database are the stage's own Warehouse.
