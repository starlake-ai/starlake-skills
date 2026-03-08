---
name: connection
description: Create or modify database connections in application.sl.yml
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

Starlake auto-detects the specific database engine from the JDBC URL prefix (e.g., `jdbc:snowflake:`, `jdbc:duckdb:`, `jdbc:postgresql:`, `jdbc:redshift:`, `jdbc:mysql:`, `jdbc:mariadb:`).

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

#### Snowflake with OAuth Authentication

Starlake supports Snowflake OAuth in two modes:

**Web App OAuth** — set `authenticator` to `oauth` and provide `sl_access_token` in the format `account°user°token`:

```yaml
connections:
  snowflake:
    type: "jdbc"
    options:
      url: "jdbc:snowflake://{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com/"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      authenticator: "oauth"
      sl_access_token: "{{SNOWFLAKE_OAUTH_TOKEN}}"
      warehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      db: "{{SNOWFLAKE_DB}}"
      schema: "{{SNOWFLAKE_SCHEMA}}"
      keep_column_case: "off"
```

**Snowflake Native App** — additionally set `SL_APP_TYPE` to `snowflake_native_app`:

```yaml
connections:
  snowflake:
    type: "jdbc"
    options:
      url: "jdbc:snowflake://{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com/"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      authenticator: "oauth"
      sl_access_token: "{{SNOWFLAKE_OAUTH_TOKEN}}"
      SL_APP_TYPE: "snowflake_native_app"
      warehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      db: "{{SNOWFLAKE_DB}}"
      schema: "{{SNOWFLAKE_SCHEMA}}"
```

**Programmatic Access Token** — set `authenticator` to `programmatic_access_token` (Starlake handles this internally and does not pass it to the JDBC driver):

```yaml
connections:
  snowflake:
    type: "jdbc"
    options:
      url: "jdbc:snowflake://{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com/"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      authenticator: "programmatic_access_token"
      user: "{{SNOWFLAKE_USER}}"
      password: "{{SNOWFLAKE_PAT}}"
      warehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      db: "{{SNOWFLAKE_DB}}"
      schema: "{{SNOWFLAKE_SCHEMA}}"
```

> **Note:** Starlake automatically adds `allowUnderscoresInHost: true` for all Snowflake connections.

#### Snowflake with Spark Connector

When using Spark to load data into Snowflake, a separate connection with `sparkFormat: snowflake` and `sf`-prefixed option keys is required:

```yaml
connections:
  spark-snowflake:
    type: "jdbc"
    sparkFormat: "snowflake"
    options:
      sfUrl: "{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      sfAccount: "{{SNOWFLAKE_ACCOUNT}}"
      sfUser: "{{SNOWFLAKE_USER}}"
      sfPassword: "{{SNOWFLAKE_PASSWORD}}"
      sfWarehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      sfDatabase: "{{SNOWFLAKE_DB}}"
      sfSchema: "{{SNOWFLAKE_SCHEMA}}"
      keep_column_case: "off"
      autopushdown: "on"
      preActions: "ALTER SESSION SET QUERY_TAG = 'starlake';ALTER SESSION SET TIMESTAMP_TYPE_MAPPING = 'TIMESTAMP_LTZ';ALTER SESSION SET QUOTED_IDENTIFIERS_IGNORE_CASE = true"
```

### DuckDB

```yaml
connections:
  duckdb:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:{{SL_ROOT}}/datasets/duckdb.db"
      driver: "org.duckdb.DuckDBDriver"
```

#### DuckDB with S3 (using `fs.s3a.*` options)

Starlake automatically translates Hadoop-style `fs.s3a.*` options into DuckDB S3 settings at connection time. This is the preferred approach for DuckDB S3 configuration:

```yaml
connections:
  duckdb:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:{{SL_ROOT}}/datasets/duckdb.db"
      driver: "org.duckdb.DuckDBDriver"
      fs.s3a.endpoint: "https://s3.amazonaws.com"       # Maps to s3_endpoint; auto-detects SSL and URL style
      fs.s3a.endpoint.region: "us-east-1"                # Maps to s3_region
      fs.s3a.access.key: "{{S3_ACCESS_KEY}}"             # Maps to s3_access_key_id
      fs.s3a.secret.key: "{{S3_SECRET_KEY}}"             # Maps to s3_secret_access_key
```

> **Starlake auto-detection from `fs.s3a.endpoint`:**
> - `https://` prefix sets `s3_use_ssl=true`, `http://` sets `s3_use_ssl=false`
> - Endpoints containing `s3.amazonaws.com` use `s3_url_style='vhost'`, all others use `s3_url_style='path'`

#### DuckDB with S3 (using `preActions`)

Alternatively, configure S3 directly via DuckDB SQL in `preActions`:

```yaml
connections:
  duckdb:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:{{SL_ROOT}}/datasets/duckdb.db"
      driver: "org.duckdb.DuckDBDriver"
      preActions: |
        INSTALL httpfs;
        LOAD httpfs;
        SET s3_region='us-east-1';
        SET s3_endpoint='{{S3_ENDPOINT}}';
        SET s3_access_key_id='{{S3_ACCESS_KEY}}';
        SET s3_secret_access_key='{{S3_SECRET_KEY}}';
        SET s3_use_ssl=false;
        SET s3_url_style='path';
```

#### DuckDB Custom Home and Secret Directories

Control where DuckDB stores extensions and secrets. These can be set as connection options or as system environment variables:

```yaml
connections:
  duckdb:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:{{SL_ROOT}}/datasets/duckdb.db"
      driver: "org.duckdb.DuckDBDriver"
      SL_DUCKDB_HOME: "{{SL_ROOT}}/.duckdb"                        # Sets DuckDB home_directory
      SL_DUCKDB_SECRET_HOME: "{{SL_ROOT}}/.duckdb/stored_secrets"   # Sets DuckDB secret_directory
```

> **Fallback chain for `secret_directory`:** `SL_DUCKDB_SECRET_HOME` option, then `SL_DUCKDB_SECRET_HOME` env var, then `SL_DUCKDB_HOME` option, then `SL_DUCKDB_HOME` env var.

#### DuckDB Option Filtering

Starlake automatically filters out the following options before passing them to DuckDB (they are used internally only):

`url`, `driver`, `dbtable`, `numpartitions`, `sl_access_token`, `account`, `allowUnderscoresInHost`, `database`, `db`, `authenticator`, `user`, `password`, `preActions`, `DATA_PATH`, `SL_DATA_PATH`, `storageType`, `quoteIdentifiers`

Additionally, any option starting with `SL_` or `fs.` is filtered out (these are processed by Starlake before being applied).

#### MotherDuck (Cloud DuckDB)

Use the `jdbc:duckdb:md:` URL prefix for MotherDuck cloud connections:

```yaml
connections:
  motherduck:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:md:{{MOTHERDUCK_DATABASE}}"
      driver: "org.duckdb.DuckDBDriver"
```

### DuckLake (Local)

DuckLake stores metadata in a local file and data in a local directory. Starlake detects DuckLake connections by the presence of `ducklake:` in `preActions`:

```yaml
connections:
  ducklake_local:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      preActions: >
        INSTALL ducklake;
        LOAD ducklake;
        ATTACH IF NOT EXISTS 'ducklake:{{DUCKLAKE_METADATA_PATH}}' AS my_ducklake
            (DATA_PATH '{{DUCKLAKE_DATA_PATH}}');
        USE my_ducklake;
```

> **Important:** For DuckLake, the `url` must be `jdbc:duckdb:` (in-memory). Starlake forces this URL when it detects DuckLake in preActions.

#### DuckLake (Cloud with PostgreSQL Catalog + GCS)

```yaml
connections:
  ducklake_cloud:
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
```

#### DuckLake with Persistent Secrets

For DuckLake with persistent DuckDB secrets (recommended for production):

```yaml
connections:
  ducklake:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      SL_DUCKDB_HOME: "{{SL_ROOT}}/.duckdb"
      SL_DUCKDB_SECRET_HOME: "{{SL_ROOT}}/.duckdb/stored_secrets"
      SL_DATA_PATH: "{{SL_ROOT}}/ducklake_data/{{SL_DB_ID}}"
      preActions: "ATTACH IF NOT EXISTS 'ducklake:{{SL_DB_ID}}' AS {{SL_DB_ID}}; USE {{SL_DB_ID}};"
```

> **Note:** Persistent secrets must be created beforehand in the directory specified by `SL_DUCKDB_SECRET_HOME` (or `SL_DUCKDB_HOME` as fallback). Starlake automatically sets DuckDB's `secret_directory` to this path at connection time, so secrets stored there are loaded on every connection.
>
> You can use any custom directory for storing secrets — just make sure the same path is set both when creating the secrets and in the connection options. For example, to use `/my/custom/secrets`:
>
> 1. **In your connection options**, set `SL_DUCKDB_SECRET_HOME` to your custom directory:
>    ```yaml
>    SL_DUCKDB_SECRET_HOME: "/my/custom/secrets"
>    ```
>
> 2. **When creating the secrets**, set the same `secret_directory` so DuckDB writes them to the correct location:
>    ```sql
>    SET secret_directory='/my/custom/secrets';
>
>    CREATE OR REPLACE PERSISTENT SECRET pg_<SL_DB_ID>
>        (TYPE postgres, HOST '<host>', PORT <port>, DATABASE <db>, USER '<user>', PASSWORD '<pwd>');
>    CREATE OR REPLACE PERSISTENT SECRET <SL_DB_ID>
>        (TYPE ducklake, METADATA_PATH '', DATA_PATH '<path>',
>         METADATA_PARAMETERS MAP {'TYPE': 'postgres', 'SECRET': 'pg_<SL_DB_ID>'});
>    ```
>
> If `SL_DUCKDB_SECRET_HOME` is not set, Starlake falls back to `SL_DUCKDB_HOME`, then to the `SL_DUCKDB_SECRET_HOME` environment variable, then to the `SL_DUCKDB_HOME` environment variable.

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

- [config](../config/SKILL.md) — Application configuration reference
- [settings](../settings/SKILL.md) — Print settings and test connections
- [bootstrap](../bootstrap/SKILL.md) — Create a new project from a template
- [extract-schema](../extract-schema/SKILL.md) — Extract schema from a database connection
- [extract-data](../extract-data/SKILL.md) — Extract data from a database connection