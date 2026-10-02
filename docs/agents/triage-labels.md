# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

Edit the right-hand column to match whatever vocabulary you actually use.

## Closing states

A finished `spec.md`, `issue.md` or ticket uses exactly one of these, with the date:

| Status | Meaning |
|---|---|
| `done (YYYY-MM-DD)` | Delivered; every step or criterion is complete |
| `wontfix (YYYY-MM-DD)` | Not actioned. Add one line saying why; if superseded, give the path of the replacing spec or issue |

Do not use `closed`, `resolved` or other synonyms. A spec is `done` only when every ticket under its `issues/` folder is `done` or `wontfix`. (`claimed`/`resolved` belong to `/wayfinder` maps only.)
