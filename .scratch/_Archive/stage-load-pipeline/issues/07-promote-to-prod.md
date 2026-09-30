# 07: Promote to Prod

**What to build:** The Stage load, deployed to Prod by the deployment pipeline, runs manually against Prod's own Lakehouse, Warehouse and model, never Dev's or Test's.

**Blocked by:** 06

**Status:** done (2026-09-24)

- [x] Pipeline deployed Test → Prod, together with `vl_NYC_Crashes` (never the pipeline first)
- [x] Before running: the Prod `warehouse_endpoint` resolves to the Prod TDS host (`…d7atl7mn…`), and every SP `artifactId` = the Prod Warehouse (`a72a40c8-…`)
- [x] `vl_NYC_Crashes` active value set = Prod
- [x] Prod has no schedule after the deploy (deployment copies the source workspace's schedule; there should be none to copy)
- [x] One manual Prod run succeeds; Prod's model last-refresh time moved, and Dev's and Test's did not

## Scope decisions (Pat, 2026-09-23)

- **No scheduling anywhere in this solution.** Not in Dev, Test or Prod, and not the landing CDC run. Every Stage load is a manual run. The original "daily 04:00" boxes were removed.
- **No release tag.** This is a practice project, not a real production, so the old SDLC "tag the commit deployed to Test" rule doesn't apply.

## Pre-deploy state (MCP, 2026-09-23)

The Prod workspace `4_NYC_VehicleCrashes_prod` has no `pl_stage_load_NYC_Crashes` yet. `vl_NYC_Crashes` is present (`b37ae4dd-…`), but its active value set hasn't been checked.

## Outcome (2026-09-24)

Pat deployed `pl_stage_load_NYC_Crashes` and `vl_NYC_Crashes` together, Test → Prod. Prod pipeline physical ID: `8d6d62a6-2bee-4b4f-b29b-03c70a01bdcb`.

**Pre-run checks** (MCP `get_pipeline_definition` plus Fabric REST):
- All 12 SP activities: `artifactId` = Prod Warehouse `a72a40c8-…`, `workspaceId` = Prod, `endpoint` = the library-variable expression.
- Ingest ×3 and Refresh use Prod notebooks (`63deb6d9-…`, `58ae15a5-…`).
- `vl_NYC_Crashes` `activeValueSetName` = `Prod`. Its `warehouse_endpoint` override = the Prod TDS host (`…d7atl7mn…`).
- The Prod schedule list is empty.

**Run** `77a30e72-8c90-4ba1-a5ee-a36c6c1ddebb` Succeeded, 23:18:41 → 23:23:28 UTC. All 16 activities Succeeded, and Refresh ran last (23:22:19 → 23:23:25).

**Stage isolation:**
- Prod model: first-ever refresh, `ViaEnhancedApi`, 23:22:38 → 23:22:59, Completed. A `DirectLakeFraming` completed at 23:23:07.
- Dev's latest refresh is still 2026-09-23 14:36 and Test's is still 2026-09-23 14:59, so this run touched neither.

**Prod DAX counts:** fact_crashes 2,269,187 · fact_persons 5,984,110 · fact_crash_vehicle 4,551,002 · bridge_crash_factor 1,648,599. These equal the Test baseline.
