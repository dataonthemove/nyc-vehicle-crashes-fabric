---
name: fabric-sdlc
description: Step-by-step Fabric SDLC process flow (v24) for NYC_VehicleCrashes — the full 34-step path from spec through branch-out, authoring, PR, integration, Dev→Test→Prod promotion, tagging, endorsement and rollback, with the per-step surface (local Git, ADO, Fabric UI, CC/MCP). Use when planning or executing any step of the lifecycle. Triggers: "branch out", "raise the PR", "sync main", "deploy to Test", "promote to Prod", "release tag", "roll back", "endorse the model", "clean up the branch", "SDLC", "what step are we on".
---

# /fabric-sdlc

Full process detail behind the SDLC rules in repo file `CLAUDE.md`. The ten hard rules there always
apply; this skill supplies the step sequence, gateways and per-step surface.

Canonical diagram: Draw.io file `Process_Flow_SDLC_v24.drawio` in repo folder
`DIagrams/Process_Flow_SDLC/` (PNG export alongside it). Step numbers below are that diagram's.

Phases: `I Plan & Setup → II Scaffold & Synchronize → III Development (Dev) → IV Integration & QA →
V Release & Monitor`. Report development is a separate downstream workflow, handed off only after the
Prod semantic model is endorsed (Step 33).

## Phase I — Plan & Setup (one-off inception)

| Step | Action | Surface |
|---|---|---|
| 1 | Scope & architect: ADRs, source-to-target mappings, measure definitions as Markdown specs | CC → local Markdown |
| 2 | Create ADO repo, clone locally | ADO + local Git · main |
| 3 | Provision Dev/Test/Prod WSs, assign capacity, bind Shared Integration/Dev WS ↔ main, create the deployment pipeline and assign all three to stages | Fabric UI · main |
| 4 | Register MCP servers (`ms-fabric-mcp-server`, `powerbi-modeling-mcp`) in CC config | CC CLI config |

## Phase II — Scaffold & Synchronize (one-off)

| Step | Action | Surface |
|---|---|---|
| 5 | Scaffold empty artifact shells + the Variable Library via MCP — the **sole** sanctioned MCP write | CC/MCP · Shared Integration · main |
| 6 | Create source connections/gateways, land raw data, create OneLake shortcuts (a shortcut cannot precede its lakehouse) | Fabric UI · Shared Integration |
| 7 | Manual Fabric Source Control **Commit** of the scaffolded items — Fabric never auto-commits | Fabric UI · Shared Integration |
| 8 | Git pull locally to bring folder structures / TMDL / metadata into the clone | local Git · main |

## Phase III — Development (the recurring loop)

| Step | Action | Surface |
|---|---|---|
| 9 | **Refine requirements & specs — the re-entry point every feedback, defect and rollback loop returns to** | CC → local Markdown · main → feature/* |
| 10 | Fabric SC → Branches → "Branch out to new workspace": creates the ADO branch *and* the Personal Dev WS together | Fabric UI · Personal Dev · feature/* |
| 11 | `git fetch origin` · `git checkout feature/x` | local Git · feature/* |
| 12 | CC plan mode drafts the implementation plan against the Step 9 specs | CC → local plan Markdown |
| — | **Gateway: Plan approved?** No → revise plan (back to 12) | |
| 13 | Author TMDL, T-SQL, pipeline JSON, incl. RLS/OLS roles | CC/VSC → local files · feature/* |
| 14 | Commit & push to the feature branch in ADO | local Git · feature/* |
| 15 | Fabric SC **Update** (pull) into the Personal Dev WS | Fabric UI · Personal Dev |
| 16 | MCP-only operations: pipeline runs, Livy/Spark, `refresh_semantic_model`, validation DAX, job polling | CC/MCP · Personal Dev |
| 17 | Private validation loop: functional checks, smoke tests, "View as role" RLS/OLS checks | CC/MCP · Personal Dev |
| — | **Gateway: Private validation passed?** No → fix & re-validate (back to 13) | |
| — | **Gateway: More dev needed?** Yes → back to 13 on the same branch | |
| 18 | Fetch & compare with main — read-only: `git fetch origin`, then `git rev-list --count feature/x..origin/main` | local Git · feature/* |
| — | **Gateway: Branch includes all of main?** (one-directional — commits *ahead* of main are the PR payload and do not count). Zero → Step 20. Otherwise → Step 19 | |
| 19 | Sync main → feature branch: merge or rebase, resolve TMDL/JSON conflicts **as text in VSC** (Fabric cannot), re-push, re-validate in the Personal WS, re-test the gateway in case main moved again | local Git · feature/* |

**Branch-out caveat (note d):** branch-out copies item definitions only — not data, connections or
bindings. Lakehouses and warehouses arrive empty: repoint sources, re-create shortcuts and run the
ingestion pipelines (Step 16) before validating. A Personal Dev WS needs capacity at creation.

## Phase IV — Integration & QA

| Step | Action | Surface |
|---|---|---|
| 20 | PR: feature branch → main, including the spec and plan Markdown; peer review | ADO |
| 21 | Fabric SC **Update** the Shared Integration/Dev WS to the merged commit | Fabric UI · Shared Integration · main |
| 22 | Validate merged changes: integration queries, end-to-end pipeline runs, Livy row counts | CC/MCP · Shared Integration |
| — | **Gateway: Model/data validation passed?** No → Step 23 | |
| 23 | **Revert** the merged PR in ADO (`git revert -m 1`), re-Update the Shared WS to the restored state, re-work on a fresh feature branch. Revert, never reset | ADO · main |

## Phase V — Release & Monitor

| Step | Action | Surface |
|---|---|---|
| 24 | Promote Dev → Test via deployment pipeline | Fabric UI · Dev → Test |
| 25 | Bind data sources & set credentials (Test) | Fabric UI · Test |
| — | **Gateway: Test passed?** No → triage | |
| — | **Gateway: Code defect or deployment config?** Config → fix value set / Deployment Rules & redeploy. Defect → new feature branch; clean up the abandoned branch and Personal Dev WS | |
| 26 | Tag main on the **exact commit deployed to Test**, not the newest (e.g. `release/v1.2`) | ADO · main (tag) |
| 27 | Promote Test → Prod within a change-managed release window | Fabric UI · Test → Prod |
| 28 | Bind data sources & set credentials (Prod) | Fabric UI · Prod |
| 29 | Assign Prod WS RBAC and semantic model RLS role membership — impossible before the model exists in Prod | Fabric UI · Prod |
| 30 | Post-deployment verification: model refresh, validation DAX vs expected, connection and role checks | CC/MCP · Prod |
| — | **Gateway: Prod verification passed?** No → Step 31 | |
| 31 | Roll back Prod: revert the PRs merged since the previous release tag, newest first. The failed tag stays on main as history; the previous verified tag becomes the Prod record; the fix ships under a new tag | ADO · main |
| 32 | Clean up: delete the merged feature branch in ADO, delete or unbind the Personal Dev WS | ADO + Fabric UI |
| 33 | Endorse the Prod semantic model (Promoted / Certified) — manual, first release only | Fabric UI · Prod |
| 34 | Monitor, triage & iterate: CC diagnostics, pipeline activity polling, Spark/Livy logs. Feedback → backlog → Step 9 | CC/MCP · Prod |

## Standing details behind the steps

- **Deployment pipelines** copy item structure and metadata only — no data. What the pipeline does not
  copy it also does not clear, so endorsement, bindings/credentials and RBAC/RLS membership persist
  once set: first-release and on-change actions, never per promotion.
- **Variable Library** (Git-versioned item, scaffolded at Step 5) holds environment-specific values as
  named sets, one per stage, so no hard-coded IDs travel between Dev, Test and Prod. The active set is
  stage configuration, not part of the item definition — a promotion does not touch it, so spot-check
  it after each deploy. Deployment Rules are the fallback.
- **Connections, gateways and OneLake shortcuts** are not in Git and are carried neither by deployment
  pipelines nor by branch-out — every stage and every Personal Dev WS needs its own. Binding an item to
  them is separate (Steps 25, 28); Direct Lake models never autobind.
- **RLS/OLS roles** live in TMDL, so they are authored, committed and PR-reviewed like any other code
  (Step 13) and tested with "View as role" before the PR. Membership is separate (Step 29).
- **Cleanup timing:** Step 32 runs once the release is verified in Prod, so the branch and workspace
  stay available through Test and Prod. A branch abandoned earlier — at integration, Test triage or
  Prod verification — never reaches Step 32, so clean it up on the way back to Step 9.
- **Endorsement** persists across promotions; repeat only when the level is deliberately changed or
  withdrawn. Certification requires a tenant-designated certifier.
- **Automation candidate:** the manual workspace Update at Steps 15 and 21 is scriptable via the
  Fabric Git REST API.
- **Commit messages:** surface prefix — `VSC Commit:` · `CC Commit:` · `ADO Commit:` · `Fab Commit:` —
  then body `[domain]_[artifact]_[action]`.
