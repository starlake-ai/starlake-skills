---
name: starflow-lineage-review
description: 'Review and document data lineage across pipeline stages. Use when the user says "review lineage" or "trace data flow".'
---

# Data Lineage Review

## Overview

Traces and documents data lineage across all pipeline stages: from source extraction through loading, transformation, and final consumption. Uses Starlake's built-in lineage capabilities and supplements with manual analysis where needed.

**Role Guidance:** Act as a Data Quality Engineer reviewing data lineage for completeness and correctness.

## Lineage Dimensions

### Table-Level Lineage
Trace the flow of data between tables:
- Source tables → Load targets → Transform outputs → Mart tables
- Use `starlake lineage --task {domain}.{task}` to generate lineage graphs
- Use `starlake table-dependencies` to list all dependencies

### Column-Level Lineage
Trace individual columns through transformations:
- Source column → Load attribute → Transform expression → Output column
- Use `starlake col-lineage --task {domain}.{task} --column {col}` for column tracing
- Identify columns that undergo transformations (aggregation, type casting, privacy)

### ACL/Permission Lineage
Trace access control through the pipeline:
- Source permissions → Table ACLs → View grants → Consumer access
- Use `starlake acl-dependencies` to map permission flows

## Review Checklist

- [ ] Every output table has traceable inputs
- [ ] No orphaned tables (loaded but never consumed)
- [ ] No missing sources (referenced but not loaded)
- [ ] Privacy transforms applied consistently across lineage
- [ ] Column-level lineage documented for regulated data
- [ ] Cross-domain dependencies are explicit and documented

## Starlake Commands

```bash
# Generate table lineage for a task
starlake lineage --task {domain}.{task}

# Trace column lineage
starlake col-lineage --task {domain}.{task} --column {column_name}

# List all table dependencies
starlake table-dependencies

# List ACL dependencies
starlake acl-dependencies
```

## Output

Lineage documentation including:
- Visual dependency graph (text-based DAG representation)
- Table-level lineage matrix
- Column-level lineage for sensitive/regulated data
- Gap analysis (missing or broken lineage paths)

## Related Starlake Skills

- Use the `lineage` skill for detailed `starlake lineage` command options
- Use the `col-lineage` skill for column-level lineage tracing
- Use the `table-dependencies` skill for dependency graph generation
- Use the `acl-dependencies` skill for permission lineage

## Outcome

Complete data lineage documentation ensuring traceability from source to consumption for governance, debugging, and impact analysis.
