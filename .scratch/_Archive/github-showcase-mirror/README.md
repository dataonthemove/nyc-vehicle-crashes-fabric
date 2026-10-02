# GitHub showcase mirror

## The problem

Pat is job-hunting as a data engineer, and hiring managers expect a public GitHub repo as portfolio evidence. The project lives in Azure DevOps, which recruiters rarely browse and which is hard to share. ADO had to stay primary, because Fabric Git Integration and the whole TMDL workflow depend on it.

## The fix

An ADO pipeline now mirrors the repo, one way, to a public GitHub repo on every push to main. It copies everything, including full history, normalising only commit authors. GitHub is read-only and overwritten on every run. The root README was rewritten for recruiters, explaining that this is a demonstration project.
