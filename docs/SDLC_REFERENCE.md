Good approach. Here's the textual summary — ready to commit to your repo and load into memory:

---

## Fabric End-to-End SDLC Reference

**Tool key:** CLI = CC CLI (terminal) | EXT = VSC extension | BOTH = CLI + EXT | SYS = Fabric / DevOps / Git

| # | Step | Tool | Notes |
|---|------|------|-------|
| 1 | Scope and architect solution | CLI | Output: ADR/spec markdown committed to repo |
| 2 | Create Azure DevOps repo; clone; initialise Git | SYS | One-time. Establish dev/test/prod branch strategy |
| 3 | Link Fabric workspace to DevOps repo | SYS | Fabric Git Integration. One-time per workspace |
| 4 | Configure MCP servers in CC CLI | SYS | ms-fabric-mcp-server + powerbi-modeling-mcp; opt-in per session |
| 5 | Scaffold empty Fabric artifact shells via MCP | CLI | create_lakehouse, create_pipeline, create_notebook, create_dataflow, create_semantic_model. Containers only |
| 6 | Author TMDL, T-SQL, pipeline JSON locally in VSC | BOTH | EXT: inline edits on open files. CLI: generate boilerplate, DAX, stored procs |
| 7 | Execute MCP-only operations | CLI | Pipeline runs, Livy/Spark, refresh_semantic_model, DAX validation, job polling |
| D1 | More dev needed? | — | Yes → back to step 6. No → step 8 |
| 8 | Git commit and push to Azure DevOps | SYS | TMDL, T-SQL, JSON, markdown only |
| 9 | Fabric Source Control: Update workspace from repo | SYS | Pull latest into Dev workspace |
| 10 | Validate: row counts, DAX, pipeline results | CLI | MCP DAX queries, Livy row counts, job status |
| D2 | Validation passed? | — | No → back to step 6. Yes → step 11 |
| 11 | Pull request review and merge in Azure DevOps | SYS | Peer review of TMDL, T-SQL, pipeline JSON |
| D3 | PR approved? | — | No → back to step 6. Yes → step 12 |
| 12 | Promote to Test via Fabric deployment pipeline | SYS | Dev → Test stage. Validate in Test workspace |
| D4 | Test passed? | — | No → back to step 6. Yes → step 13 |
| 13 | Promote to Prod via Fabric deployment pipeline | SYS | Test → Prod. Change-controlled release |
| 14 | Monitor, triage, iterate | CLI | MCP job status, pipeline runs, Livy logs. Failures loop to step 6 |

**Core loop:** Steps 6 → 7 → D1 → 8 → 9 → 10 → D2 are the primary development iteration cycle, repeated until validation passes.

---

Save this as `SDLC_REFERENCE.md` in your repo, then paste it back and ask me to remember it.