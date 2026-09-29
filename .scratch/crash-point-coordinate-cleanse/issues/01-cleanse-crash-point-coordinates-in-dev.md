# 01: Cleanse crash-point coordinates in Dev

**What to build:** Map visuals over `Fact Crashes` in Dev frame on NYC. Every crash point that is
(0, 0) or outside the NYC bounding box (lat 40.49–40.92, lon −74.27 to −73.68) is stored as NULL.
`etl.usp_load_fact_crashes` does this with one idempotent trailing UPDATE, and the bounds are declared
as variables. The same change goes into both repo copies of the proc in one commit, so a later
promotion carries it to Test and Prod. Crash, injury and fatality counts don't change. See the
parent spec: `.scratch/crash-point-coordinate-cleanse/spec.md`.

**Blocked by:** None (can start immediately).

**Status:** in-progress

- [x] Dev baseline captured via Spark before any change: total rows, NULL, (0, 0), in-box and outside-box counts.
- [x] Bounds variables and the trailing UPDATE added to the authoring notebook proc, with an intent comment. Fabric notebook formatting is preserved.
- [ ] The Warehouse item definition proc has an identical change, in the same commit as the notebook, pushed to ADO.
- [ ] The proc is altered in Dev after Source Control Update All.
- [ ] Dev Stage load run; semantic model refreshed if the pipeline's Refresh activity failed.
- [ ] Dev profile: (0, 0) = 0, non-NULL outside the box = 0, only one coordinate NULL = 0.
- [ ] Dev profile: in-box count unchanged; NULL count = baseline NULL + (0, 0) + outside-box; total rows unchanged apart from genuinely new collisions.
- [ ] `/dax-smoke-test` is all green on Dev.
- [ ] The proc is rerun in Dev and the profile is identical (idempotent).
- [ ] Outcome recorded under `## Comments` in the spec. Test and Prod are not run.
