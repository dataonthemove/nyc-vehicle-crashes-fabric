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
- Report authoring: Fabric web UI only — Power BI Desktop is not used for report development.
  Reason: `byConnection` + Warehouse-backed Direct Lake in PBID causes Direct Lake framing errors;
  DirectQuery fallback is unavailable for Warehouse-backed models.
  - Semantic model changes: local TMDL edits → commit/push to ADO → Fabric Source Control → Update All.
  - Report changes: Fabric web UI → Fabric Source Control syncs to ADO automatically.
  - Repo folder `3_SemanticModels/` is the authoritative source for semantic model development.
  - Repo folder `4_Reports/` is read-only locally — never author or edit report files on disk.

## SDLC Process Flow
Full phase sequence: `PLAN → SETUP → SCAFFOLD → DEV → INTEGRATE → REPORT → RELEASE → MONITOR`.
Diagram source: `Misc_Stuff/Fabric_SDLC_Process_Flow.md`.
- **Scaffold vs Author vs MCP-only** are distinct: scaffolding creates empty Fabric artifact
  containers via MCP (`create_lakehouse`, `create_pipeline`, etc.); authoring fills them via
  git-first local TMDL/T-SQL/pipeline-JSON edits; a separate MCP-only step covers operations with
  no local file equivalent (Livy/Spark execution, `refresh_semantic_model`, DAX validation queries,
  job status polling).
- **Core dev loop**: author → MCP-only ops → (more dev needed? loop to author) → git push →
  Fabric Source Control Update → validate (row counts / DAX / pipeline runs) → (validation passed?
  loop to author : continue). Failures at any later stage loop back to the authoring step.
- **Report sub-phase** is gated on a stable semantic model and stays in the Fabric web UI only
  (see Report authoring rule above). Reports sync to ADO automatically via Fabric Source Control.
- **Release path**: PR review/merge in ADO → deployment pipeline Dev→Test (validate) → Test→Prod
  (change-controlled). A failed Test stage loops back to the authoring step, not a hotfix branch.
- Commit message convention: `[domain]_[artifact]_[action]`.

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
