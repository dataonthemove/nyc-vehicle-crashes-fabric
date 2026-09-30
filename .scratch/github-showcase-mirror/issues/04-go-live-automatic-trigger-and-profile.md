# 04: Go live — automatic trigger and profile polish

**What to build:** The mirror runs hands-free, and the repo is the first thing a visitor sees on
Pat's GitHub profile. A normal push to ADO `main` updates GitHub with no manual step. The repo is
pinned and has a description and topics (microsoft-fabric, power-bi, kimball, data-engineering,
tmdl). The PAT expiry is in Pat's calendar, since expiry is the most likely silent failure. See
the parent spec: `.scratch/github-showcase-mirror/spec.md`.

**Blocked by:** 02 (Tracer — first working mirror to GitHub), 03 (Recruiter-facing README).

**Status:** ready-for-human

- [ ] A trivial commit pushed to ADO `main` appears on GitHub within minutes, with no manual run.
- [ ] The repo has a description and the five topics, and is pinned on Pat's profile.
- [ ] The contribution graph on Pat's GitHub profile shows the mirrored history.
- [ ] A PAT renewal reminder is set in Pat's calendar before the expiry date.
