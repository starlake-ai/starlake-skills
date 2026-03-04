---
name: expectations
description: Data quality expectations syntax, built-in macros, and validation patterns
---

# Expectations Skill

Define and enforce data quality checks on loaded and transformed data. Expectations are SQL-based conditions evaluated after data processing — they can warn or fail the pipeline based on configurable thresholds.

## Expectation Syntax

```yaml
expectations:
  - expect: "<query_name>(<params>) => <condition>"
    failOnError: true # or false to continue with warnings
```

Expectations are defined in `table.sl.yml` (load) or `task.sl.yml` (transform).

## Built-in Expectation Macros

Macros are defined as Jinja2 templates in `metadata/expectations/default.j2`:

### is_col_value_not_unique

Check that a column has unique values:

```jinja2
{% macro is_col_value_not_unique(col, table='SL_THIS') %}
    SELECT max(cnt)
    FROM (SELECT {{ col }}, count(*) as cnt FROM {{ table }}
    GROUP BY {{ col }}
    HAVING cnt > 1)
{% endmacro %}
```

### is_row_count_to_be_between

Check that row count falls within a range:

```jinja2
{% macro is_row_count_to_be_between(min_value, max_value, table_name = 'SL_THIS') -%}
    SELECT
        CASE
            WHEN count(*) BETWEEN {{min_value}} AND {{max_value}} THEN 1
        ELSE
            0
        END
    FROM {{table_name}}
{%- endmacro %}
```

### count_by_value

Count rows matching a specific value:

```jinja2
{% macro count_by_value(col, value, table='SL_THIS') %}
    SELECT count(*)
    FROM {{ table }}
    WHERE {{ col }} LIKE '{{ value }}'
{% endmacro %}
```

## Available Variables in Conditions

| Variable | Type | Description |
|---|---|---|
| `count` | Long | Number of rows in query result |
| `result` | Seq[Any] | First row values (0-indexed) |
| `results` | Seq[Seq[Any]] | All rows (for multi-row results) |

## Examples

```yaml
expectations:
  # Uniqueness: order_id must be unique
  - expect: "is_col_value_not_unique('order_id') => result(0) == 1"
    failOnError: true

  # Row count: between 100 and 1 million rows
  - expect: "is_row_count_to_be_between(100, 1000000) => result(0) == 1"
    failOnError: false

  # Value count: at least 10 USA records
  - expect: "count_by_value('country', 'USA') => result(0) >= 10"
    failOnError: false

  # Custom SQL: no negative amounts
  - expect: "SELECT COUNT(*) FROM SL_THIS WHERE amount < 0 => count == 0"
    failOnError: true

  # Null check: email not null
  - expect: "SELECT COUNT(*) FROM SL_THIS WHERE email IS NULL => count == 0"
    failOnError: true
```

## Custom Macros

Create custom Jinja2 macros in `metadata/expectations/`:

```jinja2
{# metadata/expectations/custom.j2 #}

{% macro is_valid_email(col, table='SL_THIS') %}
    SELECT COUNT(*)
    FROM {{ table }}
    WHERE {{ col }} NOT LIKE '%@%.%'
{% endmacro %}
```

Usage:

```yaml
expectations:
  - expect: "is_valid_email('email') => count == 0"
    failOnError: true
```

## Related Skills

- [load](../load/SKILL.md) - Expectations applied during data loading
- [transform](../transform/SKILL.md) - Expectations applied to transform outputs
- [validate](../validate/SKILL.md) - Validate project configuration
- [config](../config/SKILL.md) - Configuration reference
