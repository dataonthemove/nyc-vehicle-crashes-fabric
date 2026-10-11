# 01: De-duplicate in nb_cdc_to_delta, proven in Dev

**What to build:** A Dev stage load succeeds against today's landing files, which repeat keys across
the 2026-09-10 full extract and the CDC run `8552e9f4` file. Fabric Notebook `nb_cdc_to_delta` keeps
one row per natural key, from the newest file by modification time (tie-break: source file path,
descending), on both the MERGE and the first-run write paths, and prints how many duplicate rows it
dropped. Parameters, exit values, target tables and columns are unchanged. Notebook comments and the
ingestion doc stop claiming de-duplication that did not exist.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Pull current Dev state via MCP: notebook definition matches git; last stage-load run failed as described | CC | Live definition diffs clean against the repo (ignoring logical IDs) | todo |
| 2 | Confirm Spark file `_metadata.file_modification_time` is available on the Dev runtime over Livy | CC | A Livy read of the crashes folder returns one modification time per file; else fallback chosen and noted here | todo |
| 3 | Re-check the 17 reported within-file crash duplicates with a `multiLine` read | CC | Real within-file duplicate count recorded here (expected 0 if the figure was a split-read artefact) | todo |
| 4 | Add the de-dup step between the audit columns and the write; drop the ranking column; print dropped-row count | CC | Notebook file edited in Fabric's compact formatting, no spurious diffs | todo |
| 5 | Update notebook cell 1 and cell 6 comments, and the duplicates claim in `docs/socrata-ingestion.md` | CC | No comment or doc says the MERGE alone handles repeated keys | todo |
| 6 | Commit locally (`CC Commit: dev_nb_cdc_to_delta_dedup-newest-per-key`) | CC | Commit exists on main, CRLF intact | todo |
| 7 | Push; Dev Source Control → Update All | Pat | Dev Source Control shows no pending incoming changes | todo |
| 8 | Record pre-run `nyc_*` row counts in Dev via Spark | CC | Three counts recorded here | todo |
| 9 | Run `pl_stage_load_NYC_Crashes` in Dev; rerun `refresh_semantic_model` if the Refresh activity hits the framing race | CC | All activities succeed; printed drop counts roughly match the overlap (crashes 1,278, persons 4,221, vehicles 2,470) | todo |
| 10 | Verify each Dev `nyc_*` table: `count = countDistinct(key)`; counts moved only by genuinely new keys | CC | Three checks pass; results recorded here | todo |
