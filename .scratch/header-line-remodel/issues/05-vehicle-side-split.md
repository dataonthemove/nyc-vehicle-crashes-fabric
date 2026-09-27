# 05: Vehicle-side split: dim_driver, vehicle circumstance, drop vehicle_model

**What to build:** Vehicles, their drivers and the vehicle's **circumstances** in a crash are separate dimensions on `fact_crash_vehicle`, and `dim_vehicle` shrinks (D6, D7, D9, D16).

**Blocked by:** 04

**Status:** done

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [x] New `dim_driver` (`driver_sex`, `driver_license_status`, `driver_license_jurisdiction`) with its own load notebook and procedure; `fact_crash_vehicle` gains `driver_key`
- [x] `dim_damage` renamed `dim_vehicle_circumstance` (`damage_key` → `vehicle_circumstance_key`) across DDL, item definition, notebook, procedure, pipeline activity and semantic model
- [x] `travel_direction` moves from `dim_vehicle` to `dim_vehicle_circumstance`; `vehicle_model` and the driver columns are dropped from `dim_vehicle`
- [x] Pipeline: driver load added; `fact_crash_vehicle` waits on `dim_vehicle`, `dim_vehicle_circumstance`, `dim_driver` and `fact_crashes`
- [x] Semantic model: `dim_driver` table and relationship added; `driver_key` SummarizeBy `None`
- [x] Notebook and item-definition procedures identical, same commit

## Comments
- 2026-09-27 (CC): Implemented, unsynced (Update All held until 07). New notebook `07b_ETL_dim_driver` (new logicalId); `08_ETL_dim_damage` renamed in place to `08_ETL_dim_vehicle_circumstance` (logicalId kept, so Fabric renames the item rather than recreating it). `dim_vehicle` = `vehicle_type`, `vehicle_make`, `vehicle_year`, `state_registration`. `fact_crash_vehicle` resolves `vehicle_key`, `vehicle_circumstance_key`, `driver_key` by NULL-safe INNER JOIN on each dim's full attribute set. Pipeline: `Load_dim_damage` → `Load_dim_vehicle_circumstance`; `Load_dim_driver` waits on the three ingests. TMDL: `dim_damage` table/column/relationship renamed keeping lineage tags; `travel_direction`, `dim_driver` and `driver_key` added without lineage tags (Fabric injects). DDL `01` drop cell also drops legacy `dim_damage`. Procs identical notebook vs item definition.
- **For 07:** Risks step 3 must drop stale `etl.usp_load_dim_damage` in each stage. Add to validation: `dim_driver` has no duplicate attribute combinations; `fact_crash_vehicle` row count unchanged vs pre-drop (any shortfall means a driver/circumstance join miss); orphan check covers `driver_key` and `vehicle_circumstance_key`. `Context/environment-reference.md` and `SEMANTIC_MODEL.md` still name `dim_damage` — ticket 10.
