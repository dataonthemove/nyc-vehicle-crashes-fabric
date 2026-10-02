# 01: Record the rotate decision as an ADR

**Parent:** `../spec.md`

**What to build:** The project's decision on the historical NYC Open Data app token is written
down where future readers will find it: rotate the token, leave git history intact. The ADR states
why rewriting history was rejected — `git filter-repo` rewrites every SHA on `main`, which breaks
the Fabric Git Integration binding on the Dev workspace and invalidates the SHAs recorded in
repo doc `Context/landing_zone_runbook_results.md` and in the release tags — and why simply
accepting was rejected: a live credential in a portfolio repo is not an outcome.

**Blocked by:** None (can start immediately).

**Status:** done

- [x] An ADR exists under repo folder `docs/adr/` recording the choice as "rotate".
- [x] It names the two rejected options and the specific cost that ruled each one out.
- [x] It refers to the exposed commits by SHA pointer only (`f97b8fb`, `4abe70f`, `7734b17`,
      `62b1040`) and never quotes the token string.
- [x] Parent issue `../spec.md` links to the ADR.
