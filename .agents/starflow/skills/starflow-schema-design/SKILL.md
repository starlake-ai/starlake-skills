---
name: starflow-schema-design
description: 'Design Starlake-compatible table schemas with types, constraints, privacy, and expectations. Use when the user says "design schema" or "create table definition".'
---

# Schema Design

## Overview

Guides the design of Starlake-compatible table schemas including attribute definitions, custom types with regex validation, privacy annotations, and data quality expectations. Outputs ready-to-use `.sl.yml` configuration files for Starlake load operations.

**Role Guidance:** Act as a Data Architect with deep knowledge of Starlake's schema definition format and data typing system.

**Design Rationale:** Schemas are the contract between data producers and consumers. Starlake enforces schemas at load time, rejecting records that don't conform. Well-designed schemas prevent bad data from entering the pipeline.

## Steps

### Step 1: Input Gathering
1. Load source analysis from `{planning_artifacts}/source-analysis-*.md` if available.
2. Load data architecture from `{planning_artifacts}/data-architecture-*.md` if available.
3. Identify the domain and table(s) to define.

### Step 2: Custom Type Definition
Define project-specific types in `metadata/types/custom.sl.yml`:
```yaml
version: 1
types:
  - name: "email"
    pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    primitiveType: "string"
  - name: "phone"
    pattern: "^\\+?[0-9\\s\\-\\.\\(\\)]{7,20}$"
    primitiveType: "string"
  - name: "sku"
    pattern: "^[A-Z]{2,4}-[0-9]{4,8}$"
    primitiveType: "string"
```

### Step 3: Table Schema Definition
For each table, create the `.sl.yml` file with:
- **metadata**: name, pattern (file matching regex), write strategy, sink config
- **attributes**: name, type, required, privacy, comment, array/struct support
- **merge keys**: for UPSERT and SCD2 strategies
- **expectations**: inline data quality checks

Example structure:
```yaml
version: 1
table:
  name: "customers"
  pattern: "customers.*\\.csv"
  writeStrategy:
    type: "UPSERT_BY_KEY_AND_TIMESTAMP"
    key: ["customer_id"]
    timestamp: "updated_at"
  attributes:
    - name: "customer_id"
      type: "long"
      required: true
    - name: "email"
      type: "email"
      required: true
      privacy: "SHA256"
    - name: "name"
      type: "string"
      required: true
    - name: "created_at"
      type: "timestamp"
      required: true
    - name: "updated_at"
      type: "timestamp"
      required: true
```

### Step 4: Expectations Design
Define data quality expectations as Jinja2 macros:
```sql
{# Reusable macro for non-null check #}
{% macro not_null(column) %}
  SELECT COUNT(*) = 0 FROM SL_THIS WHERE {{ column }} IS NULL
{% endmacro %}

{# Domain-specific check #}
{% macro valid_email(column) %}
  SELECT COUNT(*) = 0 FROM SL_THIS
  WHERE {{ column }} NOT LIKE '%@%.%'
{% endmacro %}
```

### Step 5: Domain Configuration
Create the domain `_config.sl.yml`:
```yaml
version: 1
load:
  metadata:
    directory: "{incoming_dir}/{domain_name}"
    multiline: false
    encoding: "UTF-8"
    withHeader: true
    separator: ","
    quote: "\""
```

### Step 6: Output Generation
Generate:
1. Schema documentation to `{planning_artifacts}/schema-design-{{domain_name}}.md`
2. Ready-to-use `.sl.yml` files to `{implementation_artifacts}/schemas/`

## Related Starlake Skills

- Use the `config` skill for the complete attribute types catalog (string, int, long, date, timestamp, etc.)
- Use the `load` skill for write strategy reference (APPEND, OVERWRITE, SCD2, UPSERT, etc.)
- Use the `infer-schema` skill to auto-infer schemas from existing data files
- Use the `expectations` skill for Jinja2 macro syntax when defining quality checks

## Outcome

Complete Starlake-compatible schema definitions with custom types, privacy annotations, and expectations: ready to be placed in the `metadata/load/` directory.