# CLAUDE.md — NYC Motor Vehicle Collisions (Microsoft Fabric)

> Durable rules and conventions only.
> Live identifiers, GUIDs, connection IDs, and current artifact inventory are in the
> Environment Reference doc (Claude Project Files in claude.ai, or local notes).

## Project Overview
Portfolio-grade, end-to-end Fabric build on NYC Motor Vehicle Collision data.
Pipeline: Lakehouse ingestion → Warehouse dimensional modeling (Kimball star schema + bridge)
→ Direct Lake semantic model → CDC pipeline orchestration → Git version control (Azure DevOps).
MCP servers: `ms-fabric-mcp-server` (Fabric REST) and `powerbi-modeling-mcp` (XMLA/tabular).

## Architecture Conventions
- Modeling: Kimball star schema with a factor-group **bridge** pattern.
- Semantic model: Direct Lake, Warehouse-sourced via OneLake. Always connect via
  `powerbi-modeling-mcp` using the **semantic model name**, not the warehouse name.
- Version control: code-first TMDL/Git in VSC + Azure DevOps.
  - Fabric Git Integration watches only the GUID-named `*.SemanticModel/definition/tables/` folder.
  - Do NOT use MCP/XMLA edits for routine semantic model changes — they don't reliably persist
    to the Git-managed layer. Workflow: edit GUID folder locally → commit/push → Fabric Source
    Control pane (Update tab → Update All).
  - Manually exported folders (e.g. `Semantic_model/`) are NOT watched by Git Integration — delete them.
- Watermark: single authoritative store in Warehouse (`dbo.etl_watermark`).
  The Delta-layer watermark was intentionally removed from notebooks.

## Fabric Warehouse — T-SQL Constraints (ALWAYS apply)
- No PRIMARY KEY, UNIQUE, or FOREIGN KEY constraints. No inline constraints in `CREATE TABLE`.
- No TINYINT — use SMALLINT.
- IDENTITY syntax: `BIGINT IDENTITY` only — no seed/increment params (`IDENTITY(1,1)` fails).
- Drop-if-exists: use `OBJECT_ID` check pattern.
- No `MAXRECURSION` hint; no cross-joins on `sys.all_objects`; use `WHILE` loops for date generation.
- `DATETIME2` columns require explicit precision, e.g. `DATETIME2(6)`.
- Cross-database lakehouse references use the lakehouse name directly (SQL analytics endpoint = same object).

## Semantic Model — SummarizeBy Rules (ALWAYS apply)
- All `_key` and `_id` columns → `None`.
- Numeric dim attributes (year, quarter, month, day, day_of_week, vehicle_year) → `None`.
- `person_age` → `Average`; `vehicle_occupants` → `Sum`.
- A schema refresh resets all SummarizeBy to Sum — full re-fix required after any refresh.

## MCP Constraints (ALWAYS apply)
- At the start of any session touching existing Fabric artifacts, **pull current state via MCP
  before making any changes**.
- `list_lakehouse_files` reads `Files/` only — use Livy `SHOW TABLES` for Delta tables in `Tables/`.
- Livy sessions time out — check status before submitting; recreate if in terminal state.
- Notebooks default to Spark kernel — explicitly select `sqldatawarehouse` kernel for Warehouse T-SQL.
  T-SQL notebooks must be manually connected to the Warehouse data source on open.
- `powerbi-modeling-mcp` requires `ConnectFabric` before any modeling op.
  Use `clearCredential: False` to refresh cached state.
- `ExportToTmdlFolder` is a one-time bootstrap only — not for routine use.
- TMDL description syntax: use `///` above the object declaration (not a `description:` property).
- `add_activity_dependency` can time out on multi-dependency additions — fall back to Fabric UI.
- OAuth-owned connections (Lakehouse, Warehouse) fail with permission errors in
  `update_pipeline_definition`; anonymous HTTP connections work freely.
- MCP file upload cannot access the Claude container filesystem.
- `update_pipeline_definition` accepts notebook content as an inline Python dict in ipynb format;
  Papermill parameter tag requires a manual UI toggle.
- Fabric Source Control requires a manual trigger (Source Control pane → Update tab → Update All);
  commit pending local changes first.
