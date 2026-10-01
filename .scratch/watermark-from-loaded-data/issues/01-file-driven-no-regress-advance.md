# 01: File-driven, no-regress advance in nb_etl_watermark

**What to build:** Advance mode of Fabric Notebook `nb_etl_watermark` sets a source's **Watermark** from the
data actually landed, not from the time the pipeline ran. It gets a new parameter, `loaded_file`: the
path of one landed file, relative to the landing lakehouse `Files/`. The notebook reads that file and
takes its newest `crash_date`, parsed as a timestamp. It stores the later of that date and the current
watermark. A header-only file leaves `last_loaded_value` unchanged but still stamps `last_run_utc`.
`new_value` stays as a manual override that sets the value exactly and may move it backwards. If both
parameters are set, `loaded_file` is used. If neither is set, the run fails. The pipeline still passes
`new_value = utcnow()` until ticket 03, so CDC runs keep working unchanged in the meantime.

Parent spec: `.scratch/watermark-from-loaded-data/spec.md`

**Blocked by:** None (can start immediately)

**Status:** in-progress (CC code steps done; awaiting Pat steps 1 and 5)

| Step | Description | Owner | Status |
|---|---|---|---|
| 1 | Reactivate the pipeline activities deactivated on 2026-10-01, or discard via landing Source Control → Update All; confirm landing SC shows nothing pending | Pat | todo |
| 2 | Add `loaded_file` to the parameters cell; implement file-driven, no-regress advance; keep explicit `new_value` override; fail when neither is set | CC | done |
| 3 | Update cell comments for the new advance logic, in the same plain-language style as the existing comments | CC | done |
| 4 | Commit locally (`CC Commit: landing_nb_etl_watermark_advance-from-file`) | CC | done |
| 5 | Push; landing Source Control → Update All | Pat | todo |
| 6 | Run seam-1 tests on crashes (MCP on-demand job with parameters, or Fabric UI); read `etl_watermark` over Livy after each | CC | todo |
| 7 | Restore crashes watermark to its pre-test value (2026-09-10T13:04:16) via explicit `new_value` | CC | todo |

- [ ] Explicit `new_value = 2026-06-01T00:00:00` → crashes watermark is 2026-06-01
- [ ] Advance with the 9/10 full-history crashes file → watermark is 2026-06-11
- [ ] Advance with a header-only crashes file → watermark still 2026-06-11; `last_run_utc` changed
- [ ] Explicit `new_value = 2026-07-01T00:00:00`, then advance with the full-history file → still 2026-07-01 (no regression)
- [ ] Advance with neither `loaded_file` nor `new_value` → the run fails and the table is unchanged
- [ ] Persons and vehicles rows are untouched by every crashes test
- [ ] Notebook code and comments match Fabric's compact formatting (no spurious round-trip diff after Update All)
