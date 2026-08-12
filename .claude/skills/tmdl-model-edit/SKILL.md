---
name: tmdl-model-edit
description: Author or review semantic model changes for NYC_VehicleCrashes as local TMDL edits — measures, columns, relationships, SummarizeBy. Use for ANY change to NYC_VehicleCrashes_Semantic. Overrides the fabric-authoring/powerbi-authoring `semantic-model-authoring` skill, which routes to powerbi-modeling-mcp by default and must not be used for authoring here. Triggers: "add a measure", "edit the semantic model", "change SummarizeBy", "add a relationship", "TMDL", "measure layer".
---

# /tmdl-model-edit

Local-TMDL-first authoring for `NYC_VehicleCrashes_Semantic`. Edits are made as files on disk,
committed, pushed, and pulled into Fabric — never written through MCP/XMLA.

## Routing — read this before anything else

The plugin skills `fabric-authoring:semantic-model-authoring` and
`powerbi-authoring:semantic-model-authoring` both default to Tier-1 `powerbi-modeling-mcp` edits
whenever that MCP server is registered, which it always is in this project. **Do not let that
happen.** MCP/XMLA writes hit workspace state, bypass the PR, and do not reliably persist to the
Git-managed layer — the change appears to work and then vanishes or drifts.

Those skills' `references/` files (`tmdl-guidelines.md`, `dax-guidelines.md`,
`direct-lake-guidelines.md`) are good reading for *syntax and DAX craft*. Their **workflow** is
wrong for this repo. Use the reference content, ignore the routing.

MCP is still correct for **run / read / validate**: `refresh_semantic_model`, validation DAX,
`ConnectFabric` + read-only inspection. Never for authoring.

## Where the files live

Root: `4_Model/NYC_VehicleCrashes_Semantic.SemanticModel/`

| Path | Holds |
|---|---|
| `definition/tables/*.tmdl` | One file per table — columns, **and measures** |
| `definition/relationships.tmdl` | All relationships |
| `definition/model.tmdl` | Model-level properties |
| `definition/expressions.tmdl` | Shared expressions / parameters |
| `definition/database.tmdl` | Database-level properties |
| `.platform` | Fabric item metadata — `logicalId`, display name |

Note: the folder is **display-named**, not GUID-named. The GUID lives inside `.platform` as
`logicalId` (a *logical* ID — never copy it into `environment-reference.md`, which holds physical
IDs only).

Do not create manually-exported folders (e.g. `Semantic_model/`) — Git Integration does not watch
them. Delete any that appear.

`5_Reports/` is read-only locally. Report changes happen in the Fabric web UI.

## TMDL rules (apply to every edit)

- **Descriptions use `///` above the object declaration** — not a `description:` property.
- **Never put a `///` description on a relationship.** It breaks Fabric Git import with
  `Workload_FailedToParseFile`. Tables, columns, and measures are fine.
- Indentation is **tabs**, matching the existing files. Mixed indentation fails to parse.
- Do not hand-edit `lineageTag` or `sourceLineageTag` values. Leave existing ones alone; for
  genuinely new objects, omit them and let Fabric assign on import.
- `sourceColumn` must match the Warehouse column exactly — the Warehouse collation is
  case-sensitive.

## SummarizeBy rules (ALWAYS apply)

| Column pattern | `summarizeBy` |
|---|---|
| Any `_key` or `_id` column | `none` |
| Numeric dim attributes — `year`, `quarter`, `month`, `day`, `day_of_week`, `vehicle_year` | `none` |
| `person_age` | `average` |
| `vehicle_occupants` | `sum` |

A schema refresh resets **every** `summarizeBy` to `sum`. After any refresh, re-apply this table
across all files before committing — do not assume only the touched table drifted.

## Relationships

- Bridge relationships need `crossFilteringBehavior: bothDirections`. Without it, every
  contributing-factor query silently returns the full crash count instead of the filtered one —
  it returns *a* number, so it fails quietly. `bridge_crash_factor` → `dim_factor_group` already
  carries this; preserve it.
- Star relationships (fact → dim) take the default single direction.

## Measures

- Measures live inside the `definition/tables/*.tmdl` file of the table they logically belong to
  — normally the fact table being aggregated.
- Before writing any measure over `vehicle_occupants`, note that it is only trustworthy because
  of the outlier cap applied in `44ea207`. Raw `SUM` was inflated ~888x by 1,127 garbage rows.
- Give every measure a `formatString` and a `///` description. A measure layer without
  descriptions reads as unfinished.

## Time intelligence needs dim_date marked as a date table

`SAMEPERIODLASTYEAR`, `DATEADD`, `TOTALYTD` and friends do not work off the integer `date_key`
the relationships join on. `dim_date` carries the marking (verified 2026-08-12, commit `721344c`,
survives Fabric Git import):

```
table dim_date
	dataCategory: Time
	...
	column full_date
		dataType: dateTime
		isKey
```

- `isKey` here is the **date-table designation**, not a relationship key. Do not confuse it with
  `date_key`, which stays the surrogate join column — the relationships were not changed.
- Only **one** table per model can hold `dataCategory: Time`. Marking another moves the
  designation off `dim_date` and silently breaks every time-intelligence measure.
- Preserve both lines on any edit to `dim_date.tmdl`.

Partial-period comparisons look broken and are not: at the CDC watermark the current year and
month show large negative YoY/MoM. Confirm the prior-period value chains correctly against the
previous complete period before treating a swing as a defect.

## Sanity-check aggregates against their denominator

A measure that returns *a* number is not a validated measure. `Average Occupants per Vehicle`
first shipped dividing by all vehicles and returned 0.69 occupants per vehicle — impossible on
its face — because ~51% of `fact_crash_vehicle` rows report `vehicle_occupants` as 0 or blank.
For any ratio, check what share of the denominator actually carries data, restrict the
denominator when the blanks are missing rather than genuinely zero, and expose a coverage
measure next to it so the gap is visible in the report instead of buried in the DAX.

## Workflow (the whole point of this skill)

1. Edit the `.tmdl` files under `4_Model/` locally.
2. Commit. Body format `[domain]_[artifact]_[action]`, surfaced `CC Commit:` or `VSC Commit:`.
3. Push to ADO.
4. In Fabric: **Source Control pane → Update tab → Update All**. This is manual — no auto-sync
   exists. Local edits are invisible to Fabric until pushed *and* pulled.
5. Run `refresh_semantic_model` via MCP.
6. Validate with `/dax-smoke-test`.

Steps 4 and 5 are both required. A DAX error reading `Failed to resolve name` immediately after
an Update All means the model is **unframed**, not broken — refresh it before investigating
anything else.

## Reviewing existing TMDL

When asked to review rather than author, flag in this order: relationship `///` descriptions
(hard import failure), missing `bothDirections` on bridge relationships (silent wrong numbers),
`summarizeBy` drift against the table above, then missing format strings and descriptions.
