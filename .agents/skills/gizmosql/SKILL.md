---
name: gizmosql
description: Manage GizmoSQL processes — start, stop, list, and stop-all DuckLake-backed SQL servers
---

# GizmoSQL Skill

Manages GizmoSQL processes that expose DuckLake databases as PostgreSQL-compatible SQL endpoints. Each process runs as a Docker container and connects to a DuckLake catalog backed by PostgreSQL.

## Usage

```bash
starlake gizmosql <action> [options]
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

## Cloud Storage Data Path Examples

### GCS (Google Cloud Storage)

```yaml
version: 1
application:
  connections:
    my-ducklake-gcs:
      type: "jdbc"
      options:
        url: "jdbc:duckdb:"
        driver: "org.duckdb.DuckDBDriver"
        preActions: >
          INSTALL POSTGRES;
          INSTALL ducklake;
          LOAD POSTGRES;
          LOAD ducklake;
          CREATE OR REPLACE SECRET (
              TYPE gcs,
              KEY_ID '{{GCS_HMAC_ACCESS_KEY_ID}}',
              SECRET '{{GCS_HMAC_SECRET_ACCESS_KEY}}'
              SCOPE 'gs://{{GCS_BUCKET}}/');
          ATTACH IF NOT EXISTS 'ducklake:postgres:
                  dbname={{PG_DATABASE}}
                  host={{PG_HOST}}
                  port={{PG_PORT}}
                  user={{PG_USER}}
                  password={{PG_PASSWORD}}' AS my_ducklake
              (DATA_PATH 'gs://{{GCS_BUCKET}}/data_files/');
          USE my_ducklake;
        PG_HOST: "{{PG_HOST}}"
        PG_PORT: "{{PG_PORT}}"
        PG_USERNAME: "{{PG_USER}}"
        PG_PASSWORD: "{{PG_PASSWORD}}"
        SL_DUCKDB_PORT: "5433"
        SL_DATA_PATH: "gs://{{GCS_BUCKET}}/data_files/"
        storageType: "gcs"
        fs.s3a.access.key: "{{GCS_HMAC_ACCESS_KEY_ID}}"
        fs.s3a.secret.key: "{{GCS_HMAC_SECRET_ACCESS_KEY}}"
        fs.s3a.endpoint: "https://storage.googleapis.com"
        fs.s3a.endpoint.region: "auto"
```

> **Note:** GCS uses HMAC keys for S3-compatible access. Generate them in the GCP Console under Cloud Storage > Settings > Interoperability.

### AWS S3

```yaml
version: 1
application:
  connections:
    my-ducklake-s3:
      type: "jdbc"
      options:
        url: "jdbc:duckdb:"
        driver: "org.duckdb.DuckDBDriver"
        preActions: >
          INSTALL POSTGRES;
          INSTALL ducklake;
          LOAD POSTGRES;
          LOAD ducklake;
          CREATE OR REPLACE SECRET (
              TYPE s3,
              KEY_ID '{{AWS_ACCESS_KEY_ID}}',
              SECRET '{{AWS_SECRET_ACCESS_KEY}}',
              REGION '{{AWS_REGION}}'
              SCOPE 's3://{{S3_BUCKET}}/');
          ATTACH IF NOT EXISTS 'ducklake:postgres:
                  dbname={{PG_DATABASE}}
                  host={{PG_HOST}}
                  port={{PG_PORT}}
                  user={{PG_USER}}
                  password={{PG_PASSWORD}}' AS my_ducklake
              (DATA_PATH 's3://{{S3_BUCKET}}/data_files/');
          USE my_ducklake;
        PG_HOST: "{{PG_HOST}}"
        PG_PORT: "{{PG_PORT}}"
        PG_USERNAME: "{{PG_USER}}"
        PG_PASSWORD: "{{PG_PASSWORD}}"
        SL_DUCKDB_PORT: "5433"
        SL_DATA_PATH: "s3://{{S3_BUCKET}}/data_files/"
        storageType: "s3"
        fs.s3a.access.key: "{{AWS_ACCESS_KEY_ID}}"
        fs.s3a.secret.key: "{{AWS_SECRET_ACCESS_KEY}}"
        fs.s3a.endpoint: "https://s3.amazonaws.com"
        fs.s3a.endpoint.region: "{{AWS_REGION}}"
```

### Azure Blob Storage

```yaml
version: 1
application:
  connections:
    my-ducklake-azure:
      type: "jdbc"
      options:
        url: "jdbc:duckdb:"
        driver: "org.duckdb.DuckDBDriver"
        preActions: >
          INSTALL POSTGRES;
          INSTALL ducklake;
          LOAD POSTGRES;
          LOAD ducklake;
          CREATE OR REPLACE SECRET (
              TYPE azure,
              CONNECTION_STRING 'DefaultEndpointsProtocol=https;AccountName={{AZURE_STORAGE_ACCOUNT}};AccountKey={{AZURE_STORAGE_KEY}};EndpointSuffix=core.windows.net'
              SCOPE 'az://{{AZURE_CONTAINER}}/');
          ATTACH IF NOT EXISTS 'ducklake:postgres:
                  dbname={{PG_DATABASE}}
                  host={{PG_HOST}}
                  port={{PG_PORT}}
                  user={{PG_USER}}
                  password={{PG_PASSWORD}}' AS my_ducklake
              (DATA_PATH 'az://{{AZURE_CONTAINER}}/data_files/');
          USE my_ducklake;
        PG_HOST: "{{PG_HOST}}"
        PG_PORT: "{{PG_PORT}}"
        PG_USERNAME: "{{PG_USER}}"
        PG_PASSWORD: "{{PG_PASSWORD}}"
        SL_DUCKDB_PORT: "5433"
        SL_DATA_PATH: "az://{{AZURE_CONTAINER}}/data_files/"
```

> **Note:** Azure uses the `az://` URI scheme for DuckDB. Alternative schemes include `abfss://{{AZURE_CONTAINER}}@{{AZURE_STORAGE_ACCOUNT}}.dfs.core.windows.net/` for ADLS Gen2 access.

## Examples

### Start a GizmoSQL Process

```bash
starlake gizmosql start --connection my-ducklake
```

### Start on a Specific Port

```bash
starlake gizmosql start --connection my-ducklake --port 5433
```

### List Running GizmoSQL Processes

```bash
starlake gizmosql list
```

Output columns: `processName`, `port`, `pid`, `status`

### Stop a Specific GizmoSQL Process

```bash
starlake gizmosql stop --process-name my-ducklake
```

### Stop All GizmoSQL Processes

```bash
starlake gizmosql stop-all
```

## Related Skills

- [connection](../connection/SKILL.md) — Database connection configuration
- [settings](../settings/SKILL.md) — Print settings and test connections
- [config](../config/SKILL.md) — Configuration reference
