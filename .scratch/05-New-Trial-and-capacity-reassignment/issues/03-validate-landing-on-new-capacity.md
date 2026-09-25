# 03: Validate Landing on the new capacity

**What to build:** Proof that the Landing workspace's data survived the move and that Spark runs there on the new capacity.

**Blocked by:** 02 (Reassign all four workspaces to the new trial)

**Status:** done (2026-09-25)

- [x] The `Files/raw` listing for crashes, persons and vehicles is intact.
- [x] `etl_watermark` holds the three baseline rows unchanged (all dated 2026-09-10; see the parent spec).
- [x] One `nb_etl_watermark` job run with `mode=read` succeeds and returns the same map.

## Comments

2026-09-25 (CC): Closed. All three checks were run via MCP.

- **`Files/raw`:** `list_lakehouse_files` returned 11 entries: `.keep`, three folders, and 7 files. Each folder has one full extract (crashes 600,453,804 B, persons 1,245,634,444 B, vehicles 1,046,196,268 B; ~2.9 GB in total) plus header-only files from zero-row runs. Every timestamp is on or before 2026-09-10 13:04 UTC, before the move. No file-count baseline was recorded at runbook step 2.4, so this check is presence and timestamps only.
- **`etl_watermark`** (Livy): 3 rows. crashes `2026-09-10 13:04:16`, persons `2026-09-10 13:05:12`, vehicles `2026-09-10 13:06:06`, which matches the baseline. The last commit in `DESCRIBE HISTORY` is v8 MERGE at 2026-09-10 13:06:47, so nothing has written to the table since. Livy session opened and closed.
- **`nb_etl_watermark mode=read`:** job `3b538fb5-6ff5-43fa-8119-2333c6eea238` Completed in 32 s. `get_notebook_run_details` reports `capacityId` `e52c9636-f9c4-4f58-94c7-57568d827005`, which proves Spark ran on the new capacity. Caveat: the REST API doesn't expose the notebook `exitValue`, so the returned map wasn't read directly. It is built from the same table verified above, and the run didn't raise.

For ticket 06: correct runbook 4.5 to say the exit map can only be read from a pipeline activity output or the notebook run's snapshot in the Fabric UI, not via MCP. Also have 2.4 record `Files/raw` file counts and sizes at the next rotation (baseline figures above).
