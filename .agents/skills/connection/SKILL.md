---
name: connection
description: Create or modify database connection definitions in `application.sl.yml` (BigQuery, Snowflake, DuckDB, DuckLake, PostgreSQL, Redshift, Kafka, Elasticsearch). Use to add or configure a connection; verify it with `starlake settings --test-connection`.
---

# Connection Skill

Creates or modifies database connections in `metadata/application.sl.yml`. Connections define how Starlake connects to data sources and targets (BigQuery, Snowflake, DuckDB, PostgreSQL, Redshift, Databricks, etc.).

## Connection Structure

Connections are defined under `application.connections` in `metadata/application.sl.yml`:

```yaml
version: 1
application:
  connectionRef: "{{activeConnection}}"
  connections:
    <connection_name>:
      type: "<type>"
      sparkFormat: "<format>"   # Optional: Spark data source format
      loader: "<loader>"        # Optional: "native" or "spark"
      options:
        <key>: "<value>"
```

### ConnectionV1 Properties

| Property      | Type   | Description                                        |
|---------------|--------|----------------------------------------------------|
| `type`        | enum   | Connection type (see below)                        |
| `sparkFormat` | string | Spark data source format (e.g., `snowflake`, `jdbc`, `bigquery`, `delta`) |
| `loader`      | string | Processing engine: `native` or `spark`             |
| `quote`       | string | Identifier quoting character (default: `"`)        |
| `separator`   | string | Catalog/schema separator (default: `.`)            |
| `options`     | object | Connection-specific key-value options              |

### Connection Types

| Type     | Description                             |
|----------|-----------------------------------------|
| `FS`     | File System (Databricks/Spark local)    |
| `BQ`     | Google BigQuery                         |
| `JDBC`   | Generic JDBC (Snowflake, DuckDB, PostgreSQL, Redshift, MySQL, etc.) |
| `ES`     | Elasticsearch                           |
| `KAFKA`  | Apache Kafka                            |
| `REST`   | REST API (aliases: `HTTP`, `API`): used with `extract-rest-schema` and `extract-rest-data` |

Starlake auto-detects the specific database engine from the JDBC URL prefix (e.g., `jdbc:snowflake:`, `jdbc:duckdb:`, `jdbc:postgresql:`, `jdbc:redshift:`, `jdbc:mysql:`, `jdbc:mariadb:`). Exception: `jdbc:arrow-flight-sql:` URLs are a transport, not an engine; the engine comes from the `dialect` option (default `duckdb`), see [Arrow Flight SQL (Remote)](#arrow-flight-sql-remote).

---

## Connection Templates by Database

### BigQuery

```yaml
connections:
  bigquery:
    type: "bigquery"
    options:
      location: "europe-west1"        # GCP region
      authType: "APPLICATION_DEFAULT" # or "SERVICE_ACCOUNT_JSON_KEYFILE" or "ACCESS_TOKEN"
      authScopes: "https://www.googleapis.com/auth/cloud-platform"
      writeMethod: "direct"           # "direct" (native) or "indirect" (via GCS staging)
      # For indirect writes (required when using sparkFormat):
      # temporaryGcsBucket: "my-staging-bucket"  # Without gs:// prefix
      # For service account auth:
      # jsonKeyfile: "/path/to/key.json"
      # For access token auth:
      # gcpAccessToken: "{{GCP_TOKEN}}"
```

#### BigQuery with Spark Loader

When using Spark to load data into BigQuery, `writeMethod` must be `indirect` and a GCS bucket is required for staging:

```yaml
connections:
  bigquery:
    type: "bigquery"
    sparkFormat: "bigquery"
    options:
      writeMethod: "indirect"
      location: "europe-west1"
      gcsBucket: "my-staging-bucket"
      authType: "APPLICATION_DEFAULT"
      authScopes: "https://www.googleapis.com/auth/cloud-platform"
```

### Snowflake (Native JDBC)

```yaml
connections:
  snowflake:
    type: "jdbc"
    options:
      url: "jdbc:snowflake://{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com/"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      account: "{{SNOWFLAKE_ACCOUNT}}"
      user: "{{SNOWFLAKE_USER}}"
      password: "{{SNOWFLAKE_PASSWORD}}"
      warehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      db: "{{SNOWFLAKE_DB}}"
      schema: "{{SNOWFLAKE_SCHEMA}}"
      keep_column_case: "off"
      preActions: "ALTER SESSION SET QUERY_TAG = 'starlake';ALTER SESSION SET TIMESTAMP_TYPE_MAPPING = 'TIMESTAMP_LTZ';ALTER SESSION SET QUOTED_IDENTIFIERS_IGNORE_CASE = true"
```

> **Note:** Starlake automatically adds `allowUnderscoresInHost: true` for all Snowflake connections.

OAuth modes (web app, native app, programmatic access token) and the Spark connector template live in [reference/snowflake.md](reference/snowflake.md).

### DuckDB

```yaml
connections:
  duckdb:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:{{SL_ROOT}}/datasets/duckdb.db"
      driver: "org.duckdb.DuckDBDriver"
```

Advanced DuckDB configuration — S3 access (`fs.s3a.*` auto-translation and `preActions` styles), custom home/secret directories, option filtering, and MotherDuck (cloud DuckDB) — lives in [reference/duckdb.md](reference/duckdb.md).

### DuckLake

DuckLake stores catalog metadata in a file or database and data as Parquet in a directory or object store. Starlake detects DuckLake connections by the presence of `ducklake:` in `preActions`; the `url` must be `jdbc:duckdb:` (in-memory — Starlake forces this when it detects DuckLake).

Full templates (local, PostgreSQL catalog + GCS/S3, persistent secrets) and the step-by-step secret setup guide live in [reference/ducklake.md](reference/ducklake.md).

### Quack (DuckDB Remote)

Quack turns one DuckDB instance into a query server: pair it with DuckLake on the server so ODBC/JDBC clients query the lakehouse without holding object-storage credentials or touching Parquet files directly. Starlake detects a Quack client by `'quack:` in `preActions` and a Quack server by the `quackServerToken` option.

Client/server templates (local and PostgreSQL catalogs, multi-bucket SCOPE), the embedded `starlake quack` CLI, and server authentication/authorization hooks live in [reference/quack.md](reference/quack.md). See also the [quack](../quack/SKILL.md) skill for managing servers.


### Arrow Flight SQL (Remote)

Starlake can be a client of any [Arrow Flight SQL](https://arrow.apache.org/docs/format/FlightSql.html) server: a quack-on-demand gateway, GizmoSQL, Dremio, Doris, or any engine fronted by Flight SQL. Primary scenario: a DuckDB/DuckLake lakehouse served over Flight SQL, with the same isolation model as Quack (server owns the catalog and object-storage credentials; the client only speaks SQL).

```yaml
connections:
  qod_bi:
    type: "jdbc"
    options:
      url: "jdbc:arrow-flight-sql://localhost:31338?useEncryption=true&disableCertificateVerification=true&tenant=acme&pool=bi&superuser=true"
      user: "{{FLIGHT_USER}}"
      password: "{{FLIGHT_PASSWORD}}"
      # dialect: duckdb   # optional, duckdb is the default
      # driver: "..."     # optional, defaults to org.apache.arrow.driver.jdbc.ArrowFlightJdbcDriver
```

Key points:

- **URL passthrough**: everything after `host:port` goes to the Arrow driver untouched. `useEncryption` / `disableCertificateVerification` are TLS flags consumed by the driver; parameters like `tenant`, `pool`, `superuser` are forwarded to the server (quack-on-demand routing). Different query strings get distinct connection pools.
- **`dialect` option**: Flight SQL is a transport; `dialect` selects the engine profile (DDL, merge strategies, audit tables, quoting). Defaults to `duckdb`. `mariadb` normalizes to `mysql`, `databricks` to `spark`.
- **Driver**: not bundled; `setup` downloads it when `ENABLE_FLIGHTSQL=true` (default), version pinned with `FLIGHT_SQL_JDBC_VERSION`.
- **Fully remote client**: no client-side `ATTACH 'ducklake:...'`, no local DuckDB session setup (S3 secrets, home_directory); `preActions`/`postActions` still run as session SQL on the remote connection.
- **Loads**: with a duckdb dialect, `read_csv(...)` runs server-side, so load file paths must be visible to the server (object storage or shared filesystem).

### PostgreSQL

```yaml
connections:
  postgresql:
    type: "jdbc"
    options:
      url: "jdbc:postgresql://{{POSTGRES_HOST}}:{{POSTGRES_PORT}}/{{POSTGRES_DATABASE}}"
      driver: "org.postgresql.Driver"
      user: "{{POSTGRES_USER}}"
      password: "{{POSTGRES_PASSWORD}}"
      quoteIdentifiers: false
```

#### PostgreSQL with Spark

```yaml
connections:
  spark-postgres:
    type: "jdbc"
    sparkFormat: "jdbc"
    options:
      url: "jdbc:postgresql://{{POSTGRES_HOST}}:{{POSTGRES_PORT}}/{{POSTGRES_DATABASE}}"
      driver: "org.postgresql.Driver"
      user: "{{POSTGRES_USER}}"
      password: "{{POSTGRES_PASSWORD}}"
      quoteIdentifiers: false
```

### MySQL / MariaDB

Starlake detects MySQL/MariaDB from the JDBC URL prefix (`jdbc:mysql:` or `jdbc:mariadb:`) and uses catalog-based schema resolution instead of schema-based (MySQL uses catalogs where other databases use schemas).

```yaml
connections:
  mysql:
    type: "jdbc"
    options:
      url: "jdbc:mysql://{{MYSQL_HOST}}:{{MYSQL_PORT}}/{{MYSQL_DATABASE}}"
      driver: "com.mysql.cj.jdbc.Driver"
      user: "{{MYSQL_USER}}"
      password: "{{MYSQL_PASSWORD}}"
```

### Amazon Redshift (Native)

```yaml
connections:
  redshift:
    type: "jdbc"
    loader: "native"
    options:
      url: "jdbc:redshift://{{REDSHIFT_HOST}}:{{REDSHIFT_PORT}}/{{REDSHIFT_DATABASE}}"
      driver: "com.amazon.redshift.jdbc42.Driver"
      user: "{{REDSHIFT_USER}}"
      password: "{{REDSHIFT_PASSWORD}}"
      quoteIdentifiers: false
```

#### Redshift with Spark

```yaml
connections:
  redshift_spark:
    type: "jdbc"
    sparkFormat: "io.github.spark_redshift_community.spark.redshift"
    options:
      url: "jdbc:redshift://{{REDSHIFT_HOST}}:{{REDSHIFT_PORT}}/{{REDSHIFT_DATABASE}}"
      driver: "com.amazon.redshift.Driver"
      user: "{{REDSHIFT_USER}}"
      password: "{{REDSHIFT_PASSWORD}}"
      quoteIdentifiers: false
      tempdir: "s3a://{{S3_BUCKET}}/data"
      aws_iam_role: "{{REDSHIFT_ROLE}}"
```

### Databricks

```yaml
connections:
  databricks:
    type: "databricks"
    sparkFormat: "delta"
```

### Apache Spark (Local) / File System

```yaml
connections:
  spark_local:
    type: "fs"
```

---

## Common Options Reference

| Option             | Applies To      | Description                                              |
|--------------------|-----------------|----------------------------------------------------------|
| `url`              | JDBC types      | JDBC connection URL (required for JDBC)                  |
| `driver`           | JDBC types      | JDBC driver class name (required for JDBC)               |
| `user`             | JDBC types      | Database username                                        |
| `password`         | JDBC types      | Database password                                        |
| `preActions`       | All             | SQL statements to run before each operation (semicolon-separated) |
| `postActions`      | All             | SQL statements to run after each operation (semicolon-separated)  |
| `quoteIdentifiers` | JDBC types     | Whether to quote identifiers (default: true)             |
| `writeMethod`      | BigQuery        | `direct` or `indirect`                                   |
| `location`         | BigQuery        | GCP region (e.g., `europe-west1`, `US`)                  |
| `authType`         | BigQuery        | Authentication method: `APPLICATION_DEFAULT`, `SERVICE_ACCOUNT_JSON_KEYFILE`, `ACCESS_TOKEN` |
| `keep_column_case` | Snowflake       | Case sensitivity for column names: `on` or `off`         |
| `authenticator`    | Snowflake       | Auth mode: `oauth`, `programmatic_access_token`, `user/password` |
| `sl_access_token`  | Snowflake OAuth | OAuth access token (internal, not passed to JDBC driver) |
| `SL_APP_TYPE`      | Snowflake       | Set to `snowflake_native_app` for native app mode        |
| `SL_DUCKDB_HOME`   | DuckDB          | Custom DuckDB home directory (for extensions)            |
| `SL_DUCKDB_SECRET_HOME` | DuckDB    | Custom DuckDB secret storage directory                   |
| `SL_DATA_PATH`     | DuckLake        | DuckLake data path (can be local or cloud storage)       |
| `fs.s3a.endpoint`  | DuckDB          | S3 endpoint (auto-translated to DuckDB S3 settings)      |
| `fs.s3a.endpoint.region` | DuckDB   | S3 region (auto-translated to `s3_region`)               |
| `fs.s3a.access.key` | DuckDB        | S3 access key (auto-translated to `s3_access_key_id`)    |
| `fs.s3a.secret.key` | DuckDB        | S3 secret key (auto-translated to `s3_secret_access_key`) |
| `quackServerToken` | Quack server    | Token clients must present to connect; presence flags the connection as a Quack server |
| `quackBind`        | Quack server    | Bind address for the embedded Quack server (default `127.0.0.1`) |
| `quackPort`        | Quack server    | Bind port for the embedded Quack server (default `9494`) |

### BigQuery Storage Options

| Option                 | Description                                    |
|------------------------|------------------------------------------------|
| `gcsBucket`            | GCS bucket for indirect writes                 |
| `temporaryGcsBucket`   | Temporary GCS bucket (without `gs://` prefix)  |
| `jsonKeyfile`          | Path to service account JSON key file          |
| `clientId`             | OAuth client ID                                |
| `clientSecret`         | OAuth client secret                            |
| `refreshToken`         | OAuth refresh token                            |

### Azure Storage Options

| Option                    | Description                 |
|---------------------------|-----------------------------|
| `azureStorageContainer`   | Azure storage container     |
| `azureStorageAccount`     | Azure storage account name  |
| `azureStorageKey`         | Azure storage access key    |

---

## Connection Pooling

Starlake uses different connection pooling strategies depending on the database:

- **DuckDB**: Single-connection pool per database file (DuckDB is single-writer). Connections are duplicated for concurrent reads. Idle connections are cleaned up after 15 seconds.
- **Other JDBC**: HikariCP connection pool when `SL_USE_CONNECTION_POOLING=true` environment variable is set.
- **DuckLake**: Connections are pooled by their `ATTACH` statement to reuse the same DuckLake attachment.
- **Quack**: Connections are pooled by their `ATTACH 'quack:...'` line so two client connections targeting the same server share an attachment.

---

## Environment Variable Patterns

Always use variable substitution for sensitive values and environment-specific settings:

```yaml
# In metadata/env.sl.yml
env:
  activeConnection: "duckdb"
  POSTGRES_HOST: "localhost"
  POSTGRES_PORT: "5432"

# In metadata/env.PROD.sl.yml (production overrides)
env:
  activeConnection: "bigquery"
  POSTGRES_HOST: "${POSTGRES_HOST}"  # From system environment
```

Reference connections dynamically:

```yaml
application:
  connectionRef: "{{activeConnection}}"
```

---

## Multi-Database Projects

Projects often define multiple connections for different use cases:

```yaml
connections:
  # Local development
  duckdb:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:{{SL_ROOT}}/datasets/duckdb.db"
      driver: "org.duckdb.DuckDBDriver"

  # Cloud warehouse
  bigquery:
    type: "bigquery"
    options:
      location: "europe-west1"
      authType: "APPLICATION_DEFAULT"
      authScopes: "https://www.googleapis.com/auth/cloud-platform"
      writeMethod: "direct"

  # Source database for extraction
  postgresql:
    type: "jdbc"
    options:
      url: "jdbc:postgresql://{{POSTGRES_HOST}}:{{POSTGRES_PORT}}/{{POSTGRES_DATABASE}}"
      driver: "org.postgresql.Driver"
      user: "{{POSTGRES_USER}}"
      password: "{{POSTGRES_PASSWORD}}"
      quoteIdentifiers: false
```

Switch between connections per environment using `env.sl.yml`:

```yaml
# env.sl.yml (dev)
env:
  activeConnection: "duckdb"

# env.PROD.sl.yml (production)
env:
  activeConnection: "bigquery"
```

---

## Testing Connections

Verify a connection is properly configured:

```bash
starlake settings --test-connection <connection_name>
```

Example:

```bash
starlake settings --test-connection duckdb
starlake settings --test-connection bigquery
starlake settings --test-connection snowflake
```

---

## Related Skills

- [config](../config/SKILL.md): Application configuration reference
- [settings](../settings/SKILL.md): Print settings and test connections
- [bootstrap](../bootstrap/SKILL.md): Create a new project from a template
- [extract-schema](../extract-schema/SKILL.md): Extract schema from a database connection
- [extract-data](../extract-data/SKILL.md): Extract data from a database connection