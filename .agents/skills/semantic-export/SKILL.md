---
name: semantic-export
description: Export semantic models from metadata/semantic to Apache Ossie interchange format with the starlake semantic-export command
---

# Semantic Export Skill

Export the semantic models stored in `metadata/semantic/` to a vendor-neutral interchange format. Currently supported target: **Apache Ossie (Incubating)**, formerly Open Semantic Interchange, so models authored for Starlake can be consumed by any Ossie-compatible BI tool, query engine, or AI agent.

## Command

```bash
starlake semantic-export [options]
```

| Option | Description |
|--------|-------------|
| `--format <fmt>` | Target interchange format. Only `ossie` is supported for now (default) |
| `--model <name>` | Export a single model, matched by its `name` field or file basename. All models by default |
| `--output <dir>` | Output directory. `metadata/semantic/export/<format>/` by default |
| `--reportFormat <fmt>` | Report format: console, json, html |

Examples:

```bash
starlake semantic-export                                  # export every model to metadata/semantic/export/ossie/
starlake semantic-export --model ecommerce_analytics      # one model only
starlake semantic-export --output /tmp/ossie-models       # custom output directory
```

Each model `<name>.yaml` in `metadata/semantic/` produces `<name>.ossie.yaml` in the output directory. The command fails if `--model` names a model that does not exist.

## Mapping

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

- Metric expressions are copied verbatim as `ANSI_SQL` dialect entries. Table-level metrics whose expressions reference bare column names may need qualification (`table.column`) for consumers that evaluate them model-wide; the source table is recorded in the metric's `STARLAKE` extension.
- The export never modifies the source models; re-running overwrites previous exports in place.

## Related Skills

- `semantic`: authoring reference for the source models in `metadata/semantic/`
- `starflow-semantic-model-design`: guided workflow that produces the source models
