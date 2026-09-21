# 01: Tracer — crashes Ingest → dim_collision → Refresh

**What to build:** The first runnable Stage load. It uses pipeline `pl_stage_load_NYC_Crashes`, authored locally, pushed, and pulled into the Dev workspace by Fabric Source Control Update. The run executes three activities in a chain: one Notebook activity (Ingest, crashes, merge key `collision_id`), one Stored Procedure activity (the collision dimension load), and one Notebook activity (the refresh notebook). Each edge fires only on success. The slice proves the three risky mechanisms end to end: notebook parameter passing, Stored Procedure activity binding to the Dev Warehouse, and the refresh notebook running inside a pipeline.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

Parent: `.scratch/stage-load-pipeline/spec.md`. The Fabric Source Control Update is a manual step for Pat.

- [ ] Pipeline definition lives in the repo in a new Dev orchestration folder and appears in the Dev workspace after Update
- [ ] A manual run via MCP ends Succeeded, with all three activities Succeeded, in order
- [ ] The Ingest activity output shows `SUCCESS|crashes` or `NO_NEW_DATA`, both accepted as success
- [ ] The Refresh activity ran last, and the Dev model's last-refresh time moved
- [ ] The Stored Procedure activity's Warehouse reference is recorded (logical vs physical) for use in ticket 06
