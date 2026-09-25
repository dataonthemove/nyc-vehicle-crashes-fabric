# 02: Full Ingest — persons and vehicles in parallel

**What to build:** The Ingest phase covers all three raw sources. Persons and vehicles run in parallel with crashes, each merging on `unique_id`. The Transform phase starts only after all three succeed.

**Blocked by:** 01

**Status:** done (2026-09-22)

- [x] Three Ingest activities run in parallel, with the correct `source_name`, `file_subfolder` and `natural_key` each
- [x] Downstream Transform waits on success of all three
- [x] After a run, each `nyc_*` Delta row count equals the Spark count of distinct merge keys across the landed files for that source
- [x] No NULL merge keys; the notebook's own guard did not fire

## Outcome (2026-09-22)

Commit `b84f95c`. The Fabric Update hit conflicts, which were resolved in favour of Git. A check afterwards
confirmed the live pipeline graph and the `nb_cdc_to_delta` code/parameter tag match the repo.

Run `059071b5-64f3-45a9-b0ec-089b6abf4fa7` Succeeded 23:02:55 → 23:06:20 UTC. All three Ingest
activities started 23:03:03: Crashes 89 s, Vehicles 122 s, Persons 136 s. After that,
Load_dim_collision ran for 17 s from 23:05:21, which was after the last Ingest finished. Refresh_Semantic_Model ran last, taking 39 s.

| Source | Landed rows | Distinct keys | NULL / dup keys | Delta rows after run | Delta last op |
|---|---|---|---|---|---|
| crashes (`collision_id`) | 2,269,187 | 2,269,187 | 0 / 0 | 2,269,187 | MERGE 23:04:21 |
| persons (`unique_id`) | 5,984,110 | 5,984,110 | 0 / 0 | 5,984,110 | MERGE 23:05:04 |
| vehicles (`unique_id`) | 4,551,002 | 4,551,002 | 0 / 0 | 4,551,002 | MERGE 23:04:56 |

The landed files have no duplicate keys, so a re-read of every file merges cleanly. There is no
"multiple source rows matched" risk while that holds.
