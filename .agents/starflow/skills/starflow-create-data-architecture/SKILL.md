---
name: starflow-create-data-architecture
description: 'Design the overall data architecture including layers, storage, engines, and governance. Use when the user says "create data architecture" or "design the data platform".'
---

# Data Architecture Design

## Overview

Guides the creation of a comprehensive data architecture document covering data layers (landing, staging, warehouse, mart), engine selection, storage strategy, governance framework, and environment configuration. The output drives all downstream Starlake configuration and pipeline design decisions.

**Role Guidance:** Act as a Data Architect with expertise in modern data stack, warehouse design patterns, and Starlake's declarative pipeline platform.

**Design Rationale:** A solid data architecture prevents ad-hoc pipeline sprawl and establishes conventions that the entire team follows. Starlake enforces many of these patterns through its directory structure and configuration hierarchy.

## Steps

### Step 1: Requirements Gathering
1. Load domain discovery from `{planning_artifacts}/domain-discovery-*.md` if available.
2. Clarify:
   - Target use cases (analytics, reporting, ML, operational)
   - Latency requirements (batch, micro-batch, real-time)
   - Scale expectations (GB, TB, PB)
   - Compliance and security requirements
   - Budget and team constraints

### Step 2: Layer Design
Define the data layers and their purpose:

| Layer | Starlake Stage | Purpose | Write Strategy |
|-------|---------------|---------|----------------|
| **Landing** | incoming/pending | Raw data as-is from source | N/A (file staging) |
| **Bronze / Raw** | accepted | Validated, typed, privacy-applied | APPEND or OVERWRITE |
| **Silver / Curated** | transform (business) | Cleaned, deduplicated, conformed | UPSERT_BY_KEY or SCD2 |
| **Gold / Mart** | transform (business) | Business-ready aggregations | OVERWRITE or OVERWRITE_BY_PARTITION |

### Step 3: Engine & Storage Selection
- **Development engine**: DuckDB (local, fast iteration)
- **Production engine(s)**: BigQuery / Snowflake / Databricks / PostgreSQL
- **File storage**: Local filesystem (dev), Cloud storage (prod: GCS, S3, ADLS)
- **File format**: Parquet (default), JSON (nested/semi-structured), CSV (legacy compatibility)
- Document connection configurations per environment.

### Step 4: Starlake Project Structure
Define the metadata directory structure:
```
metadata/
  application.sl.yml       # Global config, connections, defaults
  env.sl.yml               # Base environment variables
  env.PROD.sl.yml           # Production overrides
  types/
    default.sl.yml          # Built-in types
    custom.sl.yml           # Project-specific types (regex patterns)
  load/
    {domain}/
      _config.sl.yml        # Domain defaults (incoming dir, connection)
      {table}.sl.yml        # Per-table schema and load config
  transform/
    {domain}/
      {task}.sl.yml          # Transform config (write strategy, sink)
      {task}.sql             # SQL transformation
  extract/
    {source}.sl.yml          # JDBC/API extraction config
  dags/
    {schedule}.sl.yml        # Orchestration DAG definitions
  expectations/
    {domain}.j2              # Reusable data quality macros
```

### Step 5: Governance Framework
- Data classification (public, internal, confidential, restricted)
- Privacy strategy: column-level annotations (HIDE, SHA256, MD5, AES)
- Access control: Starlake ACL policies and IAM integration
- Data retention policies per layer
- Lineage tracking strategy

### Step 6: Environment Strategy
- Development: DuckDB + local filesystem
- Staging: Target engine + cloud storage (subset of data)
- Production: Target engine + cloud storage (full data)
- Environment switching via `SL_ENV` and `env.{ENV}.sl.yml` files
- Connection references (`connectionRef`) switchable per environment

### Step 7: Output Generation
Generate the data architecture document and save to `{planning_artifacts}/data-architecture-{{project_name}}.md`.

## Outcome

A comprehensive data architecture document covering layers, engines, Starlake project structure, governance, and environment strategy: ready to guide all pipeline implementation.