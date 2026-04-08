---
stepsCompleted: []
inputDocuments: []
date: {{system-date}}
author: {{user_name}}
pipeline_name: {{pipeline_name}}
domain: {{domain_name}}
status: draft
---

# Pipeline Specification: {{pipeline_name}}

## Overview
- **Domain:** {{domain_name}}
- **Business Objective:**
- **SLA:**
- **Schedule:**
- **Engine:** {{default_engine}} (dev) / {{target_engine}} (prod)

## Extract

### Source: {source_name}
- **Type:** JDBC / File / API / Stream
- **Connection:**
- **Extraction Method:** Full / Incremental / CDC
- **Frequency:**

## Load

### Table: {table_name}
- **Domain:** {domain_name}
- **File Pattern:** `{regex_pattern}`
- **Write Strategy:** APPEND / OVERWRITE / UPSERT_BY_KEY / SCD2
- **Format:** DSV / JSON / XML / Parquet

#### Schema
| Attribute | Type | Required | Privacy | Description |
|-----------|------|----------|---------|-------------|

#### Expectations
| Check | SQL | Severity |
|-------|-----|----------|

## Transform

### Task: {task_name}
- **Source Tables:**
- **Target Table:** {domain}.{table}
- **Write Strategy:**
- **Dependencies:** (auto-inferred from SQL)

```sql
-- SQL transformation
```

#### Expectations
| Check | SQL | Severity |
|-------|-----|----------|

## Orchestrate

### DAG: {dag_name}
- **Schedule:** `{cron_expression}`
- **Template:** dag_standard.py.j2
- **Tasks:**
- **Timeout:**
- **Retry Policy:**
- **Alerts:**

## Environment Configuration

### Connections
| Name | Dev | Staging | Production |
|------|-----|---------|------------|

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
