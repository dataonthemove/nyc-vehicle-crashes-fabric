# Semantic Model — NYC_VehicleCrashes_Semantic

![Semantic model diagram](img/SemanticModel.png)

> The diagram predates the 2026-09-27 header/line remodel. It still shows `dim_collision`,
> `dim_damage` and the measures. The tables below describe the model as built.

## Overview

Fabric semantic model `NYC_VehicleCrashes_Semantic`, in **Direct Lake on SQL** storage mode over
Fabric Warehouse `NYC_VehicleCrashes_Warehouse`. It exposes the NYC Motor Vehicle Collisions data
as a Kimball header/line star schema. It has one header fact at crash grain and two line facts, and
every header key is copied onto the lines. It also has one bridge table for the many-to-many
contributing-factor relationship. Design decisions: `docs/adr/0005-header-line-fact-design.md`.
The model is built identically in Dev, Test and Prod.

The `definition/` TMDL under repo folder
`2_dev/4_Model/NYC_VehicleCrashes_Semantic.SemanticModel/` is the authoritative source. The model
is authored locally, pushed to ADO, then pulled into the workspace via Fabric Source Control.

## Tables

| Table | Role | Grain | Notes |
|---|---|---|---|
| `fact_crashes` | Header fact | One crash | `collision_id` (degenerate dimension); `latitude` / `longitude`; additive casualty columns (persons / pedestrians / cyclists / motorists, injured & killed) |
| `fact_crash_vehicle` | Line fact | One vehicle in a crash | Header keys `date_key`, `location_key`, `factor_group_key` and `collision_id` copied from its crash; `vehicle_occupants` is BLANK when unreported, not 0 |
| `fact_persons` | Line fact | One person in a crash | Header keys copied from its crash, as above; `is_injured` / `is_killed` flags, `person_age` |
| `bridge_crash_factor` | Bridge | One factor group × factor pair | Resolves the many-to-many between a crash's factor set and its contributing factors |
| `dim_date` | Dimension | One calendar day | Marked date table on `full_date`; year / quarter / month / day / day_name / is_weekend |
| `dim_location` | Dimension | One borough / zip code | `borough`, `zip_code`; one **Unknown** member (`borough` and `zip_code` = `UNKNOWN`) for crashes with no location |
| `dim_factor_group` | Dimension | One distinct set of contributing factors | `factor_set_hash` (hidden) identifies the set; one empty-set group, with no bridge rows, covers crashes with no specified factor |
| `dim_contributing_factor` | Dimension | One contributing factor | `factor_desc` |
| `dim_vehicle` | Dimension | One vehicle profile | `vehicle_type`, `vehicle_make`, `vehicle_year`, `state_registration` |
| `dim_vehicle_circumstance` | Dimension | One vehicle-in-crash profile | `pre_crash`, `travel_direction`, `point_of_impact`, `vehicle_damage` (renamed from `dim_damage`) |
| `dim_driver` | Dimension | One driver profile | `driver_sex`, `driver_license_status`, `driver_license_jurisdiction` (moved out of `dim_vehicle`) |
| `dim_person` | Dimension | One person profile | person_type, sex, ejection, emotional status, bodily injury, position in vehicle, safety equipment, pedestrian location/action/role |

There is no collision dimension. `collision_id` sits on all three facts as a degenerate dimension.
`dbo.etl_watermark` is excluded (an ETL control table, not analytic content).

## Relationships

Fifteen single-column relationships, one-to-many from dimension to fact (or bridge), with
single-direction filtering except for one deliberate exception:

- `bridge_crash_factor[factor_group_key] → dim_factor_group[factor_group_key]` is
  **bothDirections**. Without it, filtering by contributing factor silently returns the full
  crash count instead of the filtered subset.
- **Header dimensions reach every fact.** `dim_date`, `dim_location` and `dim_factor_group` each
  join all three facts, so a date, borough or contributing factor filters crash-, vehicle- and
  person-grain rows alike. `dim_contributing_factor` reaches the facts through the bridge and
  `dim_factor_group`.
- **Line dimensions reach only their own fact.** `fact_crash_vehicle` also joins `dim_vehicle`,
  `dim_vehicle_circumstance` and `dim_driver`. `fact_persons` also joins `dim_person`.
- Lines do not filter the header: a vehicle or person attribute does not filter `fact_crashes`.
  That is deferred (`.scratch/Backlog/line-to-header-filtering/`).

| Dimension | `fact_crashes` | `fact_crash_vehicle` | `fact_persons` | `bridge_crash_factor` |
|---|---|---|---|---|
| `dim_date` | ✓ | ✓ | ✓ | |
| `dim_location` | ✓ | ✓ | ✓ | |
| `dim_factor_group` | ✓ | ✓ | ✓ | ✓ (bothDirections) |
| `dim_contributing_factor` | | | | ✓ |
| `dim_vehicle` / `dim_vehicle_circumstance` / `dim_driver` | | ✓ | | |
| `dim_person` | | | ✓ | |

## Measures

**None.** All measures were removed on 2026-09-27. They will be regenerated from this model in a
separate spec, and the reports will be rebuilt after that. Until then, validate with `COUNTROWS`
and key DAX queries (`/dax-smoke-test`).

There are no security roles either: `Borough_Reader` was deleted because it leaked into the line
facts. Security roles are deferred.

## Conventions

- **SummarizeBy:** all `_key` and `_id` columns (including `collision_id`) → `None`; numeric
  dimension attributes (year, quarter, month, day, day_of_week, vehicle_year) → `None`;
  `latitude` / `longitude` → `None`, with `dataCategory` Latitude / Longitude; `person_age` →
  `Average`; `vehicle_occupants` → `Sum`. A schema refresh resets these to `Sum`, so re-apply them
  after any refresh.
- **Authoring path:** local TMDL edits → commit/push to ADO → Fabric Source Control → Update All.
  Do not author this model through XMLA/MCP; those writes hit workspace state and bypass Git.
