# 04: Rerun safety and failure gate

**What to build:** Evidence that the Stage load is safe to rerun and never refreshes a half-loaded star.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Spec Test 2: a second run with no new landed files succeeds, and every Delta and Warehouse count is unchanged
- [ ] Spec Test 3: with one Transform activity forced to fail in a throwaway branch workspace (never Dev), the run is Failed and Refresh did not execute
- [ ] The failing activity is identifiable from the Monitor hub run history
- [ ] The throwaway branch and workspace are cleaned up (CLAUDE.md SDLC rule 10)
