# 04: Go live — automatic trigger and profile polish

**What to build:** The mirror runs hands-free, and the repo is the first thing a visitor sees on
Pat's GitHub profile. A normal push to ADO `main` updates GitHub with no manual step. The repo is
pinned and has a description and topics (microsoft-fabric, power-bi, kimball, data-engineering,
tmdl). The PAT expiry is in Pat's calendar, since expiry is the most likely silent failure. See
the parent spec: `.scratch/github-showcase-mirror/spec.md`.

**Blocked by:** 02 (Tracer — first working mirror to GitHub), 03 (Recruiter-facing README).

**Status:** closed

- [x] A trivial commit pushed to ADO `main` appears on GitHub within minutes, with no manual run.
- [x] The repo has a description and the five topics, and is pinned on Pat's profile.
- [x] The contribution graph on Pat's GitHub profile shows the mirrored history.
- [x] A PAT renewal reminder is set in Pat's calendar before the expiry date.

## Comments

- 2026-09-30 (CC): Closed.
  - Automatic trigger verified: two `batchedCI` runs succeeded after Pat's push, including ADO
    `dafce3e`.
  - Topics confirmed through the GitHub API (10): analytics-engineering, data-engineering,
    dimensional-modeling, etl, kimball-methodology, power-bi, direct-lake, lakehouse,
    microsoft-fabric, tmdl. This replaces the spec's list of five.
  - Pat confirmed the pin, the contribution graph and the PAT renewal reminder (expiry 2027-09-30).
