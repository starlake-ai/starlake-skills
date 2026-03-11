# Starlake Skills

Claude Code plugin providing 45+ skills for the [Starlake](https://starlake.ai) data pipeline CLI.

Covers all CLI commands (load, transform, extract, autoload, dag-generate...), configuration patterns, connection types, write strategies, data quality expectations, and production best practices for DuckDB, BigQuery, Snowflake, Redshift, and Airflow/Dagster orchestration.

## Installation

### From Claude Code Marketplace

```bash
# Coming soon
claude plugin install starlake-skills
```

### Manual Installation

Clone this repository into your Claude Code skills directory:

```bash
# Global installation (available in all projects)
git clone https://github.com/starlake-ai/starlake-skills.git ~/.claude/skills/starlake-skills

# Or project-local installation
git clone https://github.com/starlake-ai/starlake-skills.git .claude/skills/starlake-skills
```

## Skills Catalog

### Reference
- **config** — Configuration reference (env vars, app structure, types, best practices)

### Ingestion & Loading
- **autoload** — Auto-infer schemas and load data
- **cnxload** — Load files into JDBC tables
- **esload** / **index** — Load into Elasticsearch
- **ingest** — Generic data ingestion
- **kafkaload** — Kafka load/offload
- **load** — Load from pending area (write strategies, sink config)
- **preload** — Check landing area
- **stage** — Move files landing → pending

### Transformation
- **job** / **transform** — Run SQL/Python transformations

### Extraction
- **extract** — Schema + data extraction
- **extract-bq-schema** — BigQuery schema extraction
- **extract-data** — Data extraction to files
- **extract-schema** — JDBC schema extraction (custom remarks, column selection)
- **extract-script** — Generate extraction scripts

### Schema Management
- **bootstrap** — New project from template
- **infer-schema** — Infer schema from file
- **xls2yml** / **xls2ymljob** — Excel to YAML conversion
- **yml2ddl** — YAML to SQL DDL
- **yml2xls** — YAML to Excel

### Data Quality
- **expectations** — Expectation syntax, Jinja2 macros, validation patterns

### Lineage & Diagrams
- **acl-dependencies** / **col-lineage** / **lineage** / **table-dependencies**

### Operations
- **console** / **freshness** / **gizmosql** / **metrics** / **migrate** / **serve** / **settings** / **validate**

### Security
- **iam-policies** — IAM policies
- **secure** — RLS, CLS, privacy transformations

### Orchestration
- **dag-deploy** / **dag-generate** — Airflow/Dagster DAG generation

### Utilities
- **bq-info** / **compare** / **parquet2csv** / **site** / **summarize** / **test**

## Links

- [Starlake Documentation](https://docs.starlake.ai)
- [Starlake GitHub](https://github.com/starlake-ai/starlake)
- [Starlake Examples](https://github.com/starlake-ai/starlake-examples)

## License

Apache-2.0 — See [LICENSE](LICENSE) for details.
