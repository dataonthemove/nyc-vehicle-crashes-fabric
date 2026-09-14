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
- `Context Docs/BACKLOG.md` — current backlog. Read it at the start of any session that
  continues project work, and update it when items are closed or added.
- `Context Docs/environment-reference.md` — live workspace/artifact IDs. All IDs there are
  **physical** Fabric IDs; the repo's Fabric item files carry *logical* IDs, which are
  different values. Never copy IDs from repo files into that doc.


## Fabric SDLC Process Flow (ALWAYS apply to Fabric project work)

Canonical diagram: Draw.io file `Process_Flow_SDLC_v24.drawio` in repo folder
`DIagrams/Process_Flow_SDLC/` (PNG export alongside it). Step numbers below are that diagram's.

Phases: `I Plan & Setup → II Scaffold & Synchronize → III Development (Dev) → IV Integration & QA →
V Release & Monitor`. Report development is a separate downstream workflow, handed off only after
the Prod semantic model is endorsed (Step 33).

- **Git is the source of truth; MCP is run/read/validate only.** MCP acts on *workspace* state, so
  anything it creates bypasses Git and PR review and leaves invisible repo/workspace drift. Sanctioned
  MCP use is Steps 16, 17, 22, 30, 34 — pipeline runs, Livy/Spark, `refresh_semantic_model`,
  validation DAX, job polling. The sole exception is Step 5: seeding an empty repo with empty
  artifact shells, committed from the Fabric UI at Step 7.
- **Authoring path:** local TMDL / T-SQL / pipeline JSON in VSC or CC (Step 13) → commit/push to ADO
  (Step 14) → Fabric Source Control **Update** (Step 15; manual — no auto-commit exists) → MCP
  validation (Steps 16–17). Local edits are invisible to Fabric until pushed *and* pulled; items
  committed from the Fabric UI are invisible locally until pulled.
- **Specs are versioned artifacts.** ADRs, source-to-target mappings, measure definitions and pipeline
  specs are Markdown in the repo, merged in the same PR as the code they describe. Step 1 is one-off
  inception; **Step 9 is the recurring re-entry point** that every feedback, defect and rollback loop
  returns to.
- **Plan before authoring.** CC plan mode drafts the change plan against the Step 9 specs (Step 12);
  no TMDL, T-SQL or pipeline JSON is written until the plan is approved, and the approved plan is
  committed into the spec set.
- **Branching:** `main` + short-lived feature branches only — no test/prod branches. Test and Prod
  content arrives via deployment pipelines; Git binding applies only to Dev-stage workspaces. Create
  feature work with Fabric SC → "Branch out to new workspace" (Step 10: creates the branch in ADO and
  the Personal Dev WS together), then fetch/checkout locally (Step 11). Branch-out copies item
  definitions only — **not data, connections or bindings** — so lakehouses and warehouses arrive
  empty: repoint sources, re-create shortcuts and run the ingestion pipelines before validating.
  A Personal Dev WS needs capacity assigned at creation.
- **Pre-PR sync check is one-directional (Steps 18–19).** Commits the branch holds ahead of main are
  the PR payload and do not count; the gateway asks only whether main holds commits the branch lacks.
  Answer it read-only: `git fetch origin` then `git rev-list --count feature/x..origin/main`. Zero →
  raise the PR (Step 20). Anything else → merge or rebase main into the branch, resolve TMDL and
  pipeline JSON conflicts **as text in VSC** (Fabric cannot), re-push, re-validate in the Personal WS,
  and re-test the gateway in case main moved again.
- **Integration failure = roll back, not fix forward (Step 23).** Revert the merged PR in ADO
  (`git revert -m 1`), re-Update the Shared Integration WS to the restored state, and re-work the
  defect on a fresh feature branch. Revert, never reset.
- **Release:** Dev → Test deploy (Step 24) → bind data sources and set credentials for Test (Step 25)
  → validate → triage a failure as *deployment config* (fix value set / Deployment Rules, redeploy)
  vs *code defect* (new feature branch) → tag the **exact commit deployed to Test**, not the newest on
  main (Step 26) → Test → Prod deploy (Step 27) → bind sources and credentials for Prod (Step 28) →
  assign Prod WS RBAC and semantic model RLS role membership (Step 29 — membership cannot be granted
  against a model that does not yet exist in Prod) → post-deployment verification (Step 30) →
  endorse (Step 33) → monitor (Step 34).
- **Prod rollback has no one-click path (Step 31).** Revert the PRs merged since the previous release
  tag, newest first; the failed tag stays on main as history, the previous verified tag becomes the
  Prod record, and the fix ships under a new tag. The Prod WS is not Git-bound, so the last verified
  tag — not the newest — is the authoritative record of what is in Prod.
- **Deployment pipelines carry item structure and metadata only** — no data. Standing rule: what the
  pipeline does not copy it also does not clear, so endorsement, bindings/credentials and RBAC/RLS
  membership persist once set — first-release and on-change actions, never per promotion. Pipeline
  creation and stage assignment are one-off setup outside the release loop (Step 3).
- **Environment-specific values come from the Variable Library** (Git-versioned Fabric item, scaffolded
  at Step 5, one value set per stage), so no hard-coded IDs travel between Dev, Test and Prod.
  Deployment Rules are the fallback. The active set is stage configuration, not part of the item
  definition, so a promotion does not touch it — spot-check it after each deploy.
- **Connections, gateways and OneLake shortcuts are not in Git** and are carried neither by deployment
  pipelines nor by branch-out — every stage and every Personal Dev WS needs its own (Step 6). Binding
  an item to them is a separate act (Steps 25, 28); Direct Lake models never autobind.
- **RLS/OLS roles live in TMDL**, so they are authored, committed and PR-reviewed like any other code
  (Step 13) and tested with "View as role" before the PR. Role *membership* is separate and assigned
  per workspace (Step 29).
- **Endorsement is manual and persists.** Apply Promoted/Certified on the Prod semantic model at first
  release only, repeated when the level is deliberately changed or withdrawn. Certification requires a
  tenant-designated certifier.
- **Clean up at Step 32** — delete the merged feature branch in ADO and delete or unbind the Personal
  Dev WS, once the release is verified in Prod. A branch abandoned earlier (at integration, Test triage
  or Prod verification) never reaches Step 32, so clean it up on the way back to Step 9.
- Commit message body: `[domain]_[artifact]_[action]`. Surface prefixes: `VSC Commit:` · `CC Commit:` ·
  `ADO Commit:` · `Fab Commit:`.

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

