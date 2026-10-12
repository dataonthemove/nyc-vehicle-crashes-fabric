# 05: Promote to Prod and close

**What to build:** Prod carries the same measure layer as Test, validated the same way, and the spec is closed.

**Blocked by:** 04

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Deploy Test → Prod via the deployment pipeline, selecting only the semantic model | Pat | Deployment succeeds; Warehouse not in the deployed set | todo |
| 2 | `refresh_semantic_model` on Prod to frame | CC | Refresh completes | todo |
| 3 | Metadata check: 38 measures (2 hidden), each with description, format string and display folder; the 10 columns hidden | CC | All hold | todo |
| 4 | Re-run the validation queries from tickets 01–03 on Prod | CC | All hold; figures in Comments | todo |
| 5 | Run `/dax-smoke-test` on Prod | CC | All checks pass | todo |
| 6 | Update the environment reference's last-deploy line; set the spec to `Status: done (date)`; commit | CC | Both updated and committed | todo |

## Comments
