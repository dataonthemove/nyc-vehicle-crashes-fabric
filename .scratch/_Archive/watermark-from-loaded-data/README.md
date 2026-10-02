# Watermark from loaded data

The CDC watermark advanced to the run time, not the newest data loaded, so late-published crashes would be skipped forever. It now records the newest crash date actually landed, never moves backwards, and rereads a 7-day lookback.
