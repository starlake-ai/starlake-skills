---
name: settings
description: Print resolved project settings or test an existing connection with `starlake settings --test-connection <name>`. Use to debug configuration or check that a BigQuery, Snowflake, DuckDB, or PostgreSQL connection works; use connection to define one.
---

# Settings Skill

Displays the resolved project settings or tests a specific database connection. Useful for debugging configuration issues and verifying that connections are properly configured.

## Usage

```bash
starlake settings [options]
```

## Options

- `--test-connection <value>`: Test this connection by name (must be defined in `application.sl.yml`)
- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`

## Examples

### Print All Settings

```bash
starlake settings
```

### Test a Database Connection

```bash
starlake settings --test-connection duckdb
```

### Test a PostgreSQL Connection

```bash
starlake settings --test-connection source_postgres
```

### Test BigQuery Connection

```bash
starlake settings --test-connection bigquery
```

### Test Snowflake Connection

```bash
starlake settings --test-connection snowflake
```

## Connection Types Reference

Connection templates for every supported database (BigQuery, Snowflake, Redshift, PostgreSQL, DuckDB, DuckLake, Quack, Spark/FS...) live in the [connection](../connection/SKILL.md) skill. Define or fix the connection there, then verify it here with `starlake settings --test-connection <name>`.

## Related Skills

- [connection](../connection/SKILL.md) - Create or modify connection definitions
- [validate](../validate/SKILL.md) - Validate full project configuration
- [config](../config/SKILL.md) - Configuration reference (environment variables, application structure)
