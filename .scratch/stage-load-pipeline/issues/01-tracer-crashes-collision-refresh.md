# 01: Tracer — crashes Ingest → dim_collision → Refresh

**What to build:** The first runnable Stage load. It uses pipeline `pl_stage_load_NYC_Crashes`, authored locally, pushed, and pulled into the Dev workspace by Fabric Source Control Update. The run executes three activities in a chain: one Notebook activity (Ingest, crashes, merge key `collision_id`), one Stored Procedure activity (the collision dimension load), and one Notebook activity (the refresh notebook). Each edge fires only on success. The slice proves the three risky mechanisms end to end: notebook parameter passing, Stored Procedure activity binding to the Dev Warehouse, and the refresh notebook running inside a pipeline.

**Blocked by:** None (can start immediately)

**Status:** done (2026-09-22)

Parent: `.scratch/stage-load-pipeline/spec.md`. The Fabric Source Control Update is a manual step for Pat.

- [x] Pipeline definition lives in the repo in a new Dev orchestration folder and appears in the Dev workspace after Update
- [x] A manual run via MCP ends Succeeded, with all three activities Succeeded, in order
- [x] The Ingest activity output shows `SUCCESS|crashes` or `NO_NEW_DATA`, both accepted as success
- [x] The Refresh activity ran last, and the Dev model's last-refresh time moved
- [x] The Stored Procedure activity's Warehouse reference is recorded (logical vs physical) for use in ticket 06

## Outcome (2026-09-22)

Commit `1ddacd9`. Run `2ae73cc8-257a-4bed-9003-1233301b6141` Succeeded 21:27:44 → 21:30:22 UTC:
Ingest_Crashes 91 s (exit `SUCCESS|crashes`) → Load_dim_collision 13 s → Refresh_Semantic_Model 51 s.
Dev model last refresh moved 2026-09-21 03:24 → 2026-09-22 21:29 UTC.

**Stored Procedure activity Warehouse reference (for ticket 06):** authored in Git as
`linkedService.typeProperties.artifactId` = Warehouse *logical* ID `da2b14e1-…`, `workspaceId` all
zeros. Fabric Update rehydrated both to Dev's *physical* IDs (`324e2ac0-…`, `73d1612d-…`).
`endpoint` is a literal Dev TDS host and was **not** rewritten — it is the field most at risk of
pointing at Dev after promotion.
