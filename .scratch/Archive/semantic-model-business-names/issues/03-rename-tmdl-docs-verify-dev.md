# 03: Rename in TMDL, update docs, verify in Dev

**What to build:** In Dev, report authors see the approved business-friendly table and column names, and the model binds and queries exactly as before. Claude applies the approved names to the local TMDL definition and updates every doc and skill that quotes model names. Pat pushes and runs Update All, then Claude verifies Dev.

**Blocked by:** 01 (Delete the existing report), 02 (Naming review file).

**Status:** done

**Who:** Claude edits and verifies; Pat pushes and runs Source Control Update All.

- [x] Every approved table is renamed in its declaration, its `ref table` line, its partition name, and its TMDL file name
- [x] Every approved visible column is renamed; hidden columns follow the review file
- [x] Every column's `sourceColumn` and every partition's `entityName` is unchanged
- [x] All `lineageTag`s, `///` descriptions, SummarizeBy, dataCategory and isHidden settings are unchanged
- [x] Every relationship `fromColumn`/`toColumn` references the new table names. Relationship identifiers and cross-filter behaviour (including the bridge's `bothDirections`) are unchanged, and no `///` descriptions are added to relationships
- [x] The git diff of the model definition shows renames only, with no semantic changes
- [x] The DAX references in the `dax-smoke-test` skill are updated; its Spark (Warehouse-name) checks are untouched
- [x] The `tmdl-model-edit` skill's name references are updated
- [x] The CLAUDE.md SummarizeBy section is restated with the new column names
- [x] `CONTEXT.md` gains a business-name ↔ Warehouse-name mapping
- [x] Everything above ships in one commit (`CC Commit:` prefix, `[domain]_[artifact]_[action]` body)
- [x] Pat: push, then Update All in Dev, which completes without `Workload_FailedToParseFile`
- [x] `refresh_semantic_model` succeeds in Dev
- [x] One DAX query returns a few rows from every table by its new name, selecting every renamed visible column, with no errors and no all-blank columns
- [x] Any cosmetic Source Control drift afterwards is classified per item per the CLAUDE.md drift rule

## Comments

2026-09-29 — Dev verified. Update All clean (Pat). `refresh_semantic_model` Completed (refresh 454540087).
Binding query: all 12 tables resolve by new name. Every renamed column returns data; the lowest
non-blank count per table is > 0 (partial blanks are source nulls, e.g. Vehicle Occupants 2.72M of 4.55M).
Rows: Fact Crashes 2,269,187 · Fact Crash Vehicles 4,551,002 · Fact Crash Persons 5,984,110 ·
Dim Date 6,940 · Dim Location 246 · Dim Contributing Factor 66 · Dim Driver 670 · Dim Person 25,990 ·
Dim Vehicle 155,594 · Dim Vehicle Circumstance 21,430 · dim_factor_group 1,581 · bridge_crash_factor 3,610.

2026-09-29 — Source Control shows no drift on NYC_VehicleCrashes_Semantic after Update All (Pat). Ticket closed.
