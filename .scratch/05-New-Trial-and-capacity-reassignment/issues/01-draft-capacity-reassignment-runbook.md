# 01: Draft the capacity reassignment runbook

**What to build:** A move-day checklist Pat can follow step by step to reassign all four workspaces (Landing, Dev, Test, Prod) from the expiring trial capacity to the new one, and that can be reused at the next trial rotation (~2026-11-24). It covers:
- the prerequisites for the new trial owner (`user8`): Entra Fabric Administrator role, Fabric (Free) license, trial region UK South;
- the primary route: bulk reassignment from the admin portal's capacity settings;
- the fallback route: `user7` reassigns each workspace from its settings;
- the rule to leave the old trial alive until validation passes, because items that fail to migrate stay attached to it;
- the post-move validation steps and the baseline counts from the parent spec.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The runbook exists in `Context/` and uses the glossary terms **Capacity** and **Capacity reassignment**.
- [ ] Every step names who does it (Pat or CC) and where (Fabric portal, admin portal, MCP).
- [ ] The step order, fallback route, "don't cancel the old trial" rule and validation checks all match the parent spec's decisions.
- [ ] Anything specific to a single rotation (capacity IDs, dates, user number) is a parameter, so the runbook can be reused.
