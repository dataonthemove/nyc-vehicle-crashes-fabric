# 06: Promote to Test

**What to build:** The Stage load, deployed to Test by the deployment pipeline, runs manually against Test's own Lakehouse, Warehouse and model, never Dev's.

**Blocked by:** 05

**Status:** done (2026-09-23)

- [x] Pipeline deployed Dev → Test
- [x] Stored Procedure activities point at the Test Warehouse after deployment. Watch `endpoint`: it is a literal Dev TDS host in Git (see ticket 01 Outcome); `artifactId` is a logical ID in Git and autobinds on deployment. If not, add a Deployment Rule or Variable Library item reference and record the outcome in the spec's Further Notes (possible ADR).
- [x] Ingest and Refresh notebooks bound to Test items (autobind)
- [x] `vl_NYC_Crashes` active value set = Test (ADR-0003)
- [x] A manual Test run succeeds; the Test model's last-refresh time moved and Dev's did not (spec Test 4)
- [x] Test has no schedule (scheduling deferred; see Progress)

## Evidence from ticket 04 (2026-09-23)

Fabric branch-out rehydrated each SP activity's Warehouse `artifactId` but **left `endpoint` as the Dev TDS host**. Every SP activity then failed with "database was not found". Treat the endpoint as not rebinding on deployment either until a Test run proves otherwise.
Branch-out also left `nb_cdc_to_delta`'s default lakehouse pointing at Dev. The environment reference says deployment autobinds notebooks, but verify it here anyway, because a missed rebind makes Test's Ingest write into Dev silently.

## Progress (2026-09-23)

- **Deployed:** Pat deployed the pipeline item alone, Dev → Test, via the deployment pipeline UI. Test item `57d48e48-f7fa-4df7-ba55-f35428ce8bcf`.
- **Bindings after deploy** (read via MCP `get_pipeline_definition`):
  - All three Ingest activities and Refresh → Test notebooks (`7fa44195-…`, `3caf0c97-…`) in the Test workspace. Autobind works.
  - Test `nb_cdc_to_delta` default lakehouse = Test Lakehouse `620d0b45-…`.
  - All 12 SP activities: `artifactId` = Test Warehouse `c2ce6eed-…`, `workspaceId` = Test. **`endpoint` = the Dev TDS host (`…fvq5c4z6…`), not rewritten.** Deployment behaves the same as branch-out. A run would fail with "database was not found"; it could not write to Dev.
- **Active value set:** `vl_NYC_Crashes` in Test already = `Test` (REST `activeValueSetName`).
- **Test model binding:** it already points at the Test Warehouse (`/datasources`). Its last refresh (2026-09-21 22:55) failed with a transient `Premium_ASWL_Error` (a request-send error), not a binding fault.
- **Schedules DO deploy.** The deploy created an enabled Daily 04:00 schedule in Test (`84da28bc-…`, a copy of Dev's). This contradicts the spec's "schedules are not deployed". CC deleted it via REST; the Test schedule list is empty. **Prod will get one on promotion.** Ticket 07 must verify it and keep it, not create a second.
- **Endpoint fix:** Deployment Rules don't cover pipelines, and an `ItemReference` variable exposes only `workspaceId`/`itemId`, not the host. The fix is String variable `warehouse_endpoint` in `vl_NYC_Crashes` (Dev default; Test/Prod overrides), referenced from each SP connection. Pat seeds the pipeline-JSON reference on one activity in the Dev UI to capture the exact schema. CC then applies it to the other 11 locally.
- **Schema captured** (Fabric commit `05a4542`, seeded on `Load_dim_date`): a pipeline-level `libraryVariables` block (`vl_NYC_Crashes_warehouse_endpoint` → library `vl_NYC_Crashes`, variable `warehouse_endpoint`, type String). The connection's `endpoint` is the plain string `"@pipeline().libraryVariables.vl_NYC_Crashes_warehouse_endpoint"`, not an Expression object. The UI's dynamic-connection form showed Warehouse ID and Workspace ID as Dev literals, but Git serialized them back to the logical `artifactId` and zero `workspaceId`, so they still rebind on deployment. CC applied the endpoint expression to the other 11 SP activities.
- **The connection-ID detour was unnecessary.** The dynamic form's first field is labelled "Connection (Warehouse ID)" and takes the Warehouse *item* ID. The investigation did find that `DataWarehouseConnection` (`1de56b14-…`) held `Jpb_fabric_user6` OAuth credentials; Pat re-signed it as `user7`. This pipeline doesn't use it.
- **Schedules are in Git.** `05a4542` also added `.schedules` (Daily 04:00, GMT Standard Time), which is why deployment carries the schedule. Every deploy to Test will recreate it, so delete it after each Test deploy until a per-stage mechanism exists. Prod wants it.
- **Scheduling deferred (Pat, 2026-09-23).** Pat deleted the Dev schedule; scheduling in every stage is out of scope for now as premature. The "Test has no schedule" box is satisfied by there being no schedule anywhere. Revisit per-stage schedules (and `.schedules` in Git being carried by deployment) as a separate item.
- **Dev regression after the endpoint change:** the live Dev definition matched the repo (12/12 SP endpoints on the library variable, `artifactId` = Dev Warehouse). Run `3e181877-01db-47f9-857d-1e7436126762` Succeeded 14:32:41 → ~14:36:30 UTC. All 16 activities Succeeded, and Refresh ran last (14:35:50 → 14:36:27). The library variable resolves inside the SP connection.

## Outcome (2026-09-23)

Pat redeployed `pl_stage_load_NYC_Crashes` and `vl_NYC_Crashes` to Test. Before the run: all 12 SP activities had the library-variable endpoint, with `artifactId`/`workspaceId` = Test; Ingest/Refresh used Test notebooks; the Test active value set = `Test`, whose `warehouse_endpoint` override = the Test TDS host (`…kgbhznqz…`); there was no schedule.

Run `b7180204-24c6-400e-ab34-587312b4fede` Succeeded 14:55:50 → 15:00:14 UTC. All 16 activities Succeeded, and Refresh ran last (14:59:00 → 15:00:13).
- **Spec Test 4 (stage isolation):** the Test model has an enhanced-API refresh 14:59:20 → 14:59:37 Completed (previous: 12:43:50). Dev's latest refresh is still 14:36:12, from the Dev regression run, so the Test run didn't touch it.
- A concurrent automatic `DirectLakeFraming` on Test failed at 14:59:13 while the notebook refresh held the model. The next one completed at 14:59:43. This is benign, but expect it in Test/Prod refresh history.
- Test DAX counts after the run: fact_crashes 2,269,187 · fact_persons 5,984,110 · fact_crash_vehicle 4,551,002 · bridge_crash_factor 1,648,599. These equal the baseline.

Decision recorded in ADR-0003 (Bindings table) and in the spec's Further Notes: the SP endpoint gets its value from the Variable Library, not from autobind or a Deployment Rule.
