# Ingest de-duplication and landing file cleanup

## The problem

Every stage load since 2 October 2026 failed while ingesting files. A watermark change re-read a week of overlap, assuming something downstream removed repeated rows; nothing did. The ingest notebook read all landing files together, so the same crash, person or vehicle arrived twice and Delta's MERGE rejected the batch.

## The fix

Loads work again in Dev, Test and Prod. The ingest notebook keeps the newest copy of each record, judged by file modification time, so overlaps can never fail a load. The landing folders were consolidated into one de-duplicated baseline file per source, with the originals archived. Row counts were unchanged.
