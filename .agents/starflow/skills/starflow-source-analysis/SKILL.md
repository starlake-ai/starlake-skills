---
name: starflow-source-analysis
description: 'Analyze data sources in depth: schema, quality, volume, and extraction strategy. Use when the user says "analyze data source" or "profile this data source".'
---

# Data Source Analysis

## Overview

Performs a deep analysis of a specific data source, profiling its schema, data quality characteristics, volume patterns, and extraction requirements. Produces a source analysis document that feeds directly into pipeline specification and Starlake load configuration.

**Role Guidance:** Act as a Data Analyst with expertise in data profiling and source system analysis.

**Design Rationale:** Each data source has unique characteristics that determine how it should be extracted, validated, and loaded. Understanding these upfront prevents pipeline failures and data quality issues in production.

## Steps

### Step 1: Source Identification
1. Ask the user to identify the source to analyze:
   - Source name and type (database table, file, API, stream)
   - Connection details or sample data
   - Business context: what does this data represent?
2. If a domain discovery document exists at `{planning_artifacts}/domain-discovery-*.md`, load it for context.

### Step 2: Schema Analysis
For each attribute/column, document:
| Field | Description |
|-------|-------------|
| Name | Column/field name |
| Type | Data type (maps to Starlake types: string, integer, long, double, decimal, boolean, date, timestamp, bytes) |
| Nullable | Whether NULLs are allowed |
| Primary Key | Part of unique identifier |
| Foreign Key | References to other tables/sources |
| Pattern | Regex pattern for validation (Starlake custom types) |
| Privacy | Privacy classification (PII, sensitive, public) and recommended transform (HIDE, SHA256, MD5, AES) |
| Sample values | Representative examples |

### Step 3: Quality Profiling
Assess data quality dimensions:
- **Completeness**: NULL rates per column
- **Uniqueness**: Duplicate detection on key columns
- **Validity**: Values matching expected patterns/ranges
- **Consistency**: Cross-column consistency rules
- **Timeliness**: Data freshness and update patterns
- Recommend Starlake expectations (Jinja2 macros) for each quality check.

### Step 4: Volume & Pattern Analysis
- Row count (current and growth trend)
- Record size (average, max)
- Update pattern: append-only, full refresh, incremental (CDC), SCD Type 2
- Recommended Starlake write strategy: APPEND, OVERWRITE, UPSERT_BY_KEY, UPSERT_BY_KEY_AND_TIMESTAMP, SCD2, DELETE_THEN_INSERT, OVERWRITE_BY_PARTITION, ADAPTATIVE

### Step 5: Extraction Strategy
- Recommended extraction method (full, incremental, CDC)
- Source type determines the extraction approach:
  - **Database sources**: JDBC extraction with `extract-data` (partition, parallelism, incremental via timestamp)
  - **REST API sources**: REST extraction with `extract-rest-data` (pagination, auth, rate limiting, incremental via field tracking)
  - **File sources**: Direct file ingestion with `load` (landing area pattern matching)
- Extraction frequency
- Partitioning strategy (if applicable)
- For REST APIs: authentication method, pagination type, rate limits, response structure
- File format recommendation (Parquet preferred for columnar analytics, JSON for nested structures)
- Error handling: what happens with rejected records?

### Step 6: Output Generation
Generate the source analysis document and save to `{planning_artifacts}/source-analysis-{{source_name}}.md`.

## Outcome

A detailed source analysis document with schema definition, quality profile, volume characteristics, and extraction strategy — ready for pipeline specification and Starlake YAML configuration generation.