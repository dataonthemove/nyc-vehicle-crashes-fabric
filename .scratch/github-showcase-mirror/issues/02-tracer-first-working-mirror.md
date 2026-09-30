# 02: Tracer — first working mirror to GitHub

**What to build:** A manual run of a new ADO pipeline publishes the full ADO `main` history to a
new public GitHub repo. Nothing is stripped out. The only change is that commit authors are
normalised, so every commit is credited to Pat's GitHub account. ADO stays the only repo anyone
commits to. `CLAUDE.md` records that GitHub is a read-only mirror, so no future session pushes
to it or edits it directly.

The work is split between Pat and CC:

- **Pat (GitHub):** create an empty public repo, with no README or licence, and turn off Issues,
  Wiki and Projects. Create a fine-grained PAT scoped to that repo only, with Contents set to
  read and write, and note its expiry.
- **CC (repo):** in a new top-level ops folder outside `1_Landing/` and `2_dev/`, write:
  - the mailmap, which maps the `Jpb_fabric_user*` UPNs and the mixed-case outlook address to
    `dataonthemove@outlook.com`;
  - the exclusion list, empty and wired to `--invert-paths`;
  - the pipeline YAML. It triggers on `main` and allows a manual run, checks out the full
    history, installs `git filter-repo` through pip, runs it with the mailmap and force-pushes
    `main` to GitHub using the PAT secret.

  CC also adds the read-only-mirror rule to `CLAUDE.md`, then commits.
- **Pat (ADO):** push, register the pipeline from the YAML, add the PAT as a secret variable,
  and run it manually.

See the parent spec: `.scratch/github-showcase-mirror/spec.md`.

**Blocked by:** 01 (Confirm ADO can run hosted pipelines).

**Status:** ready-for-agent

- [ ] The GitHub repo exists: public and empty before the first run, with Issues, Wiki and Projects off. Pat's other repos are untouched.
- [ ] The PAT is fine-grained and scoped to this repo only. Its expiry date is recorded under Comments.
- [ ] The mailmap, the empty exclusion list and the pipeline YAML are committed outside the Fabric Git-bound folders. Fabric Source Control shows nothing new.
- [ ] The PAT exists only as an ADO secret variable. It doesn't appear in the repo or in the pipeline logs.
- [ ] `CLAUDE.md` has the rule: GitHub is a read-only mirror, everything is public unless it's added to the exclusion list, and nobody pushes to GitHub directly.
- [ ] The manual pipeline run is green.
- [ ] On GitHub, every top-level ADO folder is present and the `main` commit count equals ADO's.
- [ ] On GitHub, no commit author shows an `@onmicrosoft.com` address; all resolve to Pat's account.
- [ ] A second manual run with no new commits leaves GitHub's head SHA unchanged.
