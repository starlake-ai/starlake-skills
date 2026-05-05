---
transform_tasks: []  # set in this step
---

# Step 4: Transform Specification

## Rules

- Skip this step (and mark complete) only if the user explicitly says "no transforms — load only".
- Standard SQL only. Engine-specific syntax requires a written justification in the task block.
- Dependencies are inferred from `FROM` / `JOIN` references in the SQL — but document them explicitly so the spec is readable without parsing.

## Preconditions

- Step 3 complete. At least one load table exists (or the user is building a pure-transform pipeline that consumes existing tables).

## Instructions

For each transformation task:

1. **Task name**: kebab-case, scoped by domain (e.g. `orders.daily-revenue`).
2. **Source tables**: list `{domain}.{table}` references the SQL touches.
3. **Target table**: `{domain}.{table}` and write strategy (same decision tree as step 3).
4. **SQL logic**: paste the query. Use CTEs over nested subqueries. No `SELECT *`. Use partition columns in `WHERE` for pruning.
5. **Post-transform expectations**: at least one. Common bars:
   - Output row count within expected range
   - Aggregations match an independent count
   - No nulls in derived keys
6. **Recursive execution**: should upstream transforms run first (`recursive: true`)? Default `false` — let the orchestrator handle ordering when possible.

Write each task under `## Transform`:

```yaml
# {domain}/{task}.sl.yml
version: 1
task:
  name: "<task>"
  writeStrategy:
    type: <STRATEGY>
    key: ["<pk>"]
  expectations:
    - check: "<sql>"
      severity: ERROR
```

```sql
-- {domain}/{task}.sql
WITH base AS (
  SELECT col_a, col_b, …
  FROM {source_domain}.{source_table}
  WHERE partition_col >= :start_date
)
SELECT …
FROM base
JOIN {other_domain}.{ref_table} USING (col_a)
```

Append the task name to `transform_tasks`.

## Document the DAG

After all tasks are defined, add a "Transform DAG" subsection listing dependencies as bullets (one line per task: `task → depends on [task1, task2]`). This is the human-readable counterpart of what the orchestrator will infer.

## Save

1. Append `4` to `stepsCompleted`.
2. Save the spec file.

## Checkpoint

> **Transforms defined:** `<n>` tasks. DAG depth: `<max-depth>`.
>
> Ready for orchestration? (y/n / revise / add another task)

**HALT.** Loop on "add another task" or "revise". On `y`, proceed.

## Next

Read fully and follow: `step-05-orchestrate.md`
