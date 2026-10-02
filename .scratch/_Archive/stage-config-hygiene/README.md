# Stage config hygiene

## The problem

The documentation describing per-stage configuration had drifted from reality. The Variable Library still held a variable nothing read, ADR-0003 and the glossary were out of date, and nothing warned that branch-out workspaces still write into Dev's lakehouse and Warehouse unless they are repointed first.

## The fix

One documentation-only commit brought everything back into line. The unused landing_lakehouse variable was removed from the Variable Library, ADR-0003 and the glossary were amended, and a branch-out pre-flight checklist was added. An earlier draft ticket was retired and used as the source for the ticket that shipped.
