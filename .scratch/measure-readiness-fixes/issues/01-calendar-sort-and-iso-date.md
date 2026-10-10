# 01: Calendar sort order and ISO date format (Dev)

**What to build:** In the Dev semantic model, `Dim Date`[Month] sorts in calendar order and [Day of Week] in week order (Sunday first) in every visual and slicer, with no per-visual re-sorting. `Dim Date`[Date] displays as `yyyy-mm-dd` with no midnight timestamp. The date-table marking (`dataCategory: Time`, `isKey`) is untouched, so time intelligence keeps working. Spec issue 1.

**Blocked by:** None (can start immediately)

**Status:** closed

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Pull the current Dev model state via MCP (read only) and confirm the `Dim Date` TMDL in git matches it | CC | No difference beyond the known cosmetic column order | done |
| 2 | Local TMDL edit (`/tmdl-model-edit`): set [Month] to sort by [Month Number], [Day of Week] to sort by [Day of Week Number], and give [Date] the format string `yyyy-mm-dd`. Leave `dataCategory` and `isKey` as they are | CC | The TMDL diff shows only these three property changes | done |
| 3 | Update the model documentation's `Dim Date` row to record the sort-by columns and the date format | CC | The doc row names both sort-by columns and the ISO format | done |
| 4 | Commit the TMDL and doc changes together (`CC Commit: model_dimdate_sortby-isodate`) | CC | Commit exists on main; working tree clean for these files | done |
| 5 | Push to ADO, then run Source Control → Update All in Dev | Pat | Source Control pane shows the semantic model in sync | done |
| 6 | Run `refresh_semantic_model` on Dev, because a git deploy leaves the model unframed | CC | Refresh completes | done |
| 7 | DAX: `INFO.VIEW.COLUMNS` shows [Month Number] and [Day of Week Number] as sort-by columns and a non-time format on [Date] | CC | Both sort-by columns and the `yyyy-mm-dd` format are reported | done |
| 8 | DAX: run a time-intelligence query (prior-year crash count via `SAMEPERIODLASTYEAR`) | CC | The query resolves and returns non-blank values for a loaded year | done |

## Comments

- 2026-10-10 (CC): Steps 1–4 done. Live Dev `Dim Date` matched git apart from the known `Month Number` column order. Live check: `Day of Week Number` 1 = Sunday … 7 = Saturday, one name per number. Next: Pat pushes and runs Update All (step 5).
- 2026-10-10 (CC): Steps 5–8 done. Pat ran Update All in the Dev workspace; refresh completed. INFO.VIEW.COLUMNS: Month → sort by Month Number, Day of Week → sort by Day of Week Number, Date format `yyyy-mm-dd`, IsKey still true. SAMEPERIODLASTYEAR prior-year crash count chains exactly (e.g. 2025 PY = 91,316 = 2024 actual). Closed.
