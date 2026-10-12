# Nest every measure display folder under `_Measures`

**Status:** done (2026-10-12)
Raised: 2026-10-12 (Pat, reviewing the measure layer in the Fabric web data model view)

**Problem:** The Data pane in the Fabric web data model view sorts display folders and fields
together alphabetically (CC wrongly assumed folders sort first). On each fact table the measure
folders (`Volume`, `Rates`, …) are interleaved with columns, so a report author can't see a table's
measures in one place.

**Fix:** Prefix every measure `displayFolder` with `_Measures\`, so each fact table shows one
`_Measures` folder at the top with the existing subject folders inside it. Display metadata only:
no DAX, values, tables or Warehouse change. Options considered and rejected: a dedicated measure
table, or one per fact (Direct Lake needs something to back each new table: an untested calculated
table, or a Warehouse table and its deploy risk); a flat `_Measures` folder (`Fact Crashes` has 21
measures).

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Prefix the 38 `displayFolder` values in the three fact table TMDL files; note the nesting in `SEMANTIC_MODEL.md`; commit (`model_measures_displayfolder_nest`) | CC | Diff is 38 `displayFolder` lines plus the doc | done |
| 2 | Push to ADO; Dev Source Control → Update All | Pat | Nothing pending for the semantic model | done |
| 3 | `refresh_semantic_model` on Dev; `INFO.VIEW.MEASURES` shows 38 measures, all `Valid`, every display folder starting `_Measures\` | CC | All hold | done |
| 4 | Deploy Dev → Test, then Test → Prod, semantic model only | Pat | Both deployments succeed; Warehouse not in the deployed set | done |
| 5 | Repeat the step 3 check on Test and Prod | CC | All hold in both | done |
| 6 | Pat confirms the Data pane shows one `_Measures` folder at the top of each fact table | Pat | Confirmed | done |

## Comments

**2026-10-12 — CC, step 1.** Committed `95df7b1`.

**2026-10-12 — CC, step 3 (Dev).** `refresh_semantic_model` Completed (refresh `460265395`).
`INFO.VIEW.MEASURES`: 38 measures, 0 not `Valid`, 0 display folders outside `_Measures\`; 11
subfolders as before.

**2026-10-12 — CC, step 5 (Test, Prod).** After Pat's semantic-model-only deploys,
`refresh_semantic_model` Completed in Test (`460270824`) and Prod (`460270833`). In both:
38 measures, 0 not `Valid`, 0 display folders outside `_Measures\`, 11 subfolders;
`Fact Crashes` 2,269,187 rows, unchanged. Remaining: step 6 (Pat's visual check).

**2026-10-12 — Pat, step 6.** Confirmed: `_Measures` shows at the top of each fact table. Side
effect noted: `Fact Crash Vehicles` has no visible columns, so the Data pane treats it as a measure
table (calculator icon) and pins it above all other tables, apart from the other two facts. No
setting turns this off; the only lever is column visibility.
