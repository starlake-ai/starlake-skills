---
name: impact
description: Report what a change of a Starlake project touches with `starlake impact`, before anything runs. Lists the load tables and transforms that changed (BREAKING, NON_BREAKING, ADDED, METADATA) and the downstream tasks they impact through column-level lineage. Offline, read-only, CI friendly (--fail-on, Markdown for PR comments).
---

# Impact Skill

Compares two versions of a Starlake project and reports, without running anything, what the change touches:

- **Direct changes**: each changed load table or transform, classified `BREAKING`, `NON_BREAKING`, `ADDED` or `METADATA`, with per-column details (column added, removed, renamed, expression or type changed).
- **Impacted downstream**: the tasks that read a changed column, found through the column-level lineage of their SQL (CTEs, subqueries and casts included), with the path that reached them. Consumers that still mention a removed column, or read a deleted table, are flagged as likely failures.
- **Unresolved**: every place the analysis fell back to table level (SQL that does not parse, Python tasks, unknown columns, ambiguous names), so reviewers know where the report is less precise.
- **Other changes, not traced**: changed files that are listed but not followed downstream (DAGs, connections, env files, fields the analysis does not classify).

No connection is opened, nothing is executed, and the project is never written.

## Usage

```bash
starlake impact [options]
```

## Options

### Which versions to compare
- `--base <ref>`: git ref of the old side; the merge-base of `<ref>` with the new side is used
- `--head <ref>`: git ref of the new side (default: the current project directory as is, uncommitted edits included)
- `--path1 <dir>`: old project directory, instead of `--base`
- `--path2 <dir>`: new project directory, instead of the current project or `--head`

`--path1` / `--path2` cannot be combined with `--base` / `--head`.

### Rendering
- `--env <name>`: env used to render the SQL variables
- `--format <value>`: `text` (default), `json`, `markdown`, `html` or `plan` (what `transform --impacted` runs)
- `starlake transform --impacted --base <ref>` runs the `run` entries of the plan.
- `--output <file>`: write the report to this local file instead of stdout (recommended in CI)
- `--template <file>`: Jinja template replacing the built-in HTML one; the values it receives are already HTML-escaped

### Failing a CI step
- `--fail-on breaking`: exit 1 when a direct change or an impacted task is `BREAKING`
- `--fail-on non-breaking`: exit 1 on any change other than `METADATA`

Exit codes: `0` report written, `1` `--fail-on` matched, `2` usage, git or project loading error (no report).

## How changes are classified

| Change | Class | Downstream effect |
|---|---|---|
| Comment, tags, ACL / RLS, expectations only | `METADATA` | None |
| New output column or attribute | `NON_BREAKING` | Only `SELECT *` consumers |
| Column expression, type, script, privacy or default changed | `BREAKING` for that column | Tasks reading that column, recursively |
| Column removed or renamed | `BREAKING` for that column | Same, and consumers still mentioning it are likely failures |
| WHERE / JOIN / GROUP BY / DISTINCT, source table, write strategy, merge key, partition, `required`, presql / postsql, parsing settings | `BREAKING` for all columns | Every downstream task |
| SQL that does not parse, Python task | `BREAKING` (unresolved) | Table level, listed in Unresolved |
| Task or table added | `ADDED` | None |
| Task or table deleted | `BREAKING` | Every consumer, as likely failures |

When in doubt the analysis over-reports rather than missing an impact.

## Examples

### Review the current branch against main

```bash
starlake impact --base origin/main
```

### Gate a pull request in CI

```bash
starlake impact --base origin/main --format markdown --output impact.md --fail-on breaking
```

Post `impact.md` as a PR comment (for example `gh pr comment --body-file impact.md`), in a step that runs even when the impact step exits 1.

### Compare two commits

```bash
starlake impact --base v1.2.0 --head feature/new-kpis
```

### Compare two directories

```bash
starlake impact --path1 /tmp/project-before --path2 /tmp/project-after --format json --output impact.json
```

## Tips

- Run it from the project root (the folder that contains `metadata/`), inside the git repository for `--base` / `--head`.
- In CI, fetch enough history for the merge-base (for example `fetch-depth: 0` with `actions/checkout`).
- Declare the `attributes` of tasks whose SQL uses `SELECT *` over external tables: the analysis is offline, so unknown columns make the edge table level.

## Related Skills

- [compare](../compare/SKILL.md) - Structural diff of two project versions
- [col-lineage](../col-lineage/SKILL.md) - Column-level lineage of one task
- [lineage](../lineage/SKILL.md) - Task dependency graph
- [validate](../validate/SKILL.md) - Validate project configuration
