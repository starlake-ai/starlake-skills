---
name: test
description: Run integration tests for your Starlake project
---

# Test Skill

Runs integration tests for your Starlake project. Tests verify that load and transform tasks produce the expected output by comparing actual results against expected data files stored in `metadata/tests/`, and by evaluating the table's or task's declared expectations.

## Usage

```bash
starlake test [options]
```

## Options

- `--load`: Test load tasks only
- `--transform`: Test transform tasks only
- `--domain <value>`: Test only this domain
- `--table <value>`: Test only this table/task within the selected domain — **broken up to 1.6.0**, see warning below
- `--test <value>`: Run only the test cases with this name
- `--site`: Generate test results as a website
- `--outputDir <value>`: Output directory for test results
- `--accessToken <value>`: Access token for authentication (e.g. GCP)
- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`

> **Warning (up to Starlake 1.6.0):** `--table` is wired to the test-name filter
> ([starlake#1676](https://github.com/starlake-ai/starlake/issues/1676)), so any
> table-scoped run — `--domain X --table Y` or `--table domain.table` — silently
> executes **0 tests and exits 0**, which reads as green in CI. Until the fix
> ships, scope with `--domain` (which works) and check the report's test count.
> `--test <name>` works, but filters by test-case name across **all** tables of
> the selected domain(s).

## How tests execute

- Each test case runs in its own **throwaway DuckDB database** under the report
  directory — never against the connection configured in your application
  settings. Locally no credentials (`--accessToken`) are needed.
- Two oracles are evaluated per test: the `_expected*` files (data comparison)
  and the table's/task's **declared expectations** (see the
  [expectations](../expectations/SKILL.md) skill). A test succeeds only if both
  pass.
- Data comparison is **set-based** (a double `EXCEPT`): row order is ignored,
  and the column **names** must match (case-insensitive) — keep the column
  order aligned with the target too, since the row comparison itself is
  positional. Null values are spelled `null` in the CSV. On mismatch the
  differences are dumped next to the report; beware, the two filenames are
  **inverted** up to 1.6.0
  ([starlake#1677](https://github.com/starlake-ai/starlake/issues/1677)):
  `missing<Name>.csv` holds the rows produced but not expected, and
  `not_expected<Name>.csv` the rows expected but not produced.
- `SL_ENV` is honored. If your connection sets a jinja-driven
  `_transpileDialect` (e.g. transpiling BigQuery SQL for local DuckDB runs),
  use a dedicated test env (e.g. `env.TEST.sl.yml` forcing the DuckDB dialect):
  the harness substitutes table refs double-quoted, which the source dialect's
  parser may reject — the harness then logs the error and falls back to the
  raw, untranspiled SQL instead of failing
  ([starlake#1669](https://github.com/starlake-ai/starlake/issues/1669)).

```bash
SL_ENV=TEST starlake test
```

## Test Directory Structure

Tests are organized in `metadata/tests/`:

```
metadata/tests/
├── load/
│   └── {domain}/
│       └── {table}/
│           └── {test_name}/
│               ├── _incoming.{file}       # Input file to load (optional)
│               └── _expected.csv          # Expected output data (optional; .json also supported)
└── transform/
    └── {domain}/
        └── {task}/
            └── {test_name}/
                ├── _expected.csv          # Expected output
                └── {domain}.{table}.csv   # Mock for each referenced table
```

### Load Test Example

```
metadata/tests/load/starbake/orders/test1/
├── _incoming.orders_20240301.json         # Input file to load
└── _expected.csv                          # Expected loaded data
```

The `_incoming.` suffix must match the table's file pattern (it drives pattern
matching and pattern-derived variables such as the file date). `_expected.csv`
is **optional** for load tests: the table's declared expectations also run and
can serve as the sole oracle. The `_incoming.` file itself is optional too:
without it nothing is ingested and the target table is taken as preloaded from
the mock data — useful for expectation-only tests.

Note for rejection tests: type-pattern row rejection only happens with the
**Spark loader** — the native loader does not validate type patterns, so a
rejection test passes or fails depending on the configured loader.

### Transform Test Example

```
metadata/tests/transform/kpi/revenue_summary/test1/
├── _expected.csv                          # Expected transform output
├── starbake.orders.csv                    # Mock source: orders table
└── starbake.order_lines.csv               # Mock source: order_lines table
```

Mock **every** table the test touches, including the ones referenced by the
task's declared expectations: for a MERGE-style task whose expectations check
key integrity against the target table, add a `{domain}.{target_table}.csv`
mock too, otherwise the expectation query fails on a missing table.

### Named expectations: excluding non-deterministic columns

When the output contains non-deterministic columns (e.g. a `CURRENT_TIMESTAMP`
ingestion column), a full-schema `_expected.csv` can never match. Use a *named*
expectation instead: `_expected<Name>.csv` paired with `_expected<Name>.sql`
holding the projected column list (or a full `SELECT` over the output) — only
those columns are compared. The `.sql`
file is mandatory: a named `.csv` without its `.sql` companion is **silently
ignored**. Expected files can be `.csv` or `.json`.

```
metadata/tests/transform/kpi/revenue_summary/test1/
├── _expectedDeterministic.sql             # e.g.: order_id, total_amount, currency
├── _expectedDeterministic.csv             # Expected values for those columns only
└── starbake.orders.csv
```

## Examples

### Run All Tests

```bash
starlake test
```

### Run Load Tests Only

```bash
starlake test --load
```

### Run Transform Tests Only

```bash
starlake test --transform
```

### Run Tests for a Specific Domain

```bash
starlake test --domain starbake
```

### Run the Test Cases with a Given Name

```bash
starlake test --domain starbake --test test1
```

(Scoping to a single table with `--table` silently runs nothing up to 1.6.0 —
see the warning in [Options](#options).)

### Generate Test Results Website

```bash
starlake test --site --outputDir /tmp/test-results
```

`junit.xml` is written on **every** run (default report folder
`test-reports/`); `--site` additionally produces the browsable `index.html`.
Caveats: `starlake test` always exits 0 — even with failing tests — so CI must
gate on junit.xml's `tests` **and** `failures` counts, never on the exit code;
and the site's task-coverage figure under-reports when several tasks target
the same table
([starlake#1670](https://github.com/starlake-ai/starlake/issues/1670)).

## Related Skills

- [load](../load/SKILL.md) - Load data (tested by load tests)
- [transform](../transform/SKILL.md) - Run transforms (tested by transform tests)
- [expectations](../expectations/SKILL.md) - Declared expectations, the second test oracle
- [validate](../validate/SKILL.md) - Validate project configuration
