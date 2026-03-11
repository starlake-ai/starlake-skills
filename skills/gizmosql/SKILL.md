---
name: gizmosql
description: Manage GizmoSQL processes — start, stop, list, and stop-all DuckLake-backed SQL servers
---

# GizmoSQL Skill

Manages GizmoSQL processes that expose DuckLake databases as PostgreSQL-compatible SQL endpoints. Each process runs as a Docker container and connects to a DuckLake catalog backed by PostgreSQL.

## Usage

```bash
starlake gizmo <action> [options]
```

## Actions

| Action     | Description                                |
|------------|--------------------------------------------|
| `start`    | Start a new GizmoSQL process               |
| `stop`     | Stop a specific process by name            |
| `list`     | List all running GizmoSQL processes        |
| `stop-all` | Stop all running GizmoSQL processes        |

## Options

- `action` (required): Action to perform — `start`, `stop`, `list`, `stop-all`
- `--connection <value>`: Connection name (required for `start`). Must reference a DuckLake connection
- `--process-name <value>`: Process name (required for `stop`)
- `--port <value>`: Port for the GizmoSQL process (optional, for `start`). Overrides the `SL_DUCKDB_PORT` connection option
- `--reportFormat <value>`: Report output format — `console`, `json`, or `html`

## Configuration Context

### GizmoSQL Server Settings

The GizmoSQL server URL and API key are configured in `application.sl.yml`:

```yaml
version: 1
application:
  gizmo:
    url: "http://localhost:8080"
    apiKey: "your-api-key"
```

### DuckLake Connection Requirements

The `start` action requires a DuckLake connection. The connection must have `preActions` containing a `'ducklake:` reference and a `USE` command to identify the database.

```yaml
version: 1
application:
  connections:
    my-ducklake:
      type: "jdbc"
      options:
        url: "jdbc:duckdb::memory:"
        driver: "org.duckdb.DuckDBDriver"
        preActions: "INSTALL ducklake FROM community; LOAD ducklake; ATTACH 'ducklake:postgres:mydb' AS mydb (DATA_PATH 'ducklake_files/mydb'); USE mydb"
        PG_HOST: "localhost"
        PG_PORT: "5432"
        PG_USERNAME: "postgres"
        PG_PASSWORD: "secret"
        SL_DUCKDB_PORT: "5433"
        SL_DATA_PATH: "ducklake_files/mydb"
```

### Connection Options for Start

The following connection options are read when starting a GizmoSQL process:

| Option            | Description                                      | Default                      |
|-------------------|--------------------------------------------------|------------------------------|
| `preActions`      | Must contain `'ducklake:` and a `USE <db>` command | (required)                  |
| `PG_HOST`         | PostgreSQL catalog host                          | `localhost`                  |
| `PG_PORT`         | PostgreSQL catalog port                          | `5432`                       |
| `PG_USERNAME`     | PostgreSQL catalog username                      | (empty)                      |
| `PG_PASSWORD`     | PostgreSQL catalog password                      | (empty)                      |
| `SL_DUCKDB_PORT`  | Default port for the GizmoSQL process            | (none)                       |
| `SL_DATA_PATH`    | Data file storage path                           | `ducklake_files/<db_name>`   |
| `storageType`     | Storage backend: `local`, `gcs`, or `s3`         | `local`                      |

### Cloud Storage Options (S3/GCS)

When `storageType` is `gcs` or `s3`, additional options are read from the connection:

| Option                     | Environment Variable | Description               |
|----------------------------|----------------------|---------------------------|
| `fs.s3a.access.key`       | `AWS_KEY_ID`         | AWS access key ID         |
| `fs.s3a.secret.key`       | `AWS_SECRET`         | AWS secret access key     |
| `fs.s3a.endpoint.region`  | `AWS_REGION`         | AWS region                |
| `fs.s3a.endpoint`         | `AWS_ENDPOINT`       | S3-compatible endpoint    |

## Examples

### Start a GizmoSQL Process

```bash
starlake gizmo start --connection my-ducklake
```

### Start on a Specific Port

```bash
starlake gizmo start --connection my-ducklake --port 5433
```

### List Running GizmoSQL Processes

```bash
starlake gizmo list
```

Output columns: `processName`, `port`, `pid`, `status`

### Stop a Specific GizmoSQL Process

```bash
starlake gizmo stop --process-name my-ducklake
```

### Stop All GizmoSQL Processes

```bash
starlake gizmo stop-all
```

## Related Skills

- [connection](../connection/SKILL.md) — Database connection configuration
- [settings](../settings/SKILL.md) — Print settings and test connections
- [config](../config/SKILL.md) — Configuration reference
