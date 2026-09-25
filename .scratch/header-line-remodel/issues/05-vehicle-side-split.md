# 05: Vehicle-side split: dim_driver, vehicle circumstance, drop vehicle_model

**What to build:** Vehicles, their drivers and the vehicle's **circumstances** in a crash are separate dimensions on `fact_crash_vehicle`, and `dim_vehicle` shrinks (D6, D7, D9, D16).

**Blocked by:** 04

**Status:** ready-for-agent

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [ ] New `dim_driver` (`driver_sex`, `driver_license_status`, `driver_license_jurisdiction`) with its own load notebook and procedure; `fact_crash_vehicle` gains `driver_key`
- [ ] `dim_damage` renamed `dim_vehicle_circumstance` (`damage_key` → `vehicle_circumstance_key`) across DDL, item definition, notebook, procedure, pipeline activity and semantic model
- [ ] `travel_direction` moves from `dim_vehicle` to `dim_vehicle_circumstance`; `vehicle_model` and the driver columns are dropped from `dim_vehicle`
- [ ] Pipeline: driver load added; `fact_crash_vehicle` waits on `dim_vehicle`, `dim_vehicle_circumstance`, `dim_driver` and `fact_crashes`
- [ ] Semantic model: `dim_driver` table and relationship added; `driver_key` SummarizeBy `None`
- [ ] Notebook and item-definition procedures identical, same commit

## Comments
