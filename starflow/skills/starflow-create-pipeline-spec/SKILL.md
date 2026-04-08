---
name: starflow-create-pipeline-spec
description: 'Create a complete pipeline specification covering extract, load, transform, and orchestrate. Use when the user says "create pipeline spec" or "design a data pipeline".'
---

# Pipeline Specification

## Overview

Creates a comprehensive pipeline specification that covers the full ETL/ELT lifecycle: extraction from sources, loading into the target system, SQL transformations, and orchestration scheduling. The spec produces implementation-ready Starlake configuration files.

**Role Guidance:** Act as a Data Architect who translates business requirements into detailed pipeline specifications using Starlake's declarative configuration model.

**Design Rationale:** A pipeline spec is the bridge between architecture decisions and implementation. It defines exactly what data moves where, how it's transformed, and when it runs. Starlake's declarative model means the spec IS the implementation — YAML + SQL, not code.

## Steps

### Step 1: Pipeline Context
1. Load available planning artifacts:
   - `{planning_artifacts}/domain-discovery-*.md`
   - `{planning_artifacts}/data-architecture-*.md`
   - `{planning_artifacts}/source-analysis-*.md`
2. Ask the user:
   - Which domain/pipeline to specify?
   - What is the business objective of this pipeline?
   - What is the target SLA (freshness requirement)?

### Step 2: Extract Specification
For database sources, define JDBC extraction config:
```yaml
version: 1
extract:
  connectionRef: "source_db"
  jdbcSchemas:
    - schema: "public"
      tables:
        - name: "orders"
          columns: ["*"]
          fetchSize: 10000
          partitionColumn: "order_id"
          numPartitions: 4
```
For file sources, document:
- File location and naming pattern
- File format and delimiters
- Arrival schedule
- File sensor or ACK file strategy

### Step 3: Load Specification
For each table in the pipeline, define:
- **Domain assignment**: Which Starlake domain
- **File pattern**: Regex to match incoming files
- **Write strategy**: APPEND, OVERWRITE, UPSERT_BY_KEY, SCD2, etc.
- **Schema**: Attributes with types, constraints, privacy
- **Expectations**: Data quality checks at load time
- **Sink configuration**: Partitioning, clustering, connection

### Step 4: Transform Specification
For each transformation task:
- **Input tables**: Source tables referenced in SQL
- **Output table**: Target table name and write strategy
- **SQL logic**: The transformation query (referencing source tables directly)
- **Expectations**: Post-transform quality checks
- **Dependencies**: Automatically inferred from SQL, but document explicitly
- **Recursive execution**: Whether upstream tasks should run first

Document the transformation DAG (dependency graph).

### Step 5: Orchestration Specification
Define the DAG configuration:
```yaml
version: 1
dag:
  comment: "Daily orders pipeline"
  template: "dag_template.py.j2"
  filename: "dag_orders_daily"
  schedule: "0 6 * * *"   # Daily at 6 AM
  options:
    catchup: false
    dagrun_timeout: 7200
```
Specify:
- Schedule (cron expression)
- Dependencies between DAGs
- File sensor triggers (if event-driven)
- Retry and timeout policies
- Alert channels on failure

### Step 6: Environment Configuration
Document connection configs per environment:
```yaml
# env.sl.yml (base)
connections:
  source_db:
    type: "jdbc"
    options:
      url: "jdbc:postgresql://localhost:5432/source"
      driver: "org.postgresql.Driver"
  warehouse:
    type: "duckdb"
    options:
      path: "./data/warehouse.db"
```

### Step 7: Output Generation
Generate:
1. Pipeline specification to `{implementation_artifacts}/pipeline-spec-{{pipeline_name}}.md`
2. Starlake configuration files to `{implementation_artifacts}/starlake-config/`

## Related Starlake Skills

- Use the `load` skill for detailed write strategy options and file format support
- Use the `transform` skill for transformation task configuration
- Use the `extract` skill for extraction method reference
- Use the `dag-generate` skill for orchestration template options
- Use the `connection` skill for connection configuration patterns

## Outcome

A complete, implementation-ready pipeline specification with Starlake YAML configurations for extract, load, transform, and orchestrate — ready for the Data Engineer to implement.
