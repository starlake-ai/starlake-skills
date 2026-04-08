---
name: starflow-transform-design
description: 'Design SQL transformations for data pipelines with quality checks and dependency management. Use when the user says "design transforms" or "create SQL transformations".'
---

# Transform Design

## Overview

Guides the design of SQL transformations that turn raw/curated data into business-ready datasets. Produces Starlake-compatible `.sql` files and their companion `.sl.yml` configuration files, including write strategies, sink configuration, and data quality expectations.

**Role Guidance:** Act as a Data Engineer with expertise in SQL analytics, data modeling, and Starlake's transform engine.

**Design Rationale:** Transformations are where business logic lives. They must be pure SQL (or Python for complex cases), testable locally on DuckDB, and deployable to any target engine via Starlake's SQL transpiler. Dependencies are inferred from SQL table references.

## Steps

### Step 1: Context Loading
1. Load available artifacts:
   - `{planning_artifacts}/data-architecture-*.md`
   - `{implementation_artifacts}/pipeline-spec-*.md`
   - `{planning_artifacts}/schema-design-*.md`
2. Identify the transform domain and target tables.

### Step 2: Transformation Inventory
List all transformations needed:
| Task Name | Source Tables | Target Table | Write Strategy | Schedule |
|-----------|-------------|--------------|----------------|----------|
| e.g., `orders_daily_agg` | `sales.orders`, `ref.products` | `analytics.orders_daily` | OVERWRITE_BY_PARTITION | Daily |

### Step 3: SQL Design
For each transformation, write the SQL:
```sql
-- Task: orders_daily_agg
-- Dependencies: sales.orders, ref.products (auto-inferred)
SELECT
  DATE(o.order_date) AS order_date,
  p.category,
  COUNT(*) AS order_count,
  SUM(o.amount) AS total_amount,
  AVG(o.amount) AS avg_amount
FROM sales.orders o
JOIN ref.products p ON o.product_id = p.product_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY DATE(o.order_date), p.category
```

Guidelines:
- Use standard SQL (Starlake transpiles across engines)
- Reference source tables with `{domain}.{table}` notation
- Use `SL_THIS` to reference the current task's output table in expectations
- For incremental processing, use partition pruning and date filters
- Avoid engine-specific syntax unless necessary

### Step 4: Task Configuration
For each task, create the `.sl.yml`:
```yaml
version: 1
transform:
  name: "orders_daily_agg"
  writeStrategy:
    type: "OVERWRITE_BY_PARTITION"
    key: ["order_date"]
  sink:
    partition: ["order_date"]
    clustering: ["category"]
    connectionRef: "warehouse"
  expectations:
    - query: "SELECT COUNT(*) > 0 FROM SL_THIS"
      name: "not_empty"
      failSeverity: "ERROR"
    - query: "SELECT COUNT(*) = 0 FROM SL_THIS WHERE total_amount < 0"
      name: "no_negative_amounts"
      failSeverity: "ERROR"
```

### Step 5: Dependency Graph
Document the transformation DAG:
- List each task and its dependencies (from SQL table references)
- Identify the execution order
- Flag any circular dependencies
- Determine which tasks support `--recursive` execution

### Step 6: Output Generation
Generate:
1. Transform design document to `{implementation_artifacts}/transform-design-{{domain}}.md`
2. SQL files to `{implementation_artifacts}/transforms/{domain}/`
3. Task YAML files alongside the SQL files

## Related Starlake Skills

- Use the `transform` skill for SQL/Python transformation execution options
- Use the `expectations` skill for transform-level data quality checks
- Use the `config` skill for available SQL functions and type reference

## Outcome

Complete SQL transformations with Starlake task configurations, quality expectations, and a documented dependency graph — ready for implementation and testing.
