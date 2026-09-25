# 05: Validate Test and Prod on the new capacity

**What to build:** Proof that the Test and Prod stages survived the move with their data, model and deployment-rule bindings intact. There is no stage load, because Dev (ticket 04) already proves the load path.

**Blocked by:** 02 (Reassign all four workspaces to the new trial)

**Status:** done (2026-09-25)

- [x] In both stages, the Lakehouse and Warehouse row counts (read by OneLake path from Livy) match the parent spec's baseline.
- [x] In both stages, `/dax-smoke-test` passes after `refresh_semantic_model`.
- [x] In both stages, the effective Direct Lake binding (`/datasources`) matches that stage's deployment rule: server and database are the stage's own Warehouse.

## Comments

2026-09-25 (CC): Closed. Every check was run via MCP or Power BI REST. `list_workspaces` shows Test and Prod on `e52c9636…`.

- **Counts** (Livy, one session per stage, both closed): all 15 baseline objects match exactly in both stages (3 Lakehouse tables, 12 Warehouse tables).
- **Refresh + smoke test:** `refresh_semantic_model` Completed in both stages (Test refresh `452884701`, 14 s; Prod `452884723`, 13 s). DAX in each stage: all 12 table counts and the core measures match the baseline (Total Crashes 2,269,187; Persons Injured 756,353; Total Vehicles 4,551,002). None of the 13 relationships has orphan many-side rows. The largest single-factor crash count is 489,682, so the bridge `bothDirections` cross-filter holds.
- **Binding:** `/datasources` returns `Sql` in both stages, matching the deployment rules:
  - Test: server `…-kgbhznqz6ckeln3zxqxoctmda4.datawarehouse.fabric.microsoft.com`, database `c2ce6eed-e8d2-46dc-93f6-7bd3bb12edff`.
  - Prod: server `…-d7atl7mnt7vexgkzrj5fhiwdsa.datawarehouse.fabric.microsoft.com`, database `a72a40c8-7dba-497e-9c92-0847e39c0ebd`.
