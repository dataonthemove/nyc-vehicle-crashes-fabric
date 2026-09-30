# 03: Recruiter-facing README

**What to build:** A visitor landing on the repo understands the project in under a minute. The
root README opens with, in order:

- a one-paragraph pitch;
- the embedded architecture PNG from `DIagrams/`;
- a "what this demonstrates" list (for example: Fabric end to end, Kimball star schema with a
  bridge, Direct Lake on SQL, CDC orchestration, TMDL-in-git, stage deployment, governed
  agent-assisted development);
- a **"Nature of this repo"** notice. It states that this is a personal demonstration project on
  Fabric trial capacity using public NYC Open Data, and that it holds no credentials. Fabric and
  tenant IDs, working notes and the backlog are published unredacted on purpose, because they
  grant no access and they show the working process. It also says the repo is a read-only mirror
  of the Azure DevOps origin, so issues and PRs aren't monitored.

The existing architecture and repo-layout tables are kept below. One README serves both ADO and
GitHub. Use `CONTEXT.md` vocabulary throughout. See the parent spec:
`.scratch/github-showcase-mirror/spec.md`.

**Blocked by:** None (can start immediately). The GitHub render check needs ticket 02 to be live.

**Status:** ready-for-agent

- [x] The README opens with the pitch, diagram, demonstrates list and "Nature of this repo" notice, in that order.
- [x] The notice covers all of: demonstration project, trial capacity, public data, no credentials, IDs and working notes unredacted on purpose, read-only mirror of ADO.
- [x] The existing architecture and repo-layout tables are kept and still accurate.
- [ ] The diagram renders in ADO's file view.
- [ ] After the next mirror run, the diagram and notice render on GitHub.

## Comments

- 2026-09-30 (CC): README rewritten. Layout table corrected: `0_Storage/` path, added
  `6_Orchestration/` row plus an Orchestration architecture row, and dropped `2_dev/5_Reports/`
  because no report definitions are in the repo yet. The diagram uses a relative link, so it
  renders in ADO and GitHub. Open: Pat to check the ADO render, then the GitHub render after 02.
