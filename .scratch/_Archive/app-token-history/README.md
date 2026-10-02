# App token in git history

An old NYC Open Data app token, used by a since-retired CDC pipeline, was still sitting in four past git commits. It was low risk, since the token only raises an anonymous rate limit, but a credential in version control looks sloppy in a repo meant to demonstrate good practice.

Rather than rewriting git history, the token was rotated in the NYC Open Data portal, so the string left in history is now dead. An ADR records the decision to leave history intact, and the issue was closed with the rotation date noted.
