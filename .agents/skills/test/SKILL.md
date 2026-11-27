---
name: test
description: Run integration tests with `starlake test` — verify load and transform tasks against expected data files and declared expectations in an isolated DuckDB, for regression testing, CI test reports (junit.xml), and coverage sites
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
- `--table <value>`: Test only the table (load) or task (transform) folder with this exact name, in the selected domain or, without `--domain`, in every domain — **broken on 1.7.11 and earlier, every 1.8.x, 1.9.0 and 1.9.1**, see warning below
- `--test <value>`: Run only the test cases with this name
- `--site`: Generate test results as a website
- `--outputDir <value>`: Output directory for test results
- `--accessToken <value>`: Access token for authentication (e.g. GCP)
- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`

> **Warning — affected versions: 1.7.11 and earlier, every 1.8.x, 1.9.0 and
> 1.9.1, and snapshot builds without the fix:** `--table` is wired to the
> test-name filter
> ([starlake#1676](https://github.com/starlake-ai/starlake/issues/1676)):
> `--domain X --table Y` runs only the test cases named `Y`, usually none, so
> it silently executes **0 tests and exits 0**, which reads as green in CI, and
> `--domain X --table Y --test Z` runs every test named `Z` in **all** tables of
> the domain (the last of `--table` and `--test` wins). On those versions, do
> not pass `--table`: narrow the run with `--domain`, `--load`, `--transform`
> and `--test`. As `--test` selects that test name in every table of the
> domain, give test cases table-specific names (e.g. `orders_nominal`) when one
> table must run alone, then check in `junit.xml` that `tests` is above 0 and
> that the `testcase` names (`<domain>.<table>.<test>`) are the ones you meant.
>
> **Fixed in 1.7.12 on the 1.7 line, and in the first 1.9 release after
> 1.9.1** (no 1.8.x release carries the fix:
> [starlake#2022](https://github.com/starlake-ai/starlake/pull/2022),
> [starlake#2034](https://github.com/starlake-ai/starlake/pull/2034)): `--table`
> takes the exact name of the table or task folder, so `--table starbake.orders`
> matches no folder and fails (write `--domain starbake --table orders`), and an
> explicit `--domain`, `--table` or `--test` selection that yields no test
> result fails with exit code 1 (`No test matches ...`). To tell which
> behaviour a build has, whatever its version label,
> `starlake test --domain <a domain> --table no_such_folder; echo $?` prints 1
> on a fixed build and 0 on an affected one.

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
  differences are dumped in the test's report folder (by default
  `test-reports/<load|transform>/<domain>/<table or task>/<test>/`):
  `missing<Name>.csv` holds the rows expected but not produced, and
  `not_expected<Name>.csv` the rows produced but not expected, `<Name>` being
  the suffix of the expected file (`missing.csv` for `_expected.csv`,
  `missingDeterministic.csv` for `_expectedDeterministic.csv`). When the column
  sets differ, both files hold a one-line notice instead of rows and the record
  counts read 0: fix the columns first. Beware: on the affected versions
  (1.7.11 and earlier, every 1.8.x, 1.9.0 and 1.9.1) the two files hold each
  other's rows, and so do the `Missing records` and `Not expected records`
  counts of the JUnit failure message and the Missing Records and Unexpected
  Records panels of the `--site` pages; the column counts are right on every
  version ([starlake#1677](https://github.com/starlake-ai/starlake/issues/1677)).
- JUnit counts one test case per oracle checked (each `_expected*` file and
  each declared expectation), plus one per test whose task fails to run, not
  one per test folder. A test folder with neither a usable `_expected*` file
  nor a declared expectation adds none, although the console prints
  `Test <domain>.<table>.<test> succeeded`; so does a folder whose table or
  task is no longer declared (`Table / Task <domain>.<name> not found`).
  Compare `tests` with the number you expect, not only with 0. On fixed
  versions, a selection that reaches only such folders fails with
  `No test matches`.
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

### Run the Test Cases of One Table

```bash
starlake test --domain starbake --table orders
starlake test --domain starbake --table orders --test test1
```

(Needs 1.7.12 or later on the 1.7 line, or a 1.9 release after 1.9.1. On the
affected versions, every 1.8.x included, the first command runs only the test
cases named `orders`, usually none, and the second runs every test named
`test1` in the domain: see the warning in [Options](#options).)

### Generate Test Results Website

```bash
starlake test --site --outputDir /tmp/test-results
```

`junit.xml` is written at the end of every run that completes, with or
without `--site` (default report folder `test-reports/`, or `--outputDir`);
`--site` additionally produces the browsable `index.html`. Caveats:

- A failing test never changes the exit code: `starlake test` exits 0 when
  tests fail, on every version. It also exits 0 with 0 tests when no
  `--domain`, `--table` or `--test` is given (`--load` and `--transform` are
  not selections) and, on the affected versions, when its selection matches no
  test. On fixed versions, an explicit selection that yields no test result
  exits 1, after writing `junit.xml` with `tests="0"`.
- A run that aborts (for instance on a mock CSV that DuckDB cannot load) exits
  1 without rewriting `junit.xml`: delete the report folder before each run, so
  that a previous report is never read as this run's verdict.
- CI therefore gates on three signals: a non-zero exit code, `tests="0"`, and
  `failures` above 0 in `junit.xml`. It never relies on the exit code alone,
  and never masks it with `|| true`.
- The site's task-coverage figure under-reports when several tasks target the
  same table ([starlake#1670](https://github.com/starlake-ai/starlake/issues/1670)).

## Upgrading to a fixed release

- A `--domain`, `--table` or `--test` selection that yields no test result now
  exits 1, where it passed with 0 tests: a script that runs
  `starlake test --domain <d>` for every domain, or `--load` and `--transform`
  separately per domain, fails on a domain without tests of that kind. Run
  `starlake test` once instead, or loop over the folders under
  `metadata/tests/load` (with `--load`) and `metadata/tests/transform` (with
  `--transform`). Each run rewrites `junit.xml` and empties the `load` and
  `transform` folders it writes to in its report folder, so a loop that keeps the default
  report folder ends with the last run's results only: give each run its own
  `--outputDir`.
- `--table <domain>.<table>` now fails: pass `--domain <domain> --table <table>`.
- `missing<Name>.csv` and `not_expected<Name>.csv`, the JUnit record counts and
  the record panels of the `--site` pages are swapped back: update any script
  that read one file for the other.

## Related Skills

- [load](../load/SKILL.md) - Load data (tested by load tests)
- [transform](../transform/SKILL.md) - Run transforms (tested by transform tests)
- [expectations](../expectations/SKILL.md) - Declared expectations, the second test oracle
- [validate](../validate/SKILL.md) - Validate project configuration
