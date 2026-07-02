# Microsoft Fabric End-to-End SDLC Process Flow

A reference for developing end-to-end solutions in Microsoft Fabric using Claude Code (CC) across two surfaces — the **terminal CLI** and the **VSC extension** — integrated with Git (VSC), Azure DevOps (ADO), and the Fabric interface.

## Tool Key

| Tag | Meaning |
|-----|---------|
| **CLI** | CC CLI (terminal) |
| **EXT** | VSC extension |
| **BOTH** | CLI + VSC extension |
| **SYS** | Fabric / DevOps / Git |

## Phases

`PLAN → SETUP → SCAFFOLD → DEV → INTEGRATE → REPORT → RELEASE → MONITOR`

## Process Steps

| # | Phase | Step | Tool | Notes |
|---|-------|------|------|-------|
| 1 | PLAN | Scope and architect solution | CLI | Model schema, pipeline design, DAX strategy. Output: ADR / spec committed as markdown to repo |
| 2 | SETUP | Create Azure DevOps repo; clone locally; initialise Git | SYS | One-time. Establish dev / test / prod branch strategy |
| 3 | SETUP | Link Fabric workspace to DevOps repo (Git Integration) | SYS | One-time per workspace |
| 4 | SETUP | Configure MCP servers in CC CLI | SYS | `ms-fabric-mcp-server` + `powerbi-modeling-mcp`; opt-in per session to control token cost |
| 5 | SCAFFOLD | Scaffold empty Fabric artifact shells via MCP | CLI | `create_lakehouse`, `create_pipeline`, `create_notebook`, `create_dataflow`, `create_semantic_model`, `create_folder`. Containers only — no content yet |
| 6 | DEV | Author TMDL, T-SQL, pipeline JSON locally in VSC | BOTH | EXT: co-author on open files (inline assist). CLI: generate boilerplate, stored procs, DAX measures, pipeline JSON blocks |
| 7 | DEV | Execute MCP-only operations (no local file equivalent) | CLI | Pipeline runs, Livy/Spark statements, `refresh_semantic_model`, DAX validation queries, job status polling |
| 8 | INTEGRATE | Git commit and push to Azure DevOps | SYS | TMDL, T-SQL, pipeline JSON, markdown only. Commit follows `[domain]_[artifact]_[action]` |
| 9 | INTEGRATE | Fabric Source Control: Update workspace from repo | SYS | Pull latest from DevOps into Dev workspace |
| 10 | INTEGRATE | Validate: row counts, DAX queries, pipeline run results | CLI | MCP DAX queries, job status checks, Livy row count statements |
| 11 | REPORT | Author reports exclusively in Fabric web UI | SYS | Depends on a **stable** semantic model. Do NOT author locally — PBID friction with the semantic model and Direct Lake causes problems |
| 12 | REPORT | Fabric Source Control syncs web reports to ADO automatically | SYS | Report definitions committed to repo without manual export |
| 13 | REPORT | Pull locally for Git history only | SYS | `git pull` to retain version history. NEVER edit report files locally with Power BI Desktop |
| 14 | REPORT | Report validation | CLI | Verify visuals, measures, filters, and Direct Lake behaviour in the web UI |
| 15 | RELEASE | Pull request review and merge in Azure DevOps | SYS | Peer review of TMDL, T-SQL, pipeline JSON, report definitions. Merge on approval |
| 16 | RELEASE | Promote to Test via Fabric deployment pipeline | SYS | Deployment pipeline stage (Dev → Test). Validate in Test workspace |
| 17 | RELEASE | Promote to Prod via Fabric deployment pipeline | SYS | Deployment pipeline stage (Test → Prod). Change-controlled release |
| 18 | MONITOR | Monitor, triage, and iterate | CLI | MCP job status, pipeline activity runs, Livy session logs. Failures loop back to step 6 |

## Decision Points

| ID | After Step | Decision | Yes → | No → |
|----|-----------|----------|-------|------|
| **D1** | 7 | More dev needed? | Loop back to step 6 (iterate) | Continue to step 8 |
| **D2** | 10 | Model / data validation passed? | Continue to step 11 (model stable) | Loop back to step 6 (fix) |
| **D-report** | 14 | Need more report dev? | Loop back to step 11 (iterate report) | Continue to step 15 |
| **D3** | 15 | PR approved? | Continue to step 16 | Loop back to step 6 (revise) |
| **D4** | 16 | Test passed? | Continue to step 17 | Loop back to step 6 (fix) |
| **Monitor loop** | 18 | Failure detected? | Loop back to step 6 (new dev cycle) | — |

## Key Principles

- **Scaffold vs Author vs MCP-only:** Step 5 creates empty containers; step 6 fills them via git-first local editing; step 7 covers only operations with no local file equivalent.
- **Routine semantic model edits** go through TMDL → VSC → git → Fabric Source Control — not MCP/XMLA.
- **Report authoring is a distinct sub-phase** gated on a stable semantic model, and is done exclusively in the Fabric web UI due to PBID/Direct Lake friction.
- **The core development loop** is steps 6 → 7 → D1 → 8 → 9 → 10 → D2, repeated until the model is stable.
- **Git commit/push (step 8) recurs** throughout development — it is not a one-time action.
