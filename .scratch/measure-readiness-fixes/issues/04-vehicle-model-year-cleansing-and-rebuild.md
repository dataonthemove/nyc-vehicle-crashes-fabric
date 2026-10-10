# 04: Vehicle Model Year cleansing and vehicle rebuild (Dev)

**What to build:** In Dev, `Dim Vehicle`[Vehicle Model Year] is NULL unless it lies between 1900 and the crash year + 1, so a Model Year slicer starts and ends sensibly and vehicle age is never negative. Classic vehicles (1900–1979) are kept. The crash year comes from the same source vehicle row's crash date. The identical expression is used in the dimension load and in the fact's vehicle-key lookup, so the inner join drops no vehicle row. Because `dim_vehicle` is keyed on its whole attribute set, the dimension and fact are rebuilt rather than patched; `vehicle_key` values are regenerated (accepted: hidden, relationship-only). Fact row counts are unchanged. Spec issue 4.

**Blocked by:** None (can start immediately)

**Status:** closed

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Add the cleansing expression to stored procedure `etl.usp_load_dim_vehicle` in **both** copies (authoring notebook and Warehouse item definition) (`/warehouse-dml`) | CC | Both copies carry the expression | done |
| 2 | Use the identical expression in the `dim_vehicle` lookup of stored procedure `etl.usp_load_fact_crash_vehicle`, in **both** copies. Mark both procedures with an "identical in …" comment, as the factor-set hash comment does | CC | The four copies carry the identical expression and comments | done |
| 3 | Update docs: the markdown headers of both transform notebooks and the model documentation's Vehicle Model Year rule | CC | All read correctly | done |
| 4 | Commit all procedure copies and docs together (`CC Commit: etl_vehicle_modelyear-cleansing`) | CC | One commit contains all four procedure copies | done |
| 5 | Push to ADO, then run Source Control → Update All in Dev | Pat | Source Control pane shows Dev in sync | done |
| 6 | Capture Dev pre-drop counts (`/dax-smoke-test` check 1) for `fact_crash_vehicle` and the other facts | CC | Counts recorded in Comments | done |
| 7 | Empty `dim_vehicle` and `fact_crash_vehicle` in Dev (script supplied by CC) | Pat | Both tables report 0 rows | done |
| 8 | Run the stage load pipeline in Dev; then `refresh_semantic_model` (rerun the refresh, not the pipeline, on a parquet 404) | CC | Pipeline succeeds; refresh completes | done |
| 9 | DAX: no vehicle with a model year below 1900 or above its crash year + 1; `fact_crash_vehicle` count equals the pre-drop count (explain any CDC-driven rise) | CC | Both hold | done |
| 10 | Run the full `/dax-smoke-test` on Dev | CC | Checks 1–6 pass | done |

## Comments

- **2026-10-10 — Steps 1–4.** Expression, identical in all four procedure copies (SELECT, NOT EXISTS and
  the fact's `dim_vehicle` join): `CASE WHEN TRY_CAST(src.vehicle_year AS SMALLINT) BETWEEN 1900 AND
  YEAR(TRY_CAST(src.crash_date AS DATE)) + 1 THEN TRY_CAST(src.vehicle_year AS SMALLINT) END`.
  Code review (standards + spec): no findings.
- **2026-10-10 ~20:10 UTC — Step 6 pre-drop counts (Dev, Spark).** `fact_crashes` 2,269,187;
  `fact_persons` 5,984,110; `fact_crash_vehicle` 4,551,002; `dim_vehicle` 155,594; Lakehouse
  `nyc_vehicles` 4,551,002. Source year bands match the spec exactly (<1900 3 · 1900–1979 1,019 ·
  1980..crash year+1 2,565,151 · crash year+2..2100 1,196 · >2100 1,728 · blank 1,981,905).
- **2026-10-10 — Dry run of the expression in the Dev Warehouse (T-SQL via synapsesql).** `crash_date`
  (text, `2012-07-01T00:00:00.000`) converts for all 4,551,002 rows; 2,927 non-blank years become NULL.
  **Expected after rebuild:** `dim_vehicle` 154,057 rows (−1,537); `fact_crash_vehicle` 4,551,002.
- **2026-10-10 — Step 8 (deviation).** Stage load pipeline run `c829db17-…` failed in all three Ingest
  activities (`DELTA_MULTIPLE_SOURCE_ROW_MATCHING_TARGET_ROW_IN_MERGE`), before any procedure ran —
  unrelated to this issue; logged as `.scratch/ingest-duplicate-keys/issue.md`. Lakehouse `nyc_vehicles`
  is unchanged since 2026-09-29, so Pat ran `EXEC etl.usp_load_dim_vehicle; EXEC
  etl.usp_load_fact_crash_vehicle;` in the Dev Warehouse SQL editor: `dim_vehicle` 154,057,
  `fact_crash_vehicle` 4,551,002 — both exactly as predicted. `refresh_semantic_model` Completed
  (refresh 459793042). Deployed procedure definitions verified via `sys.sql_modules` beforehand.
- **2026-10-10 — Steps 9–10 (Dev).** DAX: Vehicle Model Year min 1900, max 2027; vehicles below 1900: 0;
  above crash year + 1: 0; blank-year vehicles 1,984,832 (= 1,981,905 + 2,927); classic 1900–1979 kept
  (1,019); `fact_crash_vehicle` 4,551,002 = pre-drop (no CDC rise — ingest did not run).
  `/dax-smoke-test`: Spark checks 1–4 43/43 PASS (incl. added `dim_vehicle` duplicate-attribute-set
  check); DAX check 1 counts match; check 5 PASS (63 factors, 0 failing); check 6 PASS (0 missing,
  0 extra, `ri_off` 0).
