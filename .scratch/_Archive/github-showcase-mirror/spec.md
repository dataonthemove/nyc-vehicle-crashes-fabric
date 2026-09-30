Status: done (2026-10-01)

# GitHub showcase mirror

## Problem Statement

Pat is job-hunting as a data engineer, and a public GitHub repo is the portfolio evidence hiring
managers expect. This project lives in Azure DevOps (ADO), which recruiters rarely browse and which
can't easily be shared. ADO has to stay the primary source control: Fabric Git Integration is
bound to it, and the whole local-TMDL → push → Update All workflow depends on it. Pat wants a
public GitHub presence without giving up ADO or maintaining two repos by hand.

## Solution

An ADO pipeline mirrors the ADO repo to a new public GitHub repo, one way, on every push to
`main`. Each run mirrors everything: every folder and the full history. Nothing is stripped out.
The only change is normalising commit authors before the force-push to GitHub. There's no security gate. The
project is a demonstration on trial capacity with no credentials in the working tree, so Pat
accepts that residual history leaks a little. GitHub is read-only: Pat never commits there, and
every run overwrites it from ADO. The root README is rewritten for recruiters. It says plainly
that this is a demonstration project, and that this is why Fabric IDs and similar details are
published without redaction.

## User Stories

1. As Pat, I want a public GitHub repo of this project, so that I can link it from my CV and job applications.
2. As Pat, I want ADO to remain the only repo I commit to, so that my Fabric Git Integration and working habits are unchanged.
3. As Pat, I want GitHub updated automatically on each push to ADO `main`, so that the showcase never goes stale.
4. As Pat, I want no extra manual step after `git push`, so that mirroring costs me nothing day to day.
5. As Pat, I want the GitHub repo to carry real commit history, so that reviewers see sustained, incremental engineering rather than a staged dump.
6. As Pat, I want every folder mirrored, including working notes (environment reference, runbooks, ad-hoc scratch, backlog and specs), so that reviewers see the full engineering process, not just the output.
7. As Pat, I want the exclusion mechanism to exist but start empty, so that I can withdraw a path later with one commit if I change my mind.
8. As Pat, I want commits by the trial-account UPNs rewritten to my GitHub-verified email, so that they count on my contribution graph and the history looks consistent.
9. As Pat, I want the list of excluded paths versioned in the repo, so that I can change what's public through a normal commit.
10. As Pat, I want the GitHub PAT limited to this one repo, so that a leaked token can't touch my other GitHub repos.
11. As Pat, I want the PAT held as an ADO secret variable, so that it's never committed or logged.
12. As Pat, I want the mirror pipeline definition visible on GitHub, so that reviewers can see I build CI/CD.
13. As Pat, I want `CLAUDE.md`, `.claude/` shared settings, ADRs, agent docs and `.scratch/` specs public, so that my governed, agent-assisted workflow is part of the showcase.
14. As Pat, I want the root README to open with a recruiter-oriented summary, architecture diagram and skills demonstrated, so that a visitor understands the project in under a minute.
15. As Pat, I want the README to state that this is a demonstration project on trial capacity, so that visitors understand why Fabric IDs, the tenant ID and working notes appear unredacted.
16. As Pat, I want the README to say the GitHub repo is a read-only mirror of ADO, so that nobody opens issues or PRs expecting a response.
17. As Pat, I want GitHub Issues, Wiki and Projects turned off on the mirror, so that the repo doesn't invite contributions.
18. As Pat, I want the repo pinned on my GitHub profile with a description and topics, so that it's the first thing a visitor sees.
19. As Pat, I want my existing GitHub repos left untouched, so that setting up the mirror carries no risk to them.
20. As Pat, I want the mirror to live outside the Fabric Git-bound folders, so that Fabric Source Control never sees or flags it.
21. As Pat, I want a manual "run now" option on the pipeline, so that I can re-mirror without a dummy commit.
22. As Pat, I want repeated runs over unchanged history to produce identical commit SHAs, so that force-pushes don't churn GitHub history.
23. As Pat, I want to know the PAT's expiry date, so that the mirror doesn't silently stop working.
24. As Pat, I want `CLAUDE.md` to record that GitHub is a read-only mirror, so that future CC sessions never push to it or edit there.
25. As a hiring manager, I want to browse real TMDL, T-SQL, pipeline and notebook code, so that I can judge the candidate's hands-on Fabric ability.
26. As a hiring manager, I want ADRs and design docs, so that I can judge the candidate's design reasoning.
27. As a technical reviewer, I want commit messages following a consistent convention, so that I can see disciplined version control.
28. As a technical reviewer, I want the README's demonstration-project note, so that I read the unredacted IDs as a deliberate choice rather than carelessness.

## Implementation Decisions

- **Direction and authority.** One-way, ADO → GitHub. ADO `main` is authoritative. Each run replaces GitHub `main` wholesale with a force-push. Anything edited directly on GitHub is lost on the next run, so removals must be made in the exclusion list, not on GitHub.
- **Pipeline host.** An Azure Pipelines YAML pipeline in the ADO project, stored in the ADO repo in a new top-level ops folder outside `1_Landing/` and `2_dev/`. It triggers on `main` and also allows a manual run. It uses a Microsoft-hosted Ubuntu agent and checks out the full history, not a shallow clone.
- **Rewrite tool.** `git filter-repo`, installed on the agent through pip and run on the full clone, with `--mailmap` only. The mailmap maps the `Jpb_fabric_user*` UPNs and the mixed-case outlook address to `dataonthemove@outlook.com`, which Pat has confirmed is verified on GitHub. GitHub ignores a `.mailmap` file when crediting contributions, so the rewrite is needed for the contribution graph. It changes commit SHAs relative to ADO, but the same input gives the same SHAs on every run.
- **Nothing stripped (Pat's decision).** Every path and every commit is mirrored. There's no pre-push gate, no gitleaks scan and no content scrubbing. The pipeline fails only if a command fails.
- **Exclusion list: present but empty.** A versioned list wired to `--invert-paths` ships with no entries. It exists only so Pat can withdraw a path later with a single commit.
- **Accepted exposure.** These go public knowingly:
  - Everything in `Context/`: the tenant ID, physical workspace, item, capacity and connection IDs, and the runbooks.
  - `.scratch/` specs and issues, including the archived app-token incident notes.
  - `Other/` scratch scripts.
  - Physical Fabric IDs embedded in item files.
  - Trial-account UPNs quoted in file content.
  - The rotated Socrata token string in historical commits. It's dead per ADR-0001.
  None of these grant access; Entra and Fabric role-based access control (RBAC) govern access.
- **Secrets.** One ADO pipeline secret variable: a GitHub fine-grained PAT scoped to the mirror repo only, with Contents set to read and write. Set an expiry and diarise renewal.
- **GitHub repo.** A new public repo, created empty with no README or licence so the first push isn't rejected. Issues, Wiki and Projects are off. It has a description and topics (microsoft-fabric, power-bi, kimball, data-engineering, tmdl) and is pinned on the profile.
- **README.** A single root README serves both remotes. It opens with, in order:
  - A one-paragraph pitch.
  - The embedded architecture PNG.
  - A "what this demonstrates" list.
  - A **"Nature of this repo" notice**. It states that this is a personal demonstration project on Fabric trial capacity with public NYC Open Data. It holds no credentials. Fabric and tenant IDs, working notes and the backlog are published unredacted on purpose, because they grant no access and they show the working process. It also says the repo is a read-only mirror of the Azure DevOps origin, so issues and PRs aren't monitored.
  The existing architecture and layout tables are kept.
- **Governance.** `CLAUDE.md` gains a short rule: GitHub is a read-only mirror, everything is public unless it's added to the (empty) exclusion list, and neither CC nor Pat pushes to GitHub directly. `git push` to ADO stays Pat's, as today.

## Summary of sequence of operations

1. Confirm ADO org has hosted pipeline parallelism.
2. Create empty public GitHub repo; disable Issues, Wiki, Projects.
3. Create fine-grained PAT scoped to that repo only.
4. Add Pat's commit email to GitHub account, verified.
5. CC writes mailmap and empty exclusion list in ops folder.
6. CC writes mirror pipeline YAML with filter-repo step.
7. CC rewrites root README, including demonstration-nature notice.
8. CC adds read-only-mirror rule to `CLAUDE.md`.
9. CC commits; Pat pushes to ADO.
10. Pat registers pipeline in ADO, adds PAT secret.
11. Run pipeline manually; confirm it succeeds.
12. Browse GitHub; confirm all folders, authors, README render.
13. Pin repo, add description and topics.
14. Push a trivial commit; confirm automatic mirror.

## Testing Decisions

- **No automated test seam.** There's no gate by Pat's decision. The only automated check is that the pipeline run goes green or red.
- **Acceptance** is manual and done once, after the first manual run and again after the first automatic run (steps 12 and 14). On GitHub, confirm:
  - Every top-level folder in ADO is present on GitHub, and the commit count matches ADO's.
  - Commit authors resolve to Pat's GitHub account, and the contribution graph updates.
  - The README renders with the diagram and the "Nature of this repo" notice.
  - A new ADO push appears on GitHub within minutes.
- **Prior art.** The manual stage-validation checklists used in the archived stage-load pipeline tickets: an observable outcome checked once, by eye, at the boundary.

## Out of Scope

- Excluding any path, a pre-push security gate, gitleaks scanning or content scrubbing (all dropped by Pat's decision).
- Moving primary source control or Fabric Git Integration to GitHub.
- Two-way sync, or accepting any GitHub contributions.
- Rewriting ADO history. ADR-0001 stands.
- Scrubbing physical Fabric GUIDs from item files.
- GitHub Actions, GitHub Pages or a separate portfolio site.
- Mirroring branches other than `main`, or tags (the project has none).

## Further Notes

- **Deleting on GitHub doesn't work here.** It adds a commit, so the content stays in history, and the next mirror run restores it anyway. To withdraw something, add its path to the exclusion list and rerun. Forks or clones made before then keep their copy.
- **Hosted parallelism risk.** New or free ADO orgs may have no Microsoft-hosted parallel jobs until Microsoft approves a free-grant request, which can take a few business days. The fallback is a self-hosted agent on Pat's machine. Check this first, because it can block everything else.
- **PAT expiry is the most likely silent failure.** When it expires, the pipeline goes red in ADO and GitHub stops updating. Nothing breaks on the ADO side.
- Adding a path to the exclusion list later rewrites the mirrored SHAs from the first commit that touched that path. Expect one large force-push when that happens. It's harmless for a read-only mirror.
