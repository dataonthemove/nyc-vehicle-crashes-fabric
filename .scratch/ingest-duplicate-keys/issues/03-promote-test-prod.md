# 03: Promote nb_cdc_to_delta to Test and Prod

**What to build:** Stage loads in Test and Prod succeed again, with one row per key in every `nyc_*`
table. Only the notebook is deployed through `dp_NYC_VehicleCrashes`; the Warehouse is excluded,
because deploying it can wipe tables.

**Blocked by:** 01

**Status:** done (2026-10-11)

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Record pre-deploy `nyc_*` row counts in Test via Spark | CC | Three counts recorded here | done |
| 2 | Deploy Dev → Test, selecting `nb_cdc_to_delta` only | Pat | Deployment succeeds; Warehouse not in the deployment | done |
| 3 | Run `pl_stage_load_NYC_Crashes` in Test | CC | All activities succeed | done |
| 4 | Verify Test `nyc_*` tables: `count = countDistinct(key)`; counts moved only by new keys | CC | Three checks pass; recorded here | done |
| 5 | Record pre-deploy `nyc_*` row counts in Prod via Spark | CC | Three counts recorded here | done |
| 6 | Deploy Test → Prod, selecting `nb_cdc_to_delta` only | Pat | Deployment succeeds; Warehouse not in the deployment | done |
| 7 | Run `pl_stage_load_NYC_Crashes` in Prod | CC | All activities succeed | done |
| 8 | Verify Prod `nyc_*` tables as in step 4 | CC | Three checks pass; recorded here | done |

## Comments

- **2026-10-11, step 1** — Pre-deploy Test counts (`count` = `countDistinct(key)` for all three):
  `nyc_crashes` 2,269,187 · `nyc_persons` 5,984,110 · `nyc_vehicles` 4,551,002 — identical to Dev.
- **2026-10-11, step 2** — Pat deployed Dev → Test, notebook only. Live Test `nb_cdc_to_delta`
  carries the `_rank`/`_file_modified` de-dup step.
- **2026-10-11, step 3** — Test pipeline run `b4ac241f-033d-4e5a-8bed-225b41262d32`: all 16
  activities succeeded, Refresh included.
- **2026-10-11, step 4** — Post-run Test counts: crashes 2,269,187, persons 5,984,110, vehicles
  4,551,002; `count = countDistinct(key)` for all three; 0 change from step 1. Landing is now
  baseline-only (issue 02), so no new keys were expected.
- **2026-10-11, step 5** — Pre-deploy Prod counts (`count` = `countDistinct(key)` for all three):
  `nyc_crashes` 2,269,187 · `nyc_persons` 5,984,110 · `nyc_vehicles` 4,551,002 — identical to Test.
- **2026-10-11, step 6** — Pat deployed Test → Prod, notebook only. Live Prod `nb_cdc_to_delta`
  matches Test except the default-lakehouse binding (autobind to the Prod lakehouse).
- **2026-10-11, step 7** — Prod pipeline run `2fef07da-498f-406c-8eea-389c5cbaeef9`: all 16
  activities succeeded, Refresh included.
- **2026-10-11, step 8** — Post-run Prod counts: crashes 2,269,187, persons 5,984,110, vehicles
  4,551,002; `count = countDistinct(key)` for all three; 0 change from step 5.
