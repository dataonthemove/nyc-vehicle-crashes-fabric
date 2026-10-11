# 03: Promote nb_cdc_to_delta to Test and Prod

**What to build:** Stage loads in Test and Prod succeed again, with one row per key in every `nyc_*`
table. Only the notebook is deployed through `dp_NYC_VehicleCrashes`; the Warehouse is excluded,
because deploying it can wipe tables.

**Blocked by:** 01

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Record pre-deploy `nyc_*` row counts in Test via Spark | CC | Three counts recorded here | todo |
| 2 | Deploy Dev → Test, selecting `nb_cdc_to_delta` only | Pat | Deployment succeeds; Warehouse not in the deployment | todo |
| 3 | Run `pl_stage_load_NYC_Crashes` in Test | CC | All activities succeed | todo |
| 4 | Verify Test `nyc_*` tables: `count = countDistinct(key)`; counts moved only by new keys | CC | Three checks pass; recorded here | todo |
| 5 | Record pre-deploy `nyc_*` row counts in Prod via Spark | CC | Three counts recorded here | todo |
| 6 | Deploy Test → Prod, selecting `nb_cdc_to_delta` only | Pat | Deployment succeeds; Warehouse not in the deployment | todo |
| 7 | Run `pl_stage_load_NYC_Crashes` in Prod | CC | All activities succeed | todo |
| 8 | Verify Prod `nyc_*` tables as in step 4 | CC | Three checks pass; recorded here | todo |
