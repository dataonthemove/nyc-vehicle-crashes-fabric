# 03: Pipeline passes the landed file to the Advance steps

**What to build:** In Fabric Pipeline `pl_cdc_NYC_Crashes_Landing`, each `Copy_*_CDC` sink writes a
file named from the pipeline run ID with a `.csv` extension, in its existing `raw/<source>` folder.
Each `Advance_Watermark_*` notebook activity passes that same path as `loaded_file` and stops passing
`new_value`. The pipeline's `.platform` description is corrected: the watermark is read and advanced by
`nb_etl_watermark`, not read from the SQL endpoint. After this ticket a **CDC run** advances each
watermark from the data it actually landed. `nb_cdc_to_delta` reads `*` per folder, so no stage-side
change is needed.

Parent spec: `.scratch/watermark-from-loaded-data/spec.md`

**Blocked by:** 01 (the notebook must accept `loaded_file` first)

**Status:** claimed (CC steps 1–3 done 2026-10-01; awaiting push + CDC run)

| Step | Description | Owner | Status |
|---|---|---|---|
| 1 | Edit the pipeline definition locally: run-ID file name on the three Copy sinks; `loaded_file` replaces `new_value` on the three Advance activities | CC | done |
| 2 | Correct the pipeline's `.platform` description | CC | done |
| 3 | Commit locally (`CC Commit: landing_pl_cdc_advance-from-landed-file`) | CC | done |
| 4 | Push; landing Source Control → Update All; confirm pipeline opens without errors | Pat | todo |
| 5 | Run one full CDC run (all activities active) | Pat | todo |
| 6 | Verify landed file names and `etl_watermark` over MCP/Livy; check the Advance activity inputs in the run output | CC | todo |

- [ ] Three new files named `<runId>.csv` land in `Files/raw/{crashes,persons,vehicles}`
- [ ] Each Advance activity's resolved input shows `loaded_file` pointing at its own source's new file
- [ ] Source is still frozen, so the files are header-only, and all three watermarks are unchanged; `last_run_utc` updated
- [ ] Pipeline description no longer mentions reading from the SQL endpoint
- [ ] Landing Source Control shows nothing pending after Update All
