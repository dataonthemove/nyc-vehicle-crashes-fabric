# ADR-0007: Semantic model evolution and report compatibility

- **Status:** Proposed
- **Date:** 2026-10-14
- **Related:** ADR-0006 (code-first report authoring, self-service workspaces)

## Context

Self-service reports bind to the Prod semantic model `NYC_VehicleCrashes_Semantic` with Build
permission (ADR-0006). Thin reports reference model objects by table and field name — every PBIR
field expression carries an `Entity` and a `Property`. The model is therefore a published contract:
a rename or removal that is safe inside this repo can break reports the team does not own and
cannot see.

On 2026-10-14 a demo (commit `af32e4a`, reverted in `897811f`) hid measure
`Fatalities per 1,000 Crashes`, moved it to display folder `_Deprecated` and flagged its
description. The Overview KPI card in `NYC_CrashReports` that uses it kept rendering in Dev. A
measure's `displayFolder` is per field; the table does not move.

## Decision

### 1. Classify every model change before it leaves Dev

| Class | Examples | Effect on existing reports | Handling |
|---|---|---|---|
| Additive | New measure, column, table, relationship | None | Ship |
| Cosmetic | `displayFolder`, `///` description, `formatString`, hiding | None — hidden fields still resolve | Ship |
| Logic | Measure DAX or filter semantics change; numbers move | Visuals work, values differ | Ship with release note **before** Prod deployment |
| Breaking | Rename, delete, move a measure to another table, data-type change, grain change | Visuals fail ("fields need to be fixed") | Deprecation cycle (§2) |

Moving a measure to another table is classed breaking until tested otherwise: PBIR references
carry the table name.

### 2. Deprecation cycle for breaking changes

1. Add the replacement object alongside the old one.
2. On the old object: `isHidden`, `displayFolder: _Deprecated`, and a `///` description starting
   `DEPRECATED — use <replacement>; removal on <date>.`
3. Run field-level impact analysis (§3) and contact the owners of every report that still uses it.
4. Remove the object once no report uses it, or on the announced date — whichever is later unless
   the owners have been told otherwise.

All steps are local TMDL edits per `tmdl-model-edit`; nothing is changed through MCP or the web UI.

### 3. Impact analysis

- **Item level:** Fabric lineage view and the model's **Impact analysis** list dependent reports,
  workspaces and contacts. They do not show which fields a report uses.
- **Field level:** search the PBIR files of every report repo for the field's `"Property"` value,
  which covers visual fields, filters, sorts and conditional formatting:

  ```bash
  grep -rlF '"Property": "<Field Name>"' 2_dev/5_Reports --include=*.json
  ```

  Same-named fields in different tables (e.g. `Year`) also match — confirm the `"Entity"` near
  each hit. A hit's path reads report → page ID → visual ID; the page's `displayName` is in its
  `page.json`.

### 4. Self-service workspaces must be Git-connected

Field-level impact analysis only sees reports whose definitions are in a repo. Every self-service
workspace built on the Prod model is Git-connected, and its repo is searched in §3 alongside
`2_dev/5_Reports/`.

### 5. Structural safeguards

- **Business-name layer.** Model names are business names mapped to Warehouse names
  (`CONTEXT.md`). Warehouse renames are absorbed in `sourceColumn`; the model name stays.
- **Explicit measures.** Set `discourageImplicitMeasures` on the model so new reports use explicit
  measures. A schema refresh resets every `summarizeBy` to `sum`, which silently changes implicit
  totals in reports the team does not own.
- **Endorsement.** The Prod model is Certified, signalling it is governed and changes carry notice.

### 6. Communication

- A change log entry per Prod deployment, listing logic changes and deprecations.
- A deprecation calendar: object, replacement, announced date, removal date.
- Report owners found in §3 are notified directly, not only through the change log.

### 7. Last resort: side-by-side model version

When a redesign would break most reports at once, publish a v2 model next to v1, rebind reports to
v2, then retire v1. Used rarely — it doubles refresh, capacity and maintenance until v1 is gone.

## Consequences

- Hidden fields remain part of the contract until removed through §2; hiding alone is not removal.
- Breaking changes take at least one deprecation period instead of a single deployment.
- Self-service workspaces carry a Git-connection requirement.
- Open items:
  - Untested whether moving a measure between tables breaks thin reports.
  - Untested whether enabling `discourageImplicitMeasures` affects existing implicit-measure
    visuals; test in Dev before Prod.
  - Change log and deprecation calendar location not yet chosen.
  - Semantic Link Labs report field-usage functions could automate §3; not yet evaluated.
