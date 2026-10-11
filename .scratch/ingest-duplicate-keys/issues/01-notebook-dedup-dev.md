# 01: De-duplicate in nb_cdc_to_delta, proven in Dev

**What to build:** A Dev stage load succeeds against today's landing files, which repeat keys across
the 2026-09-10 full extract and the CDC run `8552e9f4` file. Fabric Notebook `nb_cdc_to_delta` keeps
one row per natural key, from the newest file by modification time (tie-break: source file path,
descending), on both the MERGE and the first-run write paths, and prints how many duplicate rows it
dropped. Parameters, exit values, target tables and columns are unchanged. Notebook comments and the
ingestion doc stop claiming de-duplication that did not exist.

**Blocked by:** None (can start immediately)

**Status:** done (2026-10-11)

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Pull current Dev state via MCP: notebook definition matches git; last stage-load run failed as described | CC | Live definition diffs clean against the repo (ignoring logical IDs) | done |
| 2 | Confirm Spark file `_metadata.file_modification_time` is available on the Dev runtime over Livy | CC | A Livy read of the crashes folder returns one modification time per file; else fallback chosen and noted here | done |
| 3 | Re-check the 17 reported within-file crash duplicates with a `multiLine` read | CC | Real within-file duplicate count recorded here (expected 0 if the figure was a split-read artefact) | done |
| 4 | Add the de-dup step between the audit columns and the write; drop the ranking column; print dropped-row count | CC | Notebook file edited in Fabric's compact formatting, no spurious diffs | done |
| 5 | Update notebook cell 1 and cell 6 comments, and the duplicates claim in `docs/socrata-ingestion.md` | CC | No comment or doc says the MERGE alone handles repeated keys | done |
| 6 | Commit locally (`CC Commit: dev_nb_cdc_to_delta_dedup-newest-per-key`) | CC | Commit exists on main, CRLF intact | done |
| 7 | Push; Dev Source Control → Update All | Pat | Dev Source Control shows no pending incoming changes | done |
| 8 | Record pre-run `nyc_*` row counts in Dev via Spark | CC | Three counts recorded here | done |
| 9 | Run `pl_stage_load_NYC_Crashes` in Dev; rerun `refresh_semantic_model` if the Refresh activity hits the framing race | CC | All activities succeed; printed drop counts roughly match the overlap (crashes 1,278, persons 4,221, vehicles 2,470) | done |
| 10 | Verify each Dev `nyc_*` table: `count = countDistinct(key)`; counts moved only by genuinely new keys | CC | Three checks pass; results recorded here | done |

## Comments

- **2026-10-11, step 1** — Live Dev `nb_cdc_to_delta` cells match the repo (trailing blank lines
  only). Run `c829db17` failed in all three Ingest activities with
  `DELTA_MULTIPLE_SOURCE_ROW_MATCHING_TARGET_ROW_IN_MERGE`.
- **2026-10-11, step 2** — `_metadata.file_modification_time` resolves on Dev runtime 1.3
  (Spark 3.5.5) even after cell 4's `select`; no fallback needed. Crashes: full extract
  `18d27ca4…` 2026-09-10 11:57:00, run file `8552e9f4….csv` 2026-10-02 02:00:18. Header-only
  files contribute no rows. `input_file_name()` carries a `?version=…?flength=…` suffix; harmless
  for the tie-break.
- **2026-10-11, step 3** — `multiLine` read: **0** within-file duplicate `collision_id`. The 17 were
  a split-read artefact. Crashes files hold 2,270,465 rows, 2,269,187 distinct → 1,278 to drop.
- **2026-10-11, step 8** — Pre-run Dev counts (`count` = `countDistinct(key)` for all three):
  `nyc_crashes` 2,269,187 · `nyc_persons` 5,984,110 · `nyc_vehicles` 4,551,002.
- **2026-10-11, pre-commit dry-run** — Edited cell 5 run over Livy on vehicles (no write): dropped
  2,470, kept 4,551,002, table columns unchanged (`_file_modified`/`_rank` dropped). Post-dedup distinct 4,551,002;
  kept rows by file: full extract 4,548,532, run `8552e9f4` file 2,470 — the newer file wins.
  `/code-review` (low) on the commit: no findings.
- **2026-10-11, step 7** — Pat pushed `1c4be75` and ran Update All; live Dev notebook carries the de-dup.
- **2026-10-11, step 9** — Pipeline run `37e2f135-1199-4cb4-960f-e1468b264037`: all 16 activities
  succeeded, Refresh included (no framing race). Printed drops: crashes 1,278 (staged 2,270,465),
  persons 4,221 (staged 5,988,331), vehicles 2,470 (staged 4,553,472) — exactly the expected overlap.
- **2026-10-11, step 10** — Dev `nyc_*` after the run: crashes 2,269,187, persons 5,984,110,
  vehicles 4,551,002; `count = countDistinct(key)` for all three; 0 change from pre-run, as expected
  (every overlap key was already in the full extract). `_source_file` now spans both files per
  table, so the overlap rows were rewritten from the newer run file.
