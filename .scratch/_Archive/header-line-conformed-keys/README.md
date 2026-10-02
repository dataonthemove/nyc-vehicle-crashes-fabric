# Header/line conformed keys

## The problem

The crash is the header and persons and vehicles are its lines, but only the crashes fact carried the location and factor-group keys. As a result, the Brooklyn RLS role filtered crashes but returned persons and vehicles unfiltered in Prod, and lines could not be sliced by borough or factor.

## Outcome

The proposed fix was to copy the crash's dimension keys onto the persons and vehicles facts. This was never built as a standalone change. It was closed as won't-fix and folded into the broader header-line-remodel spec, which addressed this gap alongside several other Kimball shortfalls.
