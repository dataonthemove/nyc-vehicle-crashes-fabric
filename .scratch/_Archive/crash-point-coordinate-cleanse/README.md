# Crash point coordinate cleanse

About 7,700 crashes had bad coordinates, such as (0, 0) or points outside NYC, which wrecked map visuals. The fact load now sets any out-of-NYC latitude and longitude to NULL. Built and validated in Dev only.
