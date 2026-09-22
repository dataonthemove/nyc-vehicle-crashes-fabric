# 02: Rotate the app token in the NYC Open Data portal

**Parent:** `../01-app-token-in-git-history.md`

**What to build:** The token string sitting in git history is dead. Pat signs in to the NYC Open
Data developer portal (data.cityofnewyork.us → account → App Tokens), issues a replacement token
and revokes the old one, then confirms in the portal that the old token no longer appears. No
code change accompanies this: Fabric Pipeline `pl_cdc_NYC_Crashes_Landing` calls Socrata
unauthenticated by design, so there is nowhere for a new token to be wired in. The new token is
held outside the repo until something actually needs it.

**Blocked by:** 01 (Record the rotate decision as an ADR).

**Status:** done (2026-09-20)

- [x] A replacement app token is issued in the portal.
- [x] The old token is revoked and its absence confirmed in the portal.
- [x] The revocation is noted in parent issue `../01-app-token-in-git-history.md`, by date and
      portal action — never by quoting either token string.
- [x] The new token is not committed to this repo in any form.
