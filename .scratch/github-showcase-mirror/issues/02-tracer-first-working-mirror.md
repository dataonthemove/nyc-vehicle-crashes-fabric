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

## Steps and owners

| # | Step | Who | Status |
|---|---|---|---|
| 1 | Create empty public GitHub repo `dataonthemove/nyc-vehicle-crashes-fabric` (no README/licence/.gitignore) | Pat | done 2026-09-30 (renamed to drop a leading hyphen) |
| 2 | Turn off Issues, Wiki, Projects and Pull requests in repo Settings → General | Pat | done 2026-09-30 |
| 3 | Create fine-grained PAT: this repo only, Contents read and write | Pat | done 2026-09-30 (expiry date: record under Comments) |
| 4 | Write author-normalisation rule, empty exclusion list and pipeline YAML in the ops folder | CC | done 2026-09-30 |
| 5 | Add the GitHub read-only-mirror rule to `CLAUDE.md` | CC | done 2026-09-30 |
| 6 | Commit steps 4–5 | CC | done 2026-09-30 |
| 7 | Push to ADO | Pat | done 2026-09-30 |
| 8 | ADO → Pipelines → New pipeline → Azure Repos Git → existing YAML; select the mirror YAML | Pat | done 2026-09-30 |
| 9 | Add pipeline variable `GITHUB_PAT`, ticked **Keep this value secret**; paste the PAT (regenerate if lost) | Pat | done 2026-09-30 |
| 10 | Run the pipeline manually; share the log if it fails | Pat | done 2026-09-30 |
| 11 | Verify on GitHub: all folders, commit count equals ADO, authors credited to Pat | Pat + CC | done 2026-09-30 |
| 12 | Run again with no new commits; confirm GitHub head SHA unchanged | Pat | |

**Blocked by:** 01 (Confirm ADO can run hosted pipelines).

**Status:** ready-for-agent

- [x] The GitHub repo exists: public and empty before the first run, with Issues, Wiki and Projects off. Pat's other repos are untouched.
- [ ] The PAT is fine-grained and scoped to this repo only. Its expiry date is recorded under Comments.
- [x] The author-normalisation rule, the empty exclusion list and the pipeline YAML are committed outside the Fabric Git-bound folders. Fabric Source Control shows nothing new.
- [x] The PAT exists only as an ADO secret variable. It doesn't appear in the repo or in the pipeline logs.
- [x] `CLAUDE.md` has the rule: GitHub is a read-only mirror, everything is public unless it's added to the exclusion list, and nobody pushes to GitHub directly.
- [x] The manual pipeline run is green.
- [x] On GitHub, every top-level ADO folder is present and the `main` commit count equals ADO's.
- [x] On GitHub, no commit author shows an `@onmicrosoft.com` address; all resolve to Pat's account.
- [ ] A second manual run with no new commits leaves GitHub's head SHA unchanged.

## Comments

- 2026-09-30 (CC): Steps 4–6 done. **Deviation from spec:** authors are normalised by a
  filter-repo commit callback rather than a mailmap file. The callback matches *any* address on
  the trial tenant domain, case-insensitively, so future `Jpb_fabric_userN` accounts created by
  capacity rotation are covered without an edit. A mailmap would need a new line per account.
  The canonical identity is `John P Brownie <dataonthemove@outlook.com>`. Pipeline YAML and the
  exclusion list are in `ops/github-mirror/`. The YAML hasn't been run yet, because local Python
  is denied by settings; the first manual run (step 10) is its first test. Its log prints the
  commit counts before and after and the author identities after the rewrite, for step 11.
- 2026-09-30 (CC): CC created pipeline `github-mirror` (ID 2) in ADO through `az pipelines create`,
  after two wizard attempts weren't saved. Pat added the secret `GITHUB_PAT`. First manual run
  **succeeded** on ADO commit `637ee42`. CC verified by cloning GitHub:
  - 433 commits on both sides.
  - Root tree hash identical (`8b1182d`), so every file matches byte for byte.
  - All 433 authors and committers are `John P Brownie <dataonthemove@outlook.com>`.
  - GitHub head is `04f2871`. Step 12 passes if a second run with no new ADO commits leaves it
    unchanged.
