# Naming review — semantic model business-friendly names

Approved: 2026-09-29 (Pat, in session; ❓ items accepted as proposed)

Edit the **Proposed** column in place. Leave a row's Proposed as `—` to keep the current name.
Anything in **Notes** marked ❓ is a judgement call I'd like you to confirm.

## Naming rules

1. Title Case with spaces (`Point of Impact`); short words (`of`, `in`) stay lowercase.
2. Visible tables carry a Title Case prefix, separated by a space: `Dim ` for dimensions, `Fact ` for facts (`Dim Date`, `Fact Crashes`). The prefix tells users which tables filter (Dim) and which aggregate (Fact). The snake_case `dim_` / `fact_` / `bridge_` forms are dropped.
3. Abbreviations are expanded (`desc` → Contributing Factor, `ped` → Pedestrian). Standard acronyms stay upper case (`ZIP`).
4. After the prefix, dimensions are singular nouns (`Dim Vehicle`, `Dim Person`). Facts are plural and named for what one row records (`Fact Crashes`, `Fact Crash Vehicles`).
5. **Hidden columns keep their technical names.** Report authors can't see them, and leaving them unchanged keeps the relationship edits small.
6. **Tables with only hidden columns keep their technical names.** Power BI already drops such a table from the field list, so renaming it gains nothing visible.
7. A column may share its table's name when it *is* the thing the table describes (`Dim Date`[Date], `Dim Contributing Factor`[Contributing Factor]).
8. Booleans read as a question: `Is …`.

## Tables

| # | Current | Proposed | Notes |
|---|---|---|---|
| T1 | `fact_crashes` | Fact Crashes | One row per collision |
| T2 | `fact_crash_vehicle` | Fact Crash Vehicles | One row per vehicle in a collision |
| T3 | `fact_persons` | Fact Crash Persons | One row per person in a collision. ❓ Alternatives: "People Involved", "Crash People". I kept "Persons" to match the NYC Open Data dataset |
| T4 | `dim_date` | Dim Date | |
| T5 | `dim_location` | Dim Location | |
| T6 | `dim_contributing_factor` | Dim Contributing Factor | |
| T7 | `dim_driver` | Dim Driver | |
| T8 | `dim_person` | Dim Person | |
| T9 | `dim_vehicle` | Dim Vehicle | |
| T10 | `dim_vehicle_circumstance` | Dim Vehicle Circumstance | |
| T11 | `dim_factor_group` | — | Rule 6: every column is hidden, so it's already invisible |
| T12 | `bridge_crash_factor` | — | Rule 6: this is the bridge-table decision. It stays technical and invisible |

## Columns (visible — renamed)

| # | Table (current) | Current | Proposed | Type | Notes |
|---|---|---|---|---|---|
| C1 | dim_contributing_factor | `factor_desc` | Contributing Factor | string | Rule 7 |
| C2 | dim_date | `full_date` | Date | dateTime | Rule 7. Marked date-table key column; `///` description kept |
| C3 | dim_date | `year` | Year | int64 | |
| C4 | dim_date | `quarter` | Quarter | int64 | |
| C5 | dim_date | `month` | Month Number | int64 | Frees "Month" for the name column |
| C6 | dim_date | `month_name` | Month | string | ❓ Sorts alphabetically until a sort-by column is added (out of scope) |
| C7 | dim_date | `day` | Day of Month | int64 | |
| C8 | dim_date | `day_of_week` | Day of Week Number | int64 | |
| C9 | dim_date | `day_name` | Day of Week | string | Same alphabetical-sort caveat as C6 |
| C10 | dim_date | `is_weekend` | Is Weekend | boolean | |
| C11 | dim_driver | `driver_sex` | Driver Sex | string | Prefix kept so it can't be confused with Person Sex in visuals |
| C12 | dim_driver | `driver_license_status` | Driver License Status | string | |
| C13 | dim_driver | `driver_license_jurisdiction` | Driver License Jurisdiction | string | |
| C14 | dim_location | `borough` | Borough | string | |
| C15 | dim_location | `zip_code` | ZIP Code | string | |
| C16 | dim_person | `person_type` | Person Type | string | |
| C17 | dim_person | `person_sex` | Person Sex | string | |
| C18 | dim_person | `ejection` | Ejection | string | |
| C19 | dim_person | `emotional_status` | Emotional Status | string | |
| C20 | dim_person | `bodily_injury` | Bodily Injury | string | |
| C21 | dim_person | `position_in_vehicle` | Position in Vehicle | string | |
| C22 | dim_person | `safety_equipment` | Safety Equipment | string | |
| C23 | dim_person | `ped_location` | Pedestrian Location | string | |
| C24 | dim_person | `ped_action` | Pedestrian Action | string | |
| C25 | dim_person | `ped_role` | Person Role | string | ❓ In the NYC source, `ped_role` holds every person's role (Driver, Passenger, Pedestrian…), not only pedestrians'. Hence "Person Role" rather than "Pedestrian Role" |
| C26 | dim_vehicle | `vehicle_type` | Vehicle Type | string | |
| C27 | dim_vehicle | `vehicle_make` | Vehicle Make | string | |
| C28 | dim_vehicle | `vehicle_year` | Vehicle Model Year | int64 | SummarizeBy None stays |
| C29 | dim_vehicle | `state_registration` | Registration State | string | |
| C30 | dim_vehicle_circumstance | `pre_crash` | Pre-Crash Action | string | |
| C31 | dim_vehicle_circumstance | `point_of_impact` | Point of Impact | string | |
| C32 | dim_vehicle_circumstance | `vehicle_damage` | Vehicle Damage | string | |
| C33 | dim_vehicle_circumstance | `travel_direction` | Travel Direction | string | |
| C34 | fact_crash_vehicle | `vehicle_occupants` | Vehicle Occupants | int64 | SummarizeBy Sum stays. Outlier caveat still applies |
| C35 | fact_crashes | `persons_injured` | Persons Injured | int64 | |
| C36 | fact_crashes | `persons_killed` | Persons Killed | int64 | |
| C37 | fact_crashes | `pedestrians_injured` | Pedestrians Injured | int64 | |
| C38 | fact_crashes | `pedestrians_killed` | Pedestrians Killed | int64 | |
| C39 | fact_crashes | `cyclists_injured` | Cyclists Injured | int64 | |
| C40 | fact_crashes | `cyclists_killed` | Cyclists Killed | int64 | |
| C41 | fact_crashes | `motorists_injured` | Motorists Injured | int64 | |
| C42 | fact_crashes | `motorists_killed` | Motorists Killed | int64 | |
| C43 | fact_crashes | `latitude` | Latitude | double | dataCategory Latitude stays |
| C44 | fact_crashes | `longitude` | Longitude | double | dataCategory Longitude stays |
| C45 | fact_persons | `person_age` | Person Age | int64 | SummarizeBy Average stays |
| C46 | fact_persons | `is_injured` | Is Injured | boolean | |
| C47 | fact_persons | `is_killed` | Is Killed | boolean | |

## Columns (hidden — unchanged by Rule 5)

| Table (current) | Hidden columns kept as-is |
|---|---|
| bridge_crash_factor | `bridge_id`, `factor_group_key`, `factor_key` |
| dim_contributing_factor | `factor_key` |
| dim_date | `date_key` |
| dim_driver | `driver_key` |
| dim_factor_group | `factor_group_key`, `factor_set_hash` |
| dim_location | `location_key` |
| dim_person | `person_key` |
| dim_vehicle | `vehicle_key` |
| dim_vehicle_circumstance | `vehicle_circumstance_key` |
| fact_crash_vehicle | `collision_id`, `fact_crash_vehicle_id`, `date_key`, `location_key`, `factor_group_key`, `vehicle_key`, `vehicle_circumstance_key`, `driver_key` |
| fact_crashes | `collision_id`, `crash_id`, `date_key`, `location_key`, `factor_group_key` |
| fact_persons | `collision_id`, `fact_person_id`, `date_key`, `location_key`, `factor_group_key`, `person_key` |

## Collision check

- No two columns in the same table share a proposed name.
- No proposed table name matches another table's name.
- Rule 7: `Dim Date`[Date] and `Dim Contributing Factor`[Contributing Factor]. With the prefix, the column no longer repeats the table name exactly.
- Hidden technical names don't clash with any business name.
