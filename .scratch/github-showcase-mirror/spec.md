Status: ready-for-agent

# GitHub showcase mirror

## Problem Statement

Pat is job-hunting as a data engineer, and a public GitHub repo is the portfolio evidence hiring
managers expect. This project lives in Azure DevOps (ADO), which recruiters rarely browse and which
can't easily be shared. ADO has to stay the primary source control: Fabric Git Integration is
bound to it, and the whole local-TMDL → push → Update All workflow depends on it. Pat wants a
public GitHub presence without giving up ADO or maintaining two repos by hand.

## Solution

An ADO pipeline mirrors the ADO repo to a new public GitHub repo, one way, on every push to
`main`. Each run builds a filtered copy of the full history, drops the working-notes folders,
normalises commit authors, and force-pushes the result to GitHub. There's no security gate. The
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
6. As Pat, I want working-notes folders (environment reference, ad-hoc scratch, backlog) left out of GitHub, so that the showcase shows finished engineering, not internal noise.
7. As Pat, I want the excluded paths removed from all of history, not just the tip, so that old commits don't surface them.
8. As Pat, I want commits by the trial-account UPNs rewritten to my GitHub-verified email, so that they count on my contribution graph and the history looks consistent.
9. As Pat, I want the list of excluded paths versioned in the repo, so that I can change what's public through a normal commit.
10. As Pat, I want the GitHub PAT limited to this one repo, so that a leaked token can't touch my other GitHub repos.
11. As Pat, I want the PAT held as an ADO secret variable, so that it's never committed or logged.
12. As Pat, I want the mirror pipeline definition visible on GitHub, so that reviewers can see I build CI/CD.
13. As Pat, I want to keep `CLAUDE.md`, `.claude/` shared settings, ADRs and agent docs public, so that my governed, agent-assisted workflow is part of the showcase.
14. As Pat, I want the root README to open with a recruiter-oriented summary, architecture diagram and skills demonstrated, so that a visitor understands the project in under a minute.
15. As Pat, I want the README to state that this is a demonstration project on trial capacity, so that visitors understand why Fabric IDs and similar details appear unredacted.
16. As Pat, I want the README to say the GitHub repo is a read-only mirror of ADO, so that nobody opens issues or PRs expecting a response.
17. As Pat, I want GitHub Issues, Wiki and Projects turned off on the mirror, so that the repo doesn't invite contributions.
18. As Pat, I want the repo pinned on my GitHub profile with a description and topics, so that it's the first thing a visitor sees.
19. As Pat, I want my existing GitHub repos left untouched, so that setting up the mirror carries no risk to them.
20. As Pat, I want the mirror to live outside the Fabric Git-bound folders, so that Fabric Source Control never sees or flags it.
21. As Pat, I want a manual "run now" option on the pipeline, so that I can re-mirror after changing exclusions without a dummy commit.
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
- **Filtering tool.** `git filter-repo`, installed on the agent through pip, running on the full clone:
  - `--invert-paths` driven by the versioned exclusion list.
  - `--mailmap` mapping the `Jpb_fabric_user*` UPNs and the mixed-case outlook address to Pat's GitHub-verified email.
  - Commits that end up empty are pruned. The same input and config give the same SHAs.
- **No gate, no content scrubbing.** Pat's decision: the project is a demonstration, so there's no pre-push security gate, no gitleaks scan and no `--replace-text`. The pipeline fails only if a command fails.
- **Initial exclusion list.** `Context/`, `Other/`, `.scratch/`. Kept public: all Fabric item folders, `docs/`, `DIagrams/`, `CONTEXT.md`, `CLAUDE.md`, shared `.claude/` files, and the pipeline itself.
- **Accepted exposure.** These go public knowingly:
  - Physical Fabric workspace and item GUIDs embedded in item files.
  - Trial-account UPNs in commit metadata. The mailmap rewrites authors, but any UPNs quoted in file content stay.
  - The rotated Socrata token string in historical commits. It's dead per ADR-0001.
  None of these grant access; Entra and Fabric role-based access control (RBAC) govern access.
- **Secrets.** One ADO pipeline secret variable: a GitHub fine-grained PAT scoped to the mirror repo only, with Contents set to read and write. Set an expiry and diarise renewal.
- **GitHub repo.** A new public repo, created empty with no README or licence so the first push isn't rejected. Issues, Wiki and Projects are off. It has a description and topics (microsoft-fabric, power-bi, kimball, data-engineering, tmdl) and is pinned on the profile.
- **README.** A single root README serves both remotes. It opens with, in order:
  - A one-paragraph pitch.
  - The embedded architecture PNG.
  - A "what this demonstrates" list.
  - A **"Nature of this repo" notice**. It states that this is a personal demonstration project on Fabric trial capacity with public NYC Open Data. It holds no credentials, and Fabric IDs are left unredacted because they grant no access. It also says the repo is a read-only mirror of the Azure DevOps origin, so issues and PRs aren't monitored.
  The existing architecture and layout tables are kept.
- **Governance.** `CLAUDE.md` gains a short rule: GitHub is a read-only mirror, the exclusion list controls what's public, and neither CC nor Pat pushes to GitHub directly. `git push` to ADO stays Pat's, as today.

## Summary of sequence of operations

1. Confirm ADO org has hosted pipeline parallelism.
2. Create empty public GitHub repo; disable Issues, Wiki, Projects.
3. Create fine-grained PAT scoped to that repo only.
4. Add Pat's commit email to GitHub account, verified.
5. CC writes exclusion list and mailmap in ops folder.
6. CC writes mirror pipeline YAML with filter-repo step.
7. CC rewrites root README, including demonstration-nature notice.
8. CC adds read-only-mirror rule to `CLAUDE.md`.
9. CC commits; Pat pushes to ADO.
10. Pat registers pipeline in ADO, adds PAT secret.
11. Run pipeline manually; confirm it succeeds.
12. Browse GitHub; confirm exclusions, authors, README render.
13. Pin repo, add description and topics.
14. Push a trivial commit; confirm automatic mirror.

## Testing Decisions

- **No automated test seam.** There's no gate by Pat's decision. The only automated check is that the pipeline run goes green or red.
- **Acceptance** is manual and done once, after the first manual run and again after the first automatic run (steps 12 and 14). On GitHub, confirm:
  - `Context/`, `Other/` and `.scratch/` are absent at the tip and in a sample of old commits.
  - Commit authors resolve to Pat's GitHub account, and the contribution graph updates.
  - The README renders with the diagram and the "Nature of this repo" notice.
  - A new ADO push appears on GitHub within minutes.
- **Prior art.** The manual stage-validation checklists used in the archived stage-load pipeline tickets: an observable outcome checked once, by eye, at the boundary.

## Out of Scope

- A pre-push security gate, gitleaks scanning or content scrubbing (dropped by Pat's decision).
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
- Adding a path to the exclusion list rewrites the mirrored SHAs from the first commit that touched that path. Expect one large force-push when that happens. It's harmless for a read-only mirror.
- `.scratch/` is excluded because it mixes physical IDs and incident notes with finished specs. If specs later become worth showcasing, a curated `docs/specs/` is the cleaner route.
