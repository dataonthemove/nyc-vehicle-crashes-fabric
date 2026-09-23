# Context — NYC Motor Vehicle Collisions

The domain glossary for this build. Use these terms in issues, specs, measures and table
names; don't drift to synonyms. Architectural decisions live in `docs/adr/`; durable
conventions live in `CLAUDE.md`.

Seeded 2026-09-18 from existing artifacts. Terms not yet grilled are marked *(unconfirmed)*.

## Source domain

| Term | Meaning |
|---|---|
| **Crash** | One reported collision event, the grain of `fact_crashes`. NYC Open Data calls it a "collision"; this project says **crash** for the event and reserves *collision* for the descriptive dimension. |
| **Person** | One individual involved in a crash — occupant, pedestrian or cyclist. Grain of `fact_persons`. |
| **Vehicle** | One vehicle involved in a crash. A crash has zero or more; the crash–vehicle pairing is the grain of `fact_crash_vehicle`. |
| **Contributing factor** | A cause code recorded against a crash. A crash may have several, which is why the model uses a bridge rather than a foreign key. |
| **Factor group** | The distinct *set* of contributing factors attached to one crash, held in `dim_factor_group`. A crash points at one factor group; the group resolves to many factors through `bridge_crash_factor`. |
| **Injury / fatality counts** | Person counts carried on the crash, split by role (motorist, pedestrian, cyclist). |

## Modeling

| Term | Meaning |
|---|---|
| **Star schema** | Kimball layout in the Fabric Warehouse: conformed dimensions (`dim_*`) around fact tables (`fact_*`). |
| **Bridge** | `bridge_crash_factor`, resolving the many-to-many between factor group and contributing factor. Its relationship cross-filter must be `bothDirections`, or every factor returns the full crash count. |
| **Surrogate key** | `*_key` column, warehouse-generated, the join column. Never summarised. |
| **Business key** | `*_id` column carrying the source system's identifier, e.g. the Socrata collision id. |
| **Grain** | The one row means exactly one ___ statement for a fact table. State it before adding any measure. |

## Pipeline

| Term | Meaning |
|---|---|
| **Landing** | The first hop: raw Socrata extracts arriving in the landing Lakehouse under `Files/raw/`. Repo folder `1_Landing/`. |
| **Ingest** | Moving landed files into Delta tables. |
| **Transform** | The warehouse load: `etl.usp_load_*` procedures that populate the star. Repo folder `2_dev/3_Transform/`. |
| **Watermark** | The high-water mark for incremental loads, in Delta table `etl_watermark` in the landing Lakehouse, written only by Fabric Notebook `nb_etl_watermark`. See `CLAUDE.md` for the legacy warehouse copy. |
| **CDC run** | One pass of Fabric Pipeline `pl_cdc_NYC_Crashes_Landing`, picking up rows newer than the watermark. |
| **Stage load** | One end-to-end pass inside a single stage (Dev, Test or Prod): Ingest → Transform → Refresh. Distinct from a **CDC run**, which happens once, in landing, for all stages. |
| **Framing** | Direct Lake re-reading the current Delta files. An unframed model raises "failed to resolve name" after a deploy; it is not a broken model. |

## Lifecycle (Git and deployment)

| Term | Meaning |
|---|---|
| **Logical ID** | The workspace-independent ID Fabric writes into Git item files (`.platform` `logicalId`, and cross-item references such as a pipeline's Warehouse `artifactId`). A workspace reference is written as all zeros. It is never a live ID, so never copy one into `Context/environment-reference.md`. |
| **Physical ID** | The real ID of an item in one workspace, as returned by `list_items`. Each stage has its own. |
| **Rehydrate** | *(Project term, not Fabric's.)* **Git → workspace.** Fabric turns *logical* IDs (and zero workspace IDs) in a Git definition into *physical* IDs of the matching items in the workspace being written. Triggers: Source Control Update, branch-out. Only ID fields rehydrate; free text such as a Warehouse `endpoint` host is copied unchanged. |
| **Autobind** | *(Microsoft's term.)* **Workspace → workspace.** The deployment pipeline turns *source-stage physical* IDs into *target-stage physical* IDs, matched by item name. Trigger: Deploy (Dev → Test, Test → Prod). Git is not involved. It covers notebook default lakehouses and pipeline notebook/Warehouse IDs. It does **not** cover a Direct Lake on SQL data source (Deployment Rule, ADR-0004) or a pipeline Warehouse `endpoint` (Variable Library, ADR-0003). |

**Rehydrate vs autobind.** Both end with the right physical IDs, so they're easily confused. Tell them apart by what triggered the change: Update or branch-out means rehydrate, Deploy means autobind. Neither one changes free text. Use "rebind" only as a generic verb when you don't know or care which one happened.

## Open terms *(unconfirmed)*

- **Occupancy** — `vehicle_occupants` holds outlier rows that inflate the sum; no agreed definition or cap yet.
- **Severity** — no agreed classification of crash severity exists in the model.
