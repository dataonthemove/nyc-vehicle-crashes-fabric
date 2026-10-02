# Crash point coordinate cleanse

## The problem

The crashes fact's latitude and longitude were set up correctly for maps, but the values were not clean. About 7,600 rows sat at exactly (0, 0), off the coast of Africa, and 150 more fell outside NYC, so any map visual opened zoomed out to the Atlantic.

## The fix

The fact_crashes load procedure now ends with an idempotent UPDATE that sets latitude and longitude to NULL wherever either falls outside the NYC bounding box. This one statement cleans existing rows and every future batch. It was built and validated in Dev; later promotion carries it to Test and Prod.
