# Stage load pipeline

Built one Fabric pipeline per stage (Dev, Test, Prod) that runs Ingest, then Transform, then the semantic model refresh in order. It replaced sixteen manual steps and stops before refresh if anything fails.
