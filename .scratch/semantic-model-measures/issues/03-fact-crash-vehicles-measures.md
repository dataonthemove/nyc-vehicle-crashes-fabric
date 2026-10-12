# 03: Fact Crash Vehicles measures

**What to build:** Report authors in Dev get the 8 `Fact Crash Vehicles` measures per the spec's measure catalogue: `Vehicles Involved`, `Avg Vehicles per Crash`, `Total Occupants`, `Vehicles with Occupant Data`, `Avg Occupants per Vehicle`, `Occupant Data Coverage %`, `Avg Vehicle Age at Crash` and `Unlicensed Driver %`. Vehicle Occupants is hidden.

`Avg Vehicles per Crash` returns BLANK under `Dim Vehicle`, `Dim Driver` or `Dim Vehicle Circumstance` filters, because those filter only its numerator: line → header filtering is unsupported (ADR-0005). This guard is the one measure not yet run against Dev.

**Blocked by:** 01 (`Avg Vehicles per Crash` references `[Total Crashes]`)

**Status:** done (2026-10-12)

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Pull current Dev model state via MCP; confirm ticket 01's measures are live | CC | Recorded in Comments | done |
| 2 | Prove the `Avg Vehicles per Crash` guard as a query-scoped measure before authoring it | CC | BLANK by Vehicle Type and a value by Borough, both recorded in Comments | done |
| 3 | Add the 8 measures to the `Fact Crash Vehicles` TMDL with format strings, display folders (`Volume`, `Occupancy`, `Vehicle & Driver`) and `///` descriptions; hide Vehicle Occupants | CC | TMDL diff shows exactly 8 measures and Vehicle Occupants hidden | done |
| 4 | Update the Measures section and the Vehicle Occupants column note in the semantic model doc; settle the *Occupancy* term in `CONTEXT.md` | CC | Occupancy no longer marked unconfirmed | done |
| 5 | Commit locally (`model_factcrashvehicle_measures`) | CC | Commit exists; working tree clean | done |
| 6 | Push to ADO; Dev Source Control → Update All | Pat | Nothing pending for the semantic model | done |
| 7 | `refresh_semantic_model` on Dev to frame | CC | Refresh completes | done |
| 8 | Metadata check: 8 vehicle measures, each with description, format string and display folder; Vehicle Occupants hidden | CC | All hold | done |
| 9 | Base equality by `Dim Date`[Year]: `Vehicles Involved`, `Total Occupants` and `Vehicles with Occupant Data` equal independent `COUNTROWS`/`SUM`; the `Unlicensed Driver %` denominator equals the count of Licensed, Unlicensed and Permit only | CC | Every row matches | done |
| 10 | Guard check on the deployed measure | CC | BLANK by `Dim Vehicle`[Vehicle Type]; a value by `Dim Location`[Borough] | done |
| 11 | Run `/dax-smoke-test` on Dev | CC | All checks pass | done |

## Comments

**2026-10-12 — CC, step 1.** Live Dev (`INFO.VIEW.MEASURES` / `INFO.VIEW.COLUMNS`): ticket 01's 21
`Fact Crashes` measures (2 hidden) and ticket 02's 9 `Fact Crash Persons` measures all `Valid`;
`Fact Crash Vehicles` has no measures and Vehicle Occupants visible. Matches git. Driver License
Status values: Licensed 2,018,943 · Unlicensed 44,164 · Permit 20,747 · blank 2,456,358 · 13
abbreviated codes (VAL 10,014 and others, ~10.8k), as the spec says.

**2026-10-12 — CC, step 2 (test-first).** All 8 measures run first as query-scoped `DEFINE MEASURE`
against Dev. Guard: `Avg Vehicles per Crash` BLANK for the top 5 Vehicle Types, the top 3 Driver
License Statuses and all 21,430 `Dim Vehicle Circumstance` rows; by Borough it equals the independent
`COUNTROWS` ratio in all 6 boroughs (total 2.01). The other measures vs independent
`COUNTROWS`/`SUMX`/`COUNTX`/`AVERAGEX` by `Dim Date`[Year]: 15 years, all match, including the
`Unlicensed Driver %` denominator (vehicles minus non-Licensed/Unlicensed/Permit). All years: 4,551,002
vehicles, 3,118,066 occupants over 2,720,205 vehicles with data (1.15 per vehicle, 59.8% coverage).
Occupant and license data are near-absent before 2016 (2012: 49 vehicles with occupants, 35 known
statuses), so both are flagged as a 2016 break in the descriptions. Avg Vehicle Age 2012 → 2026 =
5.21 → 8.12; Unlicensed Driver % 2025 = 3.1%, both matching the spec's figures.

**2026-10-12 — CC, steps 3–4.** `Fact Crash Vehicles.tmdl`: 8 measures plus `isHidden` on Vehicle
Occupants. Docs: semantic model doc (Measures section, Fact Crash Vehicles row), `CONTEXT.md`
(*Occupancy* moved from open terms into the source-domain glossary; Vehicle Occupants mapping).

**2026-10-12 — CC, code review (standards + spec) applied.** Status label kept canonical
(`ready-for-agent`); descriptions now all say "Source: vehicle records" and use one 2016-break
wording on the four occupancy measures and `Unlicensed Driver %`; spec ‡ mark on
`Avg Vehicles per Crash` cleared. Not taken: pointing the guard description at ADR-0005 instead of
naming the three dimensions (the field-list tooltip should say when it goes BLANK), a known-status
flag on `Dim Driver` and a `vehicle_age` ETL column (new columns and Warehouse changes are out of scope).

**2026-10-12 — CC, steps 7–10 (after `667852b`, push + Update All).**
- Step 7: `refresh_semantic_model` Completed (refresh `460249435`).
- Step 8: `INFO.VIEW.MEASURES`: 38 measures in the model, none invalid, 2 hidden (the Fact Crashes
  helpers). The 8 `Fact Crash Vehicles` measures are all `Valid` and visible, each with a description
  and the spec's display folder. Format strings come from the live TMDL (`get_semantic_model_definition`):
  counts `#,0`, averages `#,0.00`, rates `0.0%`. The live TMDL differs from git only in column order
  (Fabric re-serialization). `INFO.VIEW.COLUMNS`: Vehicle Occupants hidden, SummarizeBy Sum.
- Step 9: deployed measures vs independent `COUNTROWS`/`SUMX`/`COUNTX` by `Dim Date`[Year]: 15 data
  years, 0 failing rows. That covers `Vehicles Involved`, `Total Occupants`, `Vehicles with Occupant Data`
  and `Unlicensed Driver %` against a denominator of Licensed, Unlicensed and Permit only. All years:
  4,551,002 vehicles · 3,118,066 occupants · Avg Occupants per Vehicle 1.15 · coverage 59.8% ·
  Unlicensed Driver % 2.1% (2025: 3.1%) · Avg Vehicle Age at Crash 6.76 (2026: 8.12).
- Step 10: `Avg Vehicles per Crash` is BLANK for all 2,168 `Dim Vehicle`[Vehicle Type] members. By
  `Dim Location`[Borough] it equals the independent `COUNTROWS` ratio for all 6 members.

**2026-10-12 — CC, step 11.** `/dax-smoke-test` on Dev: all pass. No rebuild preceded it, so
check 1 compared the Spark counts with the model's DAX counts.

| Check | Subject | Result | Offending | Expected vs actual |
|---|---|---|---|---|
| 1 | Fact rows, Spark vs model (3) | PASS | 0 | 2,269,187 · 5,984,110 · 4,551,002 on both sides |
| 2 | Line → header key agreement, duplicate `collision_id` (9) | PASS | 0 | 0 mismatches |
| 3 | Orphaned / null keys on 15 relationships; duplicate dim keys (7) | PASS | 0 | 0 |
| 4 | Factor-group integrity, Unknown location, `dim_driver` uniqueness (7) | PASS | 0 | 1 empty-set group, 1 Unknown |
| 5 | Every bridged factor filters all three facts | PASS | 0 | 63 factors, 0 failing |
| 6 | Relationships match spec | PASS | 0 | 0 missing/wrong, 0 extra, 0 RI off |

Ticket closed. Next: ticket 04 (promote to Test).
