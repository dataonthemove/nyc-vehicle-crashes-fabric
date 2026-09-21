# 02: Full Ingest — persons and vehicles in parallel

**What to build:** The Ingest phase covers all three raw sources. Persons and vehicles run in parallel with crashes, each merging on `unique_id`. The Transform phase starts only after all three succeed.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Three Ingest activities run in parallel, with the correct `source_name`, `file_subfolder` and `natural_key` each
- [ ] Downstream Transform waits on success of all three
- [ ] After a run, each `nyc_*` Delta row count equals the Spark count of distinct merge keys across the landed files for that source
- [ ] No NULL merge keys; the notebook's own guard did not fire
