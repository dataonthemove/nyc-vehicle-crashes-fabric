# 04: Promote to Test and Prod

**What to build:** Test and Prod serve the renamed model and pass the same lightweight binding check as Dev. No table reload is involved in either stage.

**Blocked by:** 03 (Rename in TMDL, update docs, verify in Dev).

**Status:** done

**Who:** Pat deploys through the deployment pipeline; Claude verifies each stage.

- [x] Pat: deploy the semantic model Dev → Test
- [x] `refresh_semantic_model` succeeds in Test
- [x] The per-table DAX query (same as ticket 03) passes in Test
- [x] Pat: deploy the semantic model Test → Prod
- [x] `refresh_semantic_model` succeeds in Prod
- [x] The per-table DAX query passes in Prod
- [x] Deployment Rules (Direct Lake on SQL data source, ADR-0004) are still in place and unchanged in both stages

## Comments

2026-09-29 — Test. Dev → Test deploy OK (Pat). The first check returned 0 rows everywhere. Cause: every
Test Warehouse star table, including `etl_watermark`, had been recreated empty at 2026-09-28 15:41 UTC
(Delta v0), a day before this work, so it's unrelated to the rename. Lakehouse source tables were intact.
Ran `pl_stage_load_NYC_Crashes` in Test (job 4f5fe754…): all ingest and load activities succeeded, and
Refresh_Semantic_Model failed (the known framing race). A standalone `refresh_semantic_model` then Completed.
Binding query passes with row counts identical to Dev (Fact Crashes 2,269,187 · Fact Crash Vehicles
4,551,002 · Fact Crash Persons 5,984,110 · Dim Date 6,940 …).
Prod pre-check: the Prod Warehouse was not emptied. Its tables were loaded 2026-09-27 23:3x UTC with counts
matching Dev. OK to promote.
Resolved: Deployment history shows a Test deploy at 2026-09-28 16:41 local (15:41 UTC) containing NYC_VehicleCrashes_Lakehouse + NYC_VehicleCrashes_Warehouse. That recreated the tables empty. The matching Prod deploy (16:44) did NOT recreate Prod tables.

2026-09-29 — Prod. Test → Prod deploy OK (Pat). `refresh_semantic_model` Completed (refresh 454552255).
Binding query passes with counts identical to Dev and Test. Effective data source is the Prod Warehouse
(`a72a40c8…`, `…d7atl7mnt7vexgkzrj5fhiwdsa` endpoint), so the ADR-0004 Deployment Rule is intact.
Ticket closed. The feature is complete in all three stages.
