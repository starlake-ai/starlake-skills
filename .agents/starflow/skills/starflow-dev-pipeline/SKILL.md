---
name: starflow-dev-pipeline
description: 'Implement a data pipeline from a pipeline specification, generating Starlake configuration files. Use when the user says "implement pipeline" or "dev this pipeline".'
---

# Pipeline Implementation

## Overview

Implements a data pipeline by generating all necessary Starlake configuration files (YAML + SQL) from a pipeline specification. Sets up the Starlake metadata directory structure, creates load schemas, transform queries, extraction configs, and DAG definitions. Validates the implementation locally with DuckDB.

**Role Guidance:** Act as a Data Engineer building production-grade data pipelines using Starlake's declarative configuration.

**Design Rationale:** Pipeline implementation with Starlake means creating YAML + SQL files — not writing application code. The framework handles execution mechanics. Focus is on correct configuration, comprehensive schemas, and testable SQL.

## Steps

### Step 1: Load Specification
1. Load the pipeline specification from `{implementation_artifacts}/pipeline-spec-*.md`.
2. Load related artifacts:
   - `{planning_artifacts}/data-architecture-*.md`
   - `{planning_artifacts}/schema-design-*.md`
   - `{implementation_artifacts}/transform-design-*.md`
   - `{implementation_artifacts}/orchestration-design-*.md`
3. Confirm scope: which pipeline tasks to implement?

### Step 2: Project Bootstrap
If the Starlake project doesn't exist yet:
```bash
starlake bootstrap
```
This creates the base `metadata/` directory structure. Then configure:
- `metadata/application.sl.yml` — global settings and connections
- `metadata/env.sl.yml` — base environment variables
- `metadata/types/` — custom type definitions

### Step 3: Implement Load Configuration
For each table in the pipeline:
1. Create domain directory: `metadata/load/{domain}/`
2. Create domain config: `metadata/load/{domain}/_config.sl.yml`
3. Create table schema: `metadata/load/{domain}/{table}.sl.yml`
4. Validate schema: `starlake validate`

### Step 4: Implement Transforms
For each transformation task:
1. Create transform directory: `metadata/transform/{domain}/`
2. Create SQL file: `metadata/transform/{domain}/{task}.sql`
3. Create task config: `metadata/transform/{domain}/{task}.sl.yml`
4. Create expectations macros: `metadata/expectations/{domain}.j2`

### Step 5: Implement Extraction (if applicable)
For JDBC sources:
1. Create extract config: `metadata/extract/{source}.sl.yml`
2. Test extraction: `starlake extract-data`
3. Generate schemas from extracted data: `starlake infer-schema`

### Step 6: Implement Orchestration
1. Create DAG configs: `metadata/dags/{dag_name}.sl.yml`
2. Generate DAG code: `starlake dag-generate`
3. Verify generated DAG files

### Step 7: Local Validation
Run the full pipeline locally with DuckDB:
```bash
# Stage incoming files
starlake stage

# Load data
starlake load

# Run transforms (with dependencies)
starlake transform --name {domain}.{task} --recursive

# Check lineage
starlake lineage --task {domain}.{task}

# Validate all configs
starlake validate
```

### Step 8: Documentation
Generate implementation summary to `{implementation_artifacts}/pipeline-impl-{{pipeline_name}}.md` covering:
- Files created and their purpose
- How to run the pipeline locally
- Known limitations or TODOs
- Deployment instructions

## Related Starlake Skills

- Use the `bootstrap` skill to initialize a new Starlake project
- Use the `load` skill for write strategy and sink configuration details
- Use the `transform` skill for SQL transformation execution options
- Use the `extract-schema` skill for JDBC schema extraction
- Use the `extract-data` skill for data extraction to files
- Use the `dag-generate` skill for DAG generation options and templates
- Use the `validate` skill to check all configuration files
- Use the `config` skill for environment variables and connection setup

## Outcome

A fully implemented, locally validated Starlake pipeline with all YAML configuration, SQL transforms, and orchestration DAGs — ready for deployment.
