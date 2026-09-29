# 03: Rename in TMDL, update docs, verify in Dev

**What to build:** In Dev, report authors see the approved business-friendly table and column names, and the model binds and queries exactly as before. Claude applies the approved names to the local TMDL definition and updates every doc and skill that quotes model names. Pat pushes and runs Update All, then Claude verifies Dev.

**Blocked by:** 01 (Delete the existing report), 02 (Naming review file).

**Status:** ready-for-agent

**Who:** Claude edits and verifies; Pat pushes and runs Source Control Update All.

- [ ] Every approved table is renamed in its declaration, its `ref table` line, its partition name, and its TMDL file name
- [ ] Every approved visible column is renamed; hidden columns follow the review file
- [ ] Every column's `sourceColumn` and every partition's `entityName` is unchanged
- [ ] All `lineageTag`s, `///` descriptions, SummarizeBy, dataCategory and isHidden settings are unchanged
- [ ] Every relationship `fromColumn`/`toColumn` references the new table names. Relationship identifiers and cross-filter behaviour (including the bridge's `bothDirections`) are unchanged, and no `///` descriptions are added to relationships
- [ ] The git diff of the model definition shows renames only, with no semantic changes
- [ ] The DAX references in the `dax-smoke-test` skill are updated; its Spark (Warehouse-name) checks are untouched
- [ ] The `tmdl-model-edit` skill's name references are updated
- [ ] The CLAUDE.md SummarizeBy section is restated with the new column names
- [ ] `CONTEXT.md` gains a business-name ↔ Warehouse-name mapping
- [ ] Everything above ships in one commit (`CC Commit:` prefix, `[domain]_[artifact]_[action]` body)
- [ ] Pat: push, then Update All in Dev, which completes without `Workload_FailedToParseFile`
- [ ] `refresh_semantic_model` succeeds in Dev
- [ ] One DAX query returns a few rows from every table by its new name, selecting every renamed visible column, with no errors and no all-blank columns
- [ ] Any cosmetic Source Control drift afterwards is classified per item per the CLAUDE.md drift rule
