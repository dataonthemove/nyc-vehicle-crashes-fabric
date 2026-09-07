# NYC Motor Vehicle Collisions — Microsoft Fabric

End-to-end analytics build on the NYC Open Data motor vehicle collision datasets:
Lakehouse ingestion → Warehouse dimensional model → Direct Lake semantic model →
Power BI reporting, with CDC pipeline orchestration and Git-based source control.

## Architecture

| Layer | Implementation |
|---|---|
| Ingestion | CDC pipeline (`pl_cdc_NYC_Crashes`) loads Socrata endpoints into Lakehouse Delta tables, watermark-filtered |
| Warehouse | Kimball star schema — conformed dimensions, three facts, and a factor-group bridge — loaded by `etl.usp_load_*` stored procedures |
| Semantic model | Direct Lake, Warehouse-sourced via OneLake; authored as TMDL in this repo |
| Reports | Authored in the Fabric web UI, synced back through Git integration |

## Repo layout

| Path | Contents |
|---|---|
| `1_Landing/` | Landing-zone workspace, bound separately — raw data, owned upstream of Dev/Test/Prod |
| `2_dev/` | Dev workspace, Git-bound. All Fabric items live here |
| `2_dev/1_DDL/` · `2_Ingest/` · `3_Transform/` | DDL, CDC pipeline, and ETL notebooks |
| `2_dev/4_Model/` | Semantic model TMDL — the authoritative source for model changes |
| `2_dev/5_Reports/` | Report definitions — read-only locally |
| `Context Docs/` | Backlog, landing-zone runbook, environment reference |
| `Other/` | Ad-hoc SQL and PowerShell scratch |

## Working conventions

Git is the source of truth. Semantic model and warehouse changes are authored locally,
pushed to Azure DevOps, then pulled into the workspace via Fabric Source Control →
Update All. Test and Prod receive content through deployment pipelines, not Git.

Full conventions and constraints: `CLAUDE.md`.
Current work: `Context Docs/BACKLOG.md` and `Context Docs/landing_zone_runbook.md`.
