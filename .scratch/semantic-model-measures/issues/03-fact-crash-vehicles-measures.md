# 03: Fact Crash Vehicles measures

**What to build:** Report authors in Dev get the 8 `Fact Crash Vehicles` measures per the spec's measure catalogue: `Vehicles Involved`, `Avg Vehicles per Crash`, `Total Occupants`, `Vehicles with Occupant Data`, `Avg Occupants per Vehicle`, `Occupant Data Coverage %`, `Avg Vehicle Age at Crash` and `Unlicensed Driver %`. Vehicle Occupants is hidden.

`Avg Vehicles per Crash` returns BLANK under `Dim Vehicle`, `Dim Driver` or `Dim Vehicle Circumstance` filters, because those filter only its numerator: line → header filtering is unsupported (ADR-0005). This guard is the one measure not yet run against Dev.

**Blocked by:** 01 (`Avg Vehicles per Crash` references `[Total Crashes]`)

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Pull current Dev model state via MCP; confirm ticket 01's measures are live | CC | Recorded in Comments | todo |
| 2 | Prove the `Avg Vehicles per Crash` guard as a query-scoped measure before authoring it | CC | BLANK by Vehicle Type and a value by Borough, both recorded in Comments | todo |
| 3 | Add the 8 measures to the `Fact Crash Vehicles` TMDL with format strings, display folders (`Volume`, `Occupancy`, `Vehicle & Driver`) and `///` descriptions; hide Vehicle Occupants | CC | TMDL diff shows exactly 8 measures and Vehicle Occupants hidden | todo |
| 4 | Update the Measures section and the Vehicle Occupants column note in the semantic model doc; settle the *Occupancy* term in `CONTEXT.md` | CC | Occupancy no longer marked unconfirmed | todo |
| 5 | Commit locally (`model_factcrashvehicle_measures`) | CC | Commit exists; working tree clean | todo |
| 6 | Push to ADO; Dev Source Control → Update All | Pat | Nothing pending for the semantic model | todo |
| 7 | `refresh_semantic_model` on Dev to frame | CC | Refresh completes | todo |
| 8 | Metadata check: 8 vehicle measures, each with description, format string and display folder; Vehicle Occupants hidden | CC | All hold | todo |
| 9 | Base equality by `Dim Date`[Year]: `Vehicles Involved`, `Total Occupants` and `Vehicles with Occupant Data` equal independent `COUNTROWS`/`SUM`; the `Unlicensed Driver %` denominator equals the count of Licensed, Unlicensed and Permit only | CC | Every row matches | todo |
| 10 | Guard check on the deployed measure | CC | BLANK by `Dim Vehicle`[Vehicle Type]; a value by `Dim Location`[Borough] | todo |
| 11 | Run `/dax-smoke-test` on Dev | CC | All checks pass | todo |

## Comments
