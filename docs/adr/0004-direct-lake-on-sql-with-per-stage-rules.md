# ADR-0004: Direct Lake on SQL, rebound per stage by a data source rule

- **Status:** Accepted
- **Date:** 2026-09-21
- **Context:** landing-zone build, Phases 10–11 (commit `ca210d6`)

## Context

Semantic model `NYC_VehicleCrashes_Semantic` was built as Direct Lake **on OneLake**, which is Fabric's
UI default. Its expression is an `AzureStorage.DataLake` storage URL that hardcodes Dev's workspace
and warehouse GUIDs. After the first Dev → Test deploy, the Test model still read **Dev's** warehouse.
Nothing flagged it: Test reports looked correct.

A storage URL is not a bound connection. Deployment autobind has nothing to rewrite, and the
Deployment rules pane offers nothing to target. A Direct Lake on OneLake model **cannot be rebound per
stage by any mechanism**. (Phase 3 had assumed otherwise, but never tested it.)

## Decision

**Use Direct Lake on SQL, and give every downstream stage a data source rule.**

- The expression becomes `expression DatabaseQuery = Sql.Database(<TDS endpoint>, "<warehouse id>")`.
  Every table's `expressionSource` points at `DatabaseQuery`. The conversion is mechanical: measures,
  relationships, columns and SummarizeBy are untouched.
- The Test and Production stages each carry a Deployment Rule on the semantic model:
  Server = that stage's warehouse TDS endpoint, Database = that stage's warehouse ID. Values are in
  `Context/environment-reference.md`.
- Verify the *effective* binding with the Power BI `/datasources` API, not the TMDL.

## Options rejected

- **Stay on OneLake and edit the expression per stage.** That would need per-stage TMDL outside Git,
  which breaks code-first authoring.
- **Rely on autobind.** It fires neither on update-in-place (Test) nor on a first-ever create into an
  empty workspace (Prod). In Prod the model arrived bound to *Test's* effective connection.

## Consequences

- **A missing rule fails silently.** The stage reports another stage's data. After any rebuild of
  `dp_NYC_VehicleCrashes`, re-enter both rules before deploying.
- **Fabric *Test as role* stops working.** Direct Lake on SQL uses SSO, and the service returns "Test
  as role does not work with Single Sign-On (SSO)". Test RLS instead with an XMLA query that sets the
  `Roles=` connection property (`powerbi-modeling-mcp` `dax_query_operations` →
  `impersonation.roles`). It's read-only and needs no role members.
- Warehouse-level RLS would force a DirectQuery fallback, which is unavailable for Warehouse-backed
  Direct Lake. Security stays in model roles.
- The Fabric UI adds `collation: Latin1_General_100_BIN2_UTF8` to new Direct Lake on SQL models. This
  model doesn't have it, deliberately, because it would make DAX string comparison case-sensitive.
