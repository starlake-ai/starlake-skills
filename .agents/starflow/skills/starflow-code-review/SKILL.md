---
name: starflow-code-review
description: 'Review data pipeline configuration and SQL for correctness, performance, and best practices. Use when the user says "review pipeline" or "review this data code".'
---

# Data Pipeline Code Review

## Overview

Reviews Starlake pipeline configuration (YAML) and SQL transformations for correctness, performance, data quality coverage, and adherence to best practices. Uses parallel review layers adapted for data engineering concerns.

**Role Guidance:** Act as a Senior Data Engineer performing an adversarial review of pipeline configurations.

## Review Layers

### Layer 1: Configuration Correctness
- All `.sl.yml` files have `version: 1` header
- File patterns (regex) correctly match expected filenames
- Write strategies match the data update pattern (e.g., SCD2 for slowly changing dimensions)
- Attribute types reference defined types (built-in or custom)
- Required fields are marked correctly
- Privacy annotations are applied to PII columns
- Connection references resolve to defined connections
- DAG assignments reference defined DAGs

### Layer 2: SQL Quality
- Standard SQL used (no engine-specific syntax unless justified)
- Table references use `{domain}.{table}` notation
- JOINs have proper ON clauses (no cartesian products)
- WHERE clauses use partition columns for pruning
- GROUP BY matches SELECT non-aggregated columns
- No SELECT * in transforms (explicit column lists)
- CTEs preferred over nested subqueries for readability
- Date handling uses proper functions (not string manipulation)

### Layer 3: Data Quality Coverage
- Every load table has at least one expectation
- Primary key uniqueness is validated
- NOT NULL constraints are enforced via expectations
- Referential integrity checks exist for foreign keys
- Row count checks prevent empty loads from succeeding
- Business rule validations cover critical logic
- Expectations use appropriate severity (ERROR vs WARN)

### Layer 4: Performance & Scalability
- Partitioning strategy aligns with query patterns
- Clustering columns match common filter/join columns
- Incremental loads use partition pruning
- Large table JOINs are optimized (small table on right side)
- No full table scans where incremental processing is possible
- Write strategies avoid unnecessary full overwrites

### Layer 5: Operational Readiness
- DAG schedules avoid resource contention
- Retry policies are configured for transient failures
- Timeout values are set appropriately
- Alerting is configured for SLA-critical pipelines
- Lineage is traceable through all pipeline stages
- Environment configs exist for dev/staging/prod

## Output

A structured review report with findings categorized as:
- **BLOCKER**: Must fix before deployment
- **WARNING**: Should fix, risk of future issues
- **SUGGESTION**: Nice to have improvements
- **APPROVED**: Aspects that pass review

## Related Starlake Skills

- Use the `validate` skill to run automated configuration validation
- Use the `expectations` skill to verify expectation syntax
- Use the `freshness` skill for data freshness checks
- Use the `test` skill for running pipeline tests

## Outcome

A comprehensive review report ensuring pipeline quality, performance, and operational readiness before deployment.
