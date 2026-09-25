# 04: Validate Dev on the new capacity

**What to build:** Proof that Dev's data survived the move and that a full end-to-end stage load works on the new capacity. That exercises Spark, the stored-procedure activities and `vl_NYC_Crashes`. Row counts are checked **before** the stage load, so the load can't hide any data lost in the move.

**Blocked by:** 02 (Reassign all four workspaces to the new trial)

**Status:** done (2026-09-25)

- [x] Before the stage load, the Lakehouse and Warehouse row counts (read by OneLake path from Livy) match the parent spec's baseline.
- [x] After `refresh_semantic_model`, `/dax-smoke-test` passes.
- [x] The effective Direct Lake binding (`/datasources`) points at Dev's own Warehouse.
- [x] One full `pl_stage_load_NYC_Crashes` run succeeds, and the counts still match the baseline afterwards (no new landed data, so nothing should change).

## Comments

2026-09-25 (CC): Closed. Every check was run via MCP or Power BI REST. `list_workspaces` shows Dev on `e52c9636…`.

- **Pre-load counts** (Livy, session opened and closed): all 15 baseline objects match exactly (3 Lakehouse tables, 12 Warehouse tables).
- **Refresh + smoke test:** `refresh_semantic_model` Completed in 11 s (refresh `452880122`). DAX: all 12 table counts and the core measures match the baseline (Total Crashes 2,269,187; Persons Injured 756,353; Total Persons 5,984,110; Total Vehicles 4,551,002). None of the 13 relationships has orphan many-side rows. Bridge filtering works: the largest single-factor crash count is 489,682, well below the 2.27M total, so the `bothDirections` cross-filter holds.
- **Binding:** `/datasources` returns `Sql`, server `…-fvq5c4z6ak5ubekl7tlzmyqcem.datawarehouse.fabric.microsoft.com`, database `324e2ac0-5ebd-4f8a-9856-a5d7b56a25fe`. That is Dev's own Warehouse.
- **Stage load:** job `0d73d0a1-d396-49cd-bcd9-23d7f669815c` Completed in 4 m 35 s (04:30:43–04:35:18 UTC). All 16 activities succeeded: 3 Ingest notebooks, 12 SP activities and Refresh_Semantic_Model.
- **Post-load counts** (new Livy session, closed): all 15 still match the baseline.

For ticket 06, the runbook should note two things:
- The Stage Lakehouse is schema-enabled, so its Delta tables sit at `Tables/dbo/<table>`, not `Tables/<table>`.
- The Warehouse OneLake path works with GUIDs: `abfss://<ws-id>@onelake.dfs.fabric.microsoft.com/<warehouse-id>/Tables/dbo/<table>`.
