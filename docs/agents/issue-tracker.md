# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- Each directory has exactly one parent document, named by its kind:
  - `spec.md`: multi-step work, written by `/to-spec-pat`, broken into tickets by `/to-tickets_pat`
  - `issue.md`: a single finding small enough to fix directly (a bug, a risk, an idea raised in conversation or triage). No child tickets. If it grows, rename it `spec.md` and break it down
- Tickets are the children of a spec: one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined file. The folder is always `issues/`, never `tickets/`
- Triage state is recorded as a `Status:` line near the top of every parent and ticket file (see `triage-labels.md` for the role strings, including the closing states)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create `.scratch/<feature-slug>/issue.md` for a single finding, or `spec.md` for work that will be broken into tickets (creating the directory if needed). Never put a numbered `NN-<slug>.md` file in the feature root.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.
