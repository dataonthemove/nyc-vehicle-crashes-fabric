# Environment Reference — NYC Motor Vehicle Collisions

> Generated 2026-07-31 via MCP. Refresh by re-running the MCP fetch session.
> Migrated from workspace `NYC_Motor_Vehicle_Collisions` on 2026-07-31.

---

## Workspace

| Field | Value |
|---|---|
| Name | NYC_VehicleCrashes |
| Workspace ID | `73d1612d-023e-40bb-914b-fcd796620223` |
| Capacity ID | `f1b1feea-3619-4c62-928e-69eb8d45b7a9` |

---

## Core Artifacts

| Type | Display Name | Artifact ID |
|---|---|---|
| Lakehouse | NYC_VehicleCrashes_Lakehouse | `69699b13-5771-422f-874c-461430f81d9b` |
| SQLEndpoint | NYC_VehicleCrashes_Lakehouse | `63b7bc57-9351-4c56-a1cf-cda93ca7828c` |
| Warehouse | NYC_VehicleCrashes_Warehouse | `324e2ac0-5ebd-4f8a-9856-a5d7b56a25fe` |
| SemanticModel | NYC_VehicleCrashes_Semantic | `646ec529-eaaa-4d41-b3b0-a31c94355fdd` |
| DataPipeline | pl_cdc_NYC_Crashes | `95ca0fbd-e13c-4743-8d28-d3fa4da33df1` |

**Warehouse TDS endpoint:**
`TBD` — not exposed by the Fabric Items API. Copy from Warehouse → Settings → SQL connection string.

---

## Predecessor Workspace (retained for validation until decommissioned)

| Field | Value |
|---|---|
| Name | NYC_Motor_Vehicle_Collisions |
| Workspace ID | `6e56c48d-2491-4bbe-a283-0efd43bb7d19` |
| Warehouse | `b0befa58-9752-441f-861d-bb04c9fed2c1` |
| Lakehouse | `dc3d09e0-fd82-4e11-8991-4bdeb44bafd5` |

---

## Connections

| Purpose | Connection ID |
|---|---|
| Warehouse (OAuth) | `1de56b14-e844-4550-bfe4-a679696728e6` |
| Lakehouse (OAuth) | `92d1dbb4-eab2-4f3b-ae0d-59145fd8c07f` |
| HTTP source — Crashes (anonymous) | `1a0d925e-7e80-4160-a28d-f1aa73b60cc2` |
| HTTP source — Persons (anonymous) | `d6be2434-1299-49f8-ae45-27fe4a15ad7c` |
| HTTP source — Vehicles (anonymous) | `cfec87c6-d50d-48a0-b9e3-4e6aee57b7bb` |

---

## Notebooks

### DDL Folder (`199ec999-a024-41b6-a5b4-ba1702c8f9a5`)

| Notebook | ID |
|---|---|
| 000_DDL_ETL_Watermark_Seed | `8aced3d4-ef07-4226-bbf4-4cb4825d8c0b` |
| 01_DDL_Dimensions | `9a27bfcc-1bf0-47f5-b08d-6370829816bb` |
| 02_DDL_Facts_Bridges | `93273509-6c49-463c-8f1e-dbb5cc62833d` |

### ETL Folder (`29d9d35c-eee8-4eb9-b7ba-17cd724712b1`)

| Notebook | ID |
|---|---|
| 03_ETL_dim_date | `ab9cd4c3-2810-49e5-be3b-cc92831e1d75` |
| 04_ETL_dim_collision | `08315903-321f-4603-8c25-9d7f2dfa46d6` |
| 05_ETL_dim_location | `3f502d5a-5cae-4973-9823-2869b6925449` |
| 06_ETL_dim_contributing_factor | `2d913203-4de0-4035-b9c8-3c52aa241a71` |
| 07_ETL_dim_vehicle | `28cad77a-61cd-4a9d-a8c5-b534e4dca88b` |
| 08_ETL_dim_damage | `536645a1-25dd-4ba0-9a3f-8c13fe6db0d2` |
| 09_ETL_dim_person | `31c74980-c0f1-4f07-bf41-2baa921d3c95` |
| 09b_ETL_dim_factor_group | `a932aea5-47a4-4cbc-b0d9-1daa00223a7f` |
| 10_ETL_fact_crashes | `c079a56a-28d1-4fca-aeed-40a4dbbea057` |
| 11_ETL_fact_persons | `8e80a005-55f0-4c76-9a16-09ace918e729` |
| 12_ETL_fact_crash_vehicle | `14e6aec2-a1c0-4b4b-89ad-34462202842f` |
| 13_ETL_bridge_crash_factor | `f06e0440-468f-44bb-9641-4759ef52921c` |

### Root / Other

| Notebook | Folder | ID |
|---|---|---|
| nb_cdc_to_delta | root | `7eb04901-f0b8-4cf3-be76-e9ee4c5431b0` |
| RefreshSemanticModel | `3ef14615-6f34-4f51-bbe2-e1cb7779ecf0` | `166e6595-9353-4ec7-ad5d-b3acdd7244d9` |

---

## Pipeline Topology — pl_cdc_NYC_Crashes

Three parallel streams, each: Lookup Watermark → Copy CDC → Delta merge. All three delta merges must succeed before watermark update.

```
Lookup_Crashes_Watermark ──► Copy_Crashes_CDC ──► nb_delta_Crashes ──┐
Lookup_Persons_Watermark ──► Copy_Persons_CDC ──► nb_delta_Persons ──┼──► Update_Watermark_crashes_vehicles_persons
Lookup_Vehicles_Watermark ─► Copy_Vehicles_CDC ─► nb_delta_Vehicles ─┘
```

| Activity | Type | Depends On |
|---|---|---|
| Lookup_Crashes_Watermark | Lookup | — |
| Lookup_Persons_Watermark | Lookup | — |
| Lookup_Vehicles_Watermark | Lookup | — |
| Copy_Crashes_CDC | Copy | Lookup_Crashes_Watermark |
| Copy_Persons_CDC | Copy | Lookup_Persons_Watermark |
| Copy_Vehicles_CDC | Copy | Lookup_Vehicles_Watermark |
| nb_delta_Crashes | TridentNotebook (nb_cdc_to_delta) | Copy_Crashes_CDC |
| nb_delta_Persons | TridentNotebook (nb_cdc_to_delta) | Copy_Persons_CDC |
| nb_delta_Vehicles | TridentNotebook (nb_cdc_to_delta) | Copy_Vehicles_CDC |
| Update_Watermark_crashes_vehicles_persons | Script | nb_delta_Crashes + nb_delta_Persons + nb_delta_Vehicles |

**nb_cdc_to_delta parameters by stream:**

| Stream | file_subfolder | natural_key | source_name |
|---|---|---|---|
| Crashes | NYC_CrashData/crashes | collision_id | crashes |
| Persons | NYC_CrashData/persons | unique_id | persons |
| Vehicles | NYC_CrashData/vehicles | unique_id | vehicles |
