# ADR-0001: Rotate the NYC Open Data app token; leave git history intact

- **Status:** Accepted
- **Date:** 2026-09-20
- **Context issue:** `.scratch/app-token-history/01-app-token-in-git-history.md`

## Context

A NYC Open Data (Socrata) app token was committed to this repo and remains reachable from
`origin/main` in four commits — SHA pointers `f97b8fb`, `4abe70f`, `7734b17`, `62b1040`. The
token string is never quoted in this ADR or in any other repo doc; quoting it in
`Context/BACKLOG.md` is precisely how it re-entered history in the last of those commits.

The working tree is clean: no token and no `X-App-Token` header survives in any tracked file.
The Fabric Pipeline that carried the header (`pl_cdc_NYC_Crashes`, formerly under repo folder
`2_dev/2_Ingest/`) is retired, and its successor Fabric Pipeline `pl_cdc_NYC_Crashes_Landing`
calls Socrata unauthenticated. Live exposure is therefore closed; this is a history-only finding.

Severity is low — a Socrata app token only raises an anonymous rate limit, granting no write
access and no access to non-public data — but a live credential in version control is not an
acceptable state for a repo whose purpose is to demonstrate good practice.

## Decision

**Rotate the token in the NYC Open Data developer portal and leave git history unrewritten.**

Rotation kills the historical string. The four commits still contain a token-shaped string, but
it is dead, so the residue is cosmetic rather than a credential. Future references to this
incident use commit SHA pointers only.

## Options rejected

| Option | Why rejected |
|---|---|
| Accept and close | Leaves a live credential reachable from `origin/main`. The string being merely unused is not an outcome; a portfolio repo cannot ship a working token in its history. |
| Rewrite history (`git filter-repo --replace-text`) | Rewrites every SHA on `main`. That breaks the Fabric Git Integration binding on the Dev workspace, and invalidates every SHA recorded in repo doc `Context/landing_zone_runbook_results.md` and in the release tags — the only authoritative record of what is deployed. The cost of re-establishing that provenance far exceeds the residual risk of a dead string. |

## Consequences

- The token must be rotated in the portal (browser-only, behind Pat's login) before this decision
  is realised; see ticket `.scratch/app-token-history/tickets/02-rotate-app-token.md`.
- Secret scanners will continue to flag the four historical commits. That is expected, and this
  ADR is the standing answer.
- Any future doc describing this incident refers to the commits by SHA pointer and never quotes
  the string.
