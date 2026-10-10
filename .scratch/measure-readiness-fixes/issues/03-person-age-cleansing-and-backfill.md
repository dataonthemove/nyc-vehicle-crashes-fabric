# 03: Person Age cleansing and backfill (Dev)

**What to build:** In Dev, `Fact Crash Persons`[Person Age] holds only plausible ages, so the default `Average` and any age band are believable. A value becomes NULL (unknown) when it is below 0 or above 110. A 0 also becomes NULL, unless the person's role is `Passenger` or `Pedestrian`, the only roles where a real infant is plausible. New loads apply the rule in the fact load procedure. Rows already loaded are corrected by a one-time, idempotent backfill, because the incremental load never revisits them. Spec issue 3.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Baseline on Dev: `fact_persons` row count, blank Person Age count, min/max age, zero ages by Person Role; compute the expected NULL increase (negatives + above 110 + non-infant zeros, ~535k) | CC | Baseline and expected increase recorded in Comments | todo |
| 2 | Add the cleansing rule to stored procedure `etl.usp_load_fact_persons` in **both** copies: the authoring transform notebook and the Warehouse item definition (`/warehouse-dml`) | CC | Both copies carry an identical expression | todo |
| 3 | Add a run-once, idempotent backfill `UPDATE` cell to the fact-persons transform notebook, joining `dim_person` for the role; follow the occupancy backfill cell's pattern. Match Fabric's notebook formatting | CC | The cell exists and is safe to run twice | todo |
| 4 | Update docs: the notebook's markdown header, the model documentation's Person Age rule, and the stale *Occupancy* glossary entry in `CONTEXT.md` (the cap of 100 has existed since 2026-08) | CC | All three read correctly | todo |
| 5 | Commit procedure copies, backfill cell and docs together (`CC Commit: etl_factpersons_age-cleansing`) | CC | One commit contains both procedure copies | todo |
| 6 | Push to ADO, then run Source Control → Update All in Dev | Pat | Source Control pane shows Dev in sync | todo |
| 7 | Run the backfill cell in the Dev Warehouse SQL editor (script supplied by CC) | Pat | The update completes; Pat reports rows affected | todo |
| 8 | Run `refresh_semantic_model` on Dev | CC | Refresh completes | todo |
| 9 | DAX: min Person Age ≥ 0 and max ≤ 110; no zero ages outside `Passenger`/`Pedestrian`; `fact_persons` row count unchanged; blank count rose by the expected amount | CC | All four hold | todo |
