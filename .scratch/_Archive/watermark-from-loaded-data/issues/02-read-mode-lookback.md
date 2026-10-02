# 02: 7-day lookback in read mode

**What to build:** Read mode of `nb_etl_watermark` returns each watermark minus `lookback_days`, a new
parameter with default 7. The JSON shape and the `yyyy-MM-ddTHH:mm:ss` format stay the same as today,
so the three Copy query expressions in `pl_cdc_NYC_Crashes_Landing` need no change. The stored value
in `etl_watermark` is never adjusted. A seed watermark (1900-01-01) passes through without the
subtraction. The effect: each **CDC run** re-queries the last week before the watermark, picking up
late-published crashes, including same-day ones. Downstream already de-duplicates the overlap
(`nb_cdc_to_delta` MERGE on the natural key; `usp_load_fact_*` insert only absent keys).

Parent spec: `.scratch/watermark-from-loaded-data/spec.md`

**Blocked by:** 01 (same notebook)

**Status:** resolved (2026-10-01)

| Step | Description | Owner | Status |
|---|---|---|---|
| 1 | Add `lookback_days` to the parameters cell; apply it to the read-mode payload only; seed values pass through | CC | done |
| 2 | Update the comments in cells 1 and 6 to explain the lookback and why the stored value is unadjusted | CC | done |
| 3 | Commit locally (`CC Commit: landing_nb_etl_watermark_read-lookback`) | CC | done |
| 4 | Push; landing Source Control → Update All | Pat | done |
| 5 | Run the read-mode tests; read `etl_watermark` over Livy | CC | done |
| 6 | Restore crashes watermark to its pre-test value via explicit `new_value` | CC | done |

- [x] With crashes set to 2026-07-01, read mode's exit value has `crashes` = `2026-06-24T00:00:00`
- [x] `etl_watermark` still holds 2026-07-01 for crashes after the read
- [x] `lookback_days = 0` returns the stored value unchanged
- [x] A 1900-01-01 watermark is returned as `1900-01-01T00:00:00`
- [x] Exit-value JSON keys and format are unchanged (crashes, persons, vehicles; `yyyy-MM-ddTHH:mm:ss`)

Test note: `notebookutils.notebook.run` fails from a Livy session ("No kernel id and run id"), so the
read-mode exit value was taken from the `NotebookExit:` line in the on-demand job's driver stdout
(`get_notebook_driver_logs`).
