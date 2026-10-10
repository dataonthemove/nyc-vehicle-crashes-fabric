# 04: Vehicle Model Year cleansing and vehicle rebuild (Dev)

**What to build:** In Dev, `Dim Vehicle`[Vehicle Model Year] is NULL unless it lies between 1900 and the crash year + 1, so a Model Year slicer starts and ends sensibly and vehicle age is never negative. Classic vehicles (1900–1979) are kept. The crash year comes from the same source vehicle row's crash date. The identical expression is used in the dimension load and in the fact's vehicle-key lookup, so the inner join drops no vehicle row. Because `dim_vehicle` is keyed on its whole attribute set, the dimension and fact are rebuilt rather than patched; `vehicle_key` values are regenerated (accepted: hidden, relationship-only). Fact row counts are unchanged. Spec issue 4.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Add the cleansing expression to stored procedure `etl.usp_load_dim_vehicle` in **both** copies (authoring notebook and Warehouse item definition) (`/warehouse-dml`) | CC | Both copies carry the expression | todo |
| 2 | Use the identical expression in the `dim_vehicle` lookup of stored procedure `etl.usp_load_fact_crash_vehicle`, in **both** copies. Mark both procedures with an "identical in …" comment, as the factor-set hash comment does | CC | The four copies carry the identical expression and comments | todo |
| 3 | Update docs: the markdown headers of both transform notebooks and the model documentation's Vehicle Model Year rule | CC | All read correctly | todo |
| 4 | Commit all procedure copies and docs together (`CC Commit: etl_vehicle_modelyear-cleansing`) | CC | One commit contains all four procedure copies | todo |
| 5 | Push to ADO, then run Source Control → Update All in Dev | Pat | Source Control pane shows Dev in sync | todo |
| 6 | Capture Dev pre-drop counts (`/dax-smoke-test` check 1) for `fact_crash_vehicle` and the other facts | CC | Counts recorded in Comments | todo |
| 7 | Empty `dim_vehicle` and `fact_crash_vehicle` in Dev (script supplied by CC) | Pat | Both tables report 0 rows | todo |
| 8 | Run the stage load pipeline in Dev; then `refresh_semantic_model` (rerun the refresh, not the pipeline, on a parquet 404) | CC | Pipeline succeeds; refresh completes | todo |
| 9 | DAX: no vehicle with a model year below 1900 or above its crash year + 1; `fact_crash_vehicle` count equals the pre-drop count (explain any CDC-driven rise) | CC | Both hold | todo |
| 10 | Run the full `/dax-smoke-test` on Dev | CC | Checks 1–6 pass | todo |
