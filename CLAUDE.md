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
  - Fabric Git Integration watches only the `*.SemanticModel/definition/` tree — here
    `2_dev/4_Model/NYC_VehicleCrashes_Semantic.SemanticModel/definition/`. The folder is **display-named**,
    not GUID-named; the GUID is the `logicalId` inside `.platform`.
  - Do NOT use MCP/XMLA edits for routine semantic model changes — they don't reliably persist
    to the Git-managed layer. Workflow: edit the `definition/` TMDL files locally → commit/push →
    Fabric Source Control pane (Update tab → Update All).
  - Manually exported folders (e.g. `Semantic_model/`) are NOT watched by Git Integration — delete them.
  - The official `fabric-authoring`/`powerbi-authoring` plugin's `semantic-model-authoring` skill
    defaults to its Tier-1 priority (`powerbi-modeling-mcp` MCP edits) whenever the MCP server is
    registered — which it always is here. Override this: force the local-TMDL-file workflow above
    instead of letting the skill fall through to MCP.
- **Cosmetic workspace drift — commit it, do not fight it.** Fabric re-serializes items on load,
  so the Source Control pane shows `NYC_VehicleCrashes_Semantic` and `NYC_VehicleCrashes_Warehouse`
  as Modified with nobody having touched them. Update All will NOT clear these: Update overwrites
  the workspace from git, the service immediately re-emits its own canonical form, and the flag
  returns. It is a fixed point unreachable from the git side.
  - Classify **per item** before acting. Cosmetic = `lineageTag` injection, TMDL/JSON reordering,
    whitespace — no measure, column, relationship, table or stored-procedure semantics changed.
  - Cosmetic → **Commit all**, selecting only those items. Git absorbs Fabric’s serialization and
    the flag clears permanently. This is the one sanctioned exception to local-code-first.
  - Substantive → real UI drift: do not commit it. Fix the TMDL/SQL locally, push, then Update All.
  - Never blanket-commit every flagged item without classifying each one — that is how genuine UI
    drift gets laundered into the repo.
- Watermark: single authoritative store is Delta table `etl_watermark` in Fabric Lakehouse
  `NYC_VehicleCrashes_Landing_Lakehouse` (landing workspace), written **only** by Fabric Notebook
  `nb_etl_watermark` (PySpark) — the lakehouse SQL analytics endpoint is read-only, so no Script
  activity may write it. Consumers read it through that SQL endpoint.
  Warehouse `dbo.etl_watermark` is the legacy store; it stays in place and authoritative until the
  ingestion move (landing-zone Phase 6) cuts over, then is retired. Do not write both.
- Report authoring: Fabric web UI only — Power BI Desktop is not used for report development.
  Reason: `byConnection` + Warehouse-backed Direct Lake in PBID causes Direct Lake framing errors;
  DirectQuery fallback is unavailable for Warehouse-backed models.
  - Semantic model changes: local TMDL edits → commit/push to ADO → Fabric Source Control → Update All.
  - Report changes: Fabric web UI → Fabric Source Control syncs to ADO automatically.
  - Repo folder `2_dev/4_Model/` is the authoritative source for semantic model development.
  - Repo folder `2_dev/5_Reports/` is read-only locally — never author or edit report files on disk.

## Working Docs
- Backlog: issues live under `.scratch/` per `docs/agents/issue-tracker.md`. Read open issues
  at the start of any session that continues project work, and update them when closed or added.
- `Context/environment-reference.md` — live workspace/artifact IDs. All IDs there are
  **physical** Fabric IDs; the repo's Fabric item files carry *logical* IDs, which are
  different values. Never copy IDs from repo files into that doc.


## Fabric Warehouse — T-SQL Constraints (ALWAYS apply)
- No PRIMARY KEY, UNIQUE, or FOREIGN KEY constraints. No inline constraints in `CREATE TABLE`.
- No TINYINT — use SMALLINT.
- IDENTITY syntax: `BIGINT IDENTITY` only — no seed/increment params (`IDENTITY(1,1)` fails).
- Drop-if-exists: use `OBJECT_ID` check pattern.
- No `MAXRECURSION` hint; no cross-joins on `sys.all_objects`. For row generation, cross-join
  `(VALUES (0),(1),...,(9))` table constructors as derived tables (not chained CTEs) and trim with
  a `WHERE`/`DATEDIFF` predicate — set-based, avoids both restrictions. Do NOT use `WHILE` loops:
  `dim_date` took 29 minutes for 5,479 rows that way.
- `DATETIME2` columns require explicit precision, e.g. `DATETIME2(6)`.
- Cross-database lakehouse references use the lakehouse name directly (SQL analytics endpoint = same object).
- **Stored procedures exist twice in the repo** — the authoring notebook under `2_dev/3_Transform/` and
  the Fabric-exported Warehouse item definition under
  `2_dev/0_NYC_VehicleCrashes_Warehouse.Warehouse/etl/StoredProcedures/`. The notebook is the source of
  truth; the item definition is what the Dev→Test deployment pipeline actually promotes. Change
  **both in the same commit** or the two silently diverge — running the notebook masks a stale item
  definition completely, so a green validation proves nothing about the deployed copy.

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

## Permission Settings — Layer Roles (ALWAYS apply)
Three settings layers merge; precedence is **deny > ask > allow > defaultMode**, and the
layers union. Put each rule in exactly one layer, per its role:

| Layer | Path | Tracked | Role |
|---|---|---|---|
| Global | `~/.claude/settings.json` | no | Machine-wide safety net + universal read-only conveniences. True for every repo. |
| Project shared | `.claude/settings.json` | **yes** | This project's governance + Fabric MCP surface. Anything encoding a rule in this file. |
| Project local | `.claude/settings.local.json` | no | Machine-specific and throwaway only. Short enough to read at a glance. |

- **Standing rule:** allow entries must be recurring prefix patterns, never one-shot literal
  commands. `/fewer-permission-prompts` generates the latter — review before accepting.
- Never grant `Bash(python *)` / `Bash(node *)`: arbitrary local execution voids the
  `rm:*` / `git reset --hard:*` / `git clean:*` denies and bypasses `ask(Edit|Write)`.
- The deny list protects the **local machine and this repo**. It makes no claim about the
  Fabric workspace, which Fabric RBAC governs — that is why `livy_run_statement` stays allowed.
- The MCP governance rules above (TMDL-first authoring, MCP as run/read/validate only) are now
  **enforced** by the `deny` block in `.claude/settings.json`. Relax one and you must relax the
  other in the same commit, or the file and the enforcement silently disagree.
- `model_operations` and `database_operations` are `ask`, not deny: each multiplexes sanctioned
  and forbidden operations behind one `operation` parameter, and rules match on tool name only.


## Agent skills


### Issue tracker
Issues live as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.


### Triage labels
Default five canonical labels (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.


### Domain docs
Single-context: one root `CONTEXT.md` plus `docs/adr/`. See `docs/agents/domain.md`.
