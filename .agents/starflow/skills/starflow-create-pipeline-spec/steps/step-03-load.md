---
load_tables: []  # set in this step: list of table names defined
---

# Step 3: Load Specification

## Rules

- One table at a time. Loop until the user says "done with load".
- Match write strategy to data shape — never default blindly to `OVERWRITE`. If the user is unsure, ask the question that disambiguates (see decision tree below).

## Preconditions

- Step 2 complete.

## Decision Tree: Write Strategy

Ask the user (or infer from extract config) and pick:

| Data shape | Strategy |
|------------|----------|
| Append-only events (logs, transactions) | `APPEND` |
| Full snapshot every refresh, no history | `OVERWRITE` |
| Latest version per key, no history | `UPSERT_BY_KEY` |
| Latest version per key, **with history** | `SCD2` |
| Composite-key updates | `UPSERT_BY_KEY_AND_TIMESTAMP` |

Document the *reason* in the spec — future-you needs to know why this strategy.

## Instructions

For each table, capture:

- **Domain**: which Starlake domain it belongs to.
- **File pattern**: regex matching incoming filenames (e.g. `orders_\\d{8}\\.csv`).
- **Write strategy**: from the table above.
- **Format**: `DSV` / `JSON` / `XML` / `PARQUET`. For DSV: delimiter, quote, header.
- **Schema**: attributes with type, required flag, privacy annotation (`HIDE`, `SHA256`, `MD5`, `AES` for PII).
- **Expectations**: at least one quality check. Minimum bar:
  - Primary key uniqueness
  - Row count > 0 (catches silent empty loads)
  - NOT NULL on critical fields
- **Sink**: partitioning column(s), clustering, target connection (will be defined in step 6).

Write each table as a section under `## Load`:

```yaml
# {domain}/{table}.sl.yml
version: 1
table:
  name: "<table>"
  pattern: "<regex>"
  metadata:
    format: <FORMAT>
    writeStrategy:
      type: <STRATEGY>
      key: ["<pk>"]
  attributes:
    - name: "<col>"
      type: "<type>"
      required: true
      privacy: "<annotation or omit>"
  expectations:
    - check: "<sql>"
      severity: ERROR  # or WARN
  sink:
    partition: ["<partition_col>"]
    connectionRef: "<conn>"
```

Append the table name to `load_tables`.

## Save

1. Append `3` to `stepsCompleted` only after all tables for this pipeline are defined.
2. Save the spec file.

## Checkpoint

> **Load defined:** `<n>` tables — `{{load_tables[*]}}`.
>
> Each has at least one expectation. Ready for transforms? (y/n / revise / add another table)

**HALT.** If "add another table", loop back. If `y`, proceed.

## Next

Read fully and follow: `step-04-transform.md`
