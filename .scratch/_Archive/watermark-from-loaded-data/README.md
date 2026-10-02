# Watermark from loaded data

## The problem

Each CDC run moved the watermark to the time the pipeline ran, not to the newest data it loaded. NYC Open Data froze its datasets in June, so when it backfills, crashes from June to September would be skipped forever. Same-day crashes published later were also being missed.

## The fix

The watermark now records the newest crash_date actually landed per source. A run that lands nothing leaves it unchanged, and it never moves backwards. Each read uses a 7-day lookback, with downstream de-duplication of the overlap. A one-time reset set all three watermarks back to 11 June 2026.
