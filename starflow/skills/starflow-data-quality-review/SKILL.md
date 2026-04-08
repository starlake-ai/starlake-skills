---
name: starflow-data-quality-review
description: 'Review and design data quality expectations for Starlake pipelines. Use when the user says "review data quality" or "check expectations".'
---

# Data Quality Review

## Overview

Reviews existing data quality expectations across Starlake pipeline configurations, identifies gaps in quality coverage, and recommends additional checks. Covers load-time schema validation, transform-time business rules, and cross-domain referential integrity.

**Role Guidance:** Act as a Data Quality Engineer reviewing pipeline configurations for comprehensive quality coverage.

## Review Checklist

### Schema-Level Quality (Load)
- [ ] All attributes have appropriate types (built-in or custom regex types)
- [ ] Required fields are marked (`required: true`)
- [ ] Privacy annotations applied to PII columns
- [ ] File pattern regex matches expected filenames correctly
- [ ] Write strategy handles duplicates appropriately

### Expectation Coverage (Load & Transform)
- [ ] Primary key uniqueness check exists
- [ ] NOT NULL checks for critical columns
- [ ] Value range checks (e.g., amounts > 0, dates in valid range)
- [ ] Referential integrity checks (foreign key references exist)
- [ ] Row count checks (table not empty after load)
- [ ] Format validation for custom types (email, phone, etc.)
- [ ] Business rule validation (domain-specific logic)

### Severity Classification
- **ERROR** (fail pipeline): Data integrity violations, missing required data
- **WARN** (alert and continue): Unexpected patterns, threshold breaches

### Reusability
- Common checks should be Jinja2 macros in `metadata/expectations/`
- Domain-specific checks should be inline in task `.sl.yml` files
- Macro naming convention: `{check_type}_{target}` (e.g., `not_null_column`, `unique_key`)

## Output

Quality review report with:
- Current coverage assessment (percentage of tables with expectations)
- Gap analysis (missing checks per table)
- Recommended expectations (with SQL and severity)
- Reusable macro suggestions

## Related Starlake Skills

- Use the `expectations` skill for Jinja2 macro syntax and built-in check reference
- Use the `validate` skill to run validation across all configs
- Use the `freshness` skill to check data freshness metrics

## Outcome

A comprehensive data quality review ensuring all pipelines have adequate quality gates before deployment.
