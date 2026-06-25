---
description: Run the Fabric change deployment checklist — MCP state pull, git hygiene, push verification, and Source Control sync reminder
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*), Bash(git ls-files:*), mcp__ms-fabric-mcp-server__list_workspaces, mcp__ms-fabric-mcp-server__list_items, mcp__ms-fabric-mcp-server__get_item
---

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`
- Files with uncommitted changes: !`git diff --name-only HEAD`
- Manually exported semantic model folder (must be empty): !`git ls-files Semantic_model/ 2>/dev/null || echo "(none)"`

## Your task

Run the full Fabric change deployment checklist. Report each step as **DONE**, **PENDING**, or **BLOCKED** with a one-line note.

---

### Step 1 — Pull current Fabric state via MCP

Call `list_workspaces`, then `list_items` for the relevant workspace. Confirm the artifact being changed is in its expected state before any edits are applied. If state is unexpected, stop and report.

### Step 2 — Verify local edits

Summarize what has changed (staged or committed). If uncommitted changes exist, list the affected files and ask whether they should be staged.

### Step 3 — Pre-commit cleanliness

- Is the `Semantic_model/` folder tracked? (If yes: BLOCKED — delete it; only the GUID-named `*.SemanticModel/` folder is valid)
- Are the changes limited to the GUID-named `*.SemanticModel/definition/tables/` folder (or other valid Fabric-watched paths)?

### Step 4 — Commit and push to Azure DevOps

- Are changes committed with a descriptive message?
- Has `git push` to the Azure DevOps remote been executed?

### Step 5 — Fabric Source Control sync (MANUAL — cannot be automated)

**This step requires browser action. Flag as PENDING until user confirms.**

1. Open the Fabric workspace in browser
2. Source Control pane → **Update tab** → **Update All**

Remind the user to confirm this step before marking the deployment complete.
