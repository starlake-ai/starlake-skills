---
name: semantic-export
description: Export semantic models from metadata/semantic to Apache Ossie, Looker LookML, or Power BI TMDL with the starlake semantic-export command
---

# Semantic Export Skill

Export the semantic models stored in `metadata/semantic/` to another semantic format. Three targets:

- **`ossie`** (default): **Apache Ossie (Incubating)**, formerly Open Semantic Interchange, a vendor-neutral interchange format consumable by any Ossie-compatible BI tool, query engine, or AI agent.
- **`lookml`**: a Looker project, one `<table>.view.lkml` per table plus a `<model>.model.lkml` with explores derived from relationships.
- **`tmdl`**: a Power BI TMDL folder per model (`database.tmdl`, `model.tmdl`, `relationships.tmdl`, `tables/<table>.tmdl`).

## Command

```bash
starlake semantic-export [options]
```

| Option | Description |
|--------|-------------|
| `--format <fmt>` | Target format: `ossie` (default), `lookml`, or `tmdl` |
| `--model <name>` | Export a single model, matched by its `name` field or file basename. All models by default |
| `--output <dir>` | Output directory. `metadata/semantic/export/<format>/` by default |
| `--connection <name>` | lookml: Looker connection name written in the model file. tmdl: Starlake connection used to derive each table's Power Query source |
| `--reportFormat <fmt>` | Report format: console, json, html |

Examples:

```bash
starlake semantic-export                                  # export every model to metadata/semantic/export/ossie/
starlake semantic-export --model ecommerce_analytics      # one model only
starlake semantic-export --output /tmp/ossie-models       # custom output directory
starlake semantic-export --format lookml --connection looker_wh
starlake semantic-export --format tmdl --model ecommerce_analytics --connection snowflake_prod
```

Output per format (the command fails if `--model` names a model that does not exist):

- `ossie`: each model `<name>.yaml` produces `<name>.ossie.yaml`.
- `lookml`: each model produces `<model>.model.lkml` (connection, `include: "*.view.lkml"`, one explore per relationship with `sql_on` built from the relationship columns) plus one `<table>.view.lkml` per table (dimensions, dimension_groups for time dimensions, measures from metrics).
- `tmdl`: each model produces a folder with `database.tmdl`, `model.tmdl`, `relationships.tmdl` (composite keys handled via concatenated key columns) and `tables/<table>.tmdl` (columns, measures, a Power Query partition derived from `--connection`). Names are kept verbatim and quoted per TMDL rules when they are not plain identifiers.

## Mapping (ossie)

The converter targets Ossie core-spec version `0.2.0.dev0`:

| Starlake semantic model | Ossie |
|---|---|
| model `name` / `description` | `semantic_model[0].name` / `description` |
| `tables[]` | `datasets[]` with `source` = `database.schema.table` |
| `dimensions[]` | `fields[]` with `dimension: {is_time: false}` |
| `time_dimensions[]` | `fields[]` with `dimension: {is_time: true}` |
| `facts[]` | `fields[]` (no dimension block) |
| column `expr` / `data_type` | `expression.dialects[{dialect: ANSI_SQL}]` / Ossie datatype enum |
| `synonyms` | `ai_context.synonyms` |
| `primary_key.columns` / `unique` dimensions | `primary_key` / `unique_keys` |
| table and model `metrics[]` | model-level `metrics[]` (table origin recorded in extension) |
| `relationships[]` | `relationships[]` with `from`/`to` and column arrays |
| `verified_queries[].question` | model `ai_context.examples` |

**Nothing is lost**: attributes with no Ossie equivalent (filters, `sample_values`, `is_enum`, `access_modifier`, `cortex_search_service`, verified query SQL, `join_type` / `relationship_type`) are preserved verbatim in `custom_extensions` blocks under `vendor_name: STARLAKE`, per the Ossie extensibility model. A round-trip or another converter can read them back.

Unknown `data_type` values map to the Ossie `Opaque` datatype; absent ones are omitted.

## Notes

- lookml and tmdl are lossy where the target has no equivalent; ossie is the round-trippable format.
- tmdl metric translation: simple aggregate metrics (`sum`, `count`, `avg`, `min`, `max` over a column) become real DAX measures; anything else becomes a `BLANK()` measure carrying the original SQL in a TODO comment for manual porting.
- tmdl Power Query sources are engine-aware, derived from the named Starlake connection's JDBC URL (e.g. `Sql.Database` for sqlserver, engine-specific connectors otherwise; unrecognized engines fall back to a generic source with a warning).
- Metric expressions are copied verbatim as `ANSI_SQL` dialect entries. Table-level metrics whose expressions reference bare column names may need qualification (`table.column`) for consumers that evaluate them model-wide; the source table is recorded in the metric's `STARLAKE` extension.
- The export never modifies the source models; re-running overwrites previous exports in place.

## Related Skills

- `semantic`: authoring reference for the source models in `metadata/semantic/`
- `starflow-semantic-model-design`: guided workflow that produces the source models
