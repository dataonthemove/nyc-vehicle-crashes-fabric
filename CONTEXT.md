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
| **Stage-varying value** | A setting whose value differs between Dev, Test and Prod, and which Fabric treats as a literal. It lives in the stage's variable library (`vl_NYC_Crashes`, ADR-0003). |
| **Binding** | A reference from one item to another that Fabric re-points to the target stage's item when it deploys. |
| **Active value set** | The set of variable values a stage's library currently serves. It is chosen by hand in each stage and never deployed. |
| **Branch workspace** | A feature workspace created by Git branch-out. It is *not* a stage: its bindings still point at Dev, and its active value set is Dev's. Pre-flight: `Context/branch-out-preflight.md`. |
| **Default lakehouse** | The lakehouse a notebook resolves relative `Files/` and `Tables/` paths against. It is stored in the `# META` header of the notebook's git file. Autobind repoints it on deploy, but branch-out doesn't. |

## Lifecycle (Git and deployment)

| Term | Meaning |
|---|---|
| **Logical ID** | The workspace-independent ID Fabric writes into Git item files (`.platform` `logicalId`, and cross-item references such as a pipeline's Warehouse `artifactId`). A workspace reference is written as all zeros. It is never a live ID, so never copy one into `Context/environment-reference.md`. |
| **Physical ID** | The real ID of an item in one workspace, as returned by `list_items`. Each stage has its own. |
| **Rehydrate** | *(Project term, not Fabric's.)* **Git → workspace.** Fabric turns *logical* IDs (and zero workspace IDs) in a Git definition into *physical* IDs of the matching items in the workspace being written. Triggers: Source Control Update, branch-out. Only ID fields rehydrate; free text such as a Warehouse `endpoint` host is copied unchanged. |
| **Autobind** | *(Microsoft's term.)* **Workspace → workspace.** The deployment pipeline turns *source-stage physical* IDs into *target-stage physical* IDs, matched by item name. Trigger: Deploy (Dev → Test, Test → Prod). Git is not involved. It covers notebook default lakehouses and pipeline notebook/Warehouse IDs. It does **not** cover a Direct Lake on SQL data source (Deployment Rule, ADR-0004) or a pipeline Warehouse `endpoint` (Variable Library, ADR-0003). |
| **Capacity** | The pool of compute a workspace runs on. Workspaces sit on a capacity; they aren't part of it. A trial capacity belongs to the user who started it and expires after 60 days. |
| **Capacity reassignment** | Moving a workspace from one capacity to another in the same region. Workspace and item IDs, OneLake data, Git bindings and the deployment pipeline all stay the same; only the compute changes. Distinct from a **rebuild**, which recreates the items from Git in new workspaces, so every physical ID changes. |

**Rehydrate vs autobind.** Both end with the right physical IDs, so they're easily confused. Tell them apart by what triggered the change: Update or branch-out means rehydrate, Deploy means autobind. Neither one changes free text. Use "rebind" only as a generic verb when you don't know or care which one happened.

## Identifiers and connections

| Term | Meaning |
|---|---|
| **Warehouse ID** | The item ID of a Fabric Warehouse, i.e. its **physical ID** in one stage (Dev `324e2ac0…`, Test `c2ce6eed…`). Other places call it `artifactId` (pipeline JSON), "Connection (Warehouse ID)" (pipeline UI) and `Database` (Direct Lake on SQL data source / Deployment Rule). It's the same value in each. Identifies *which* Warehouse. |
| **`artifactId`** | The JSON field in a pipeline Warehouse connection (`linkedService.typeProperties.artifactId`) that holds the **Warehouse ID**. In Git it's a **logical ID**; in a workspace it's the physical Warehouse ID. It is rehydrated on Update and autobound on Deploy. It's a field name, not a separate kind of ID. |
| **`workspaceId`** | The ID of the workspace that holds a referenced item (UI "Workspace ID"). In Git it's all zeros, meaning "this workspace"; in a workspace it's the stage's physical workspace ID (Dev `73d1612d…`, Test `b67c8251…`). It is rehydrated and autobound like `artifactId`. |
| **Connection ID** | The ID of a Fabric **connection object** (gear → Manage connections and gateways), which holds credentials, e.g. `DataWarehouseConnection` `1de56b14…` (OAuth, `user7`). It isn't an item: it has no logical ID, it's the same in every stage, and it's never rehydrated or autobound. This pipeline's SP activities don't use one. Don't confuse it with the Warehouse ID in the "Connection (Warehouse ID)" field. |
| **TDS endpoint** | Tabular Data Stream, the SQL Server wire protocol. The endpoint is the **host name** SQL clients connect to (`…datawarehouse.fabric.microsoft.com`), one per workspace, so it differs per stage. It appears as `endpoint` (pipeline JSON), "SQL connection string" (pipeline UI), `Server` (Direct Lake on SQL data source) and `properties.connectionString` (REST). It's free text, not an ID, so it's never rehydrated or autobound; pipelines read it from `vl_NYC_Crashes.warehouse_endpoint` (ADR-0003). |
| **Endpoint host prefix** | The TDS host's first label, `<tenant>-<workspace>`: two GUIDs, each base32-encoded (lowercase, no padding) to fit DNS's 63-character label limit and a one-level wildcard certificate. Reversible, not secret. The tenant half is the same in every stage; the workspace half differs. 
**How to tell them apart.** The Warehouse ID and `artifactId` are the same value under two names, and they say *which item*. `workspaceId` says *which workspace* the item is in. The TDS endpoint says *which server to connect to*, as a host name, not a plain GUID. The connection ID says *whose credentials*. Only the first three change automatically between stages.

## Open terms *(unconfirmed)*

- **Occupancy** — `vehicle_occupants` holds outlier rows that inflate the sum; no agreed definition or cap yet.
- **Severity** — no agreed classification of crash severity exists in the model.
