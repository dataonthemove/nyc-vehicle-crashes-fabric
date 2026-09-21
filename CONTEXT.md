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

## Open terms *(unconfirmed)*

- **Occupancy** — `vehicle_occupants` holds outlier rows that inflate the sum; no agreed definition or cap yet.
- **Severity** — no agreed classification of crash severity exists in the model.
