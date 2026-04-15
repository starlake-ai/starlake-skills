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

MotherDuck requires the `MOTHERDUCK_TOKEN` environment variable to be set for authentication. Use the `jdbc:duckdb:md:` URL prefix:

```yaml
connections:
  motherduck:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:md:{{MOTHERDUCK_DATABASE}}"
      driver: "org.duckdb.DuckDBDriver"
```

> **Authentication:** Set the `MOTHERDUCK_TOKEN` environment variable before running Starlake. Obtain your token from the [MotherDuck UI](https://app.motherduck.com/) under Settings > Access Tokens.
>
> ```bash
> export MOTHERDUCK_TOKEN="your_token_here"
> ```
>
> You can also define it in `env.sl.yml`:
> ```yaml
> env:
>   MOTHERDUCK_TOKEN: "${MOTHERDUCK_TOKEN}"  # From system environment
>   MOTHERDUCK_DATABASE: "my_database"
> ```

#### MotherDuck with Shared Database

To attach to a shared MotherDuck database:

```yaml
connections:
  motherduck:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:md:{{MOTHERDUCK_DATABASE}}"
      driver: "org.duckdb.DuckDBDriver"
      preActions: "ATTACH '{{MOTHERDUCK_SHARED_DB}}' AS shared_db;"
```

#### MotherDuck with Local Hybrid

MotherDuck supports a hybrid mode where queries can span both local and cloud data. Use a local DuckDB file with MotherDuck attached:

```yaml
connections:
  motherduck_hybrid:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:md:{{MOTHERDUCK_DATABASE}}?motherduck_attach_mode=single"
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

> **Important:** Persistent secrets **must be created before** using this connection. Starlake automatically sets DuckDB's `secret_directory` to `SL_DUCKDB_SECRET_HOME` at connection time (falling back to `SL_DUCKDB_HOME` if `SL_DUCKDB_SECRET_HOME` is not defined), so secrets stored there are loaded on every connection.

#### DuckLake Secret Setup Guide

When setting up a DuckLake connection with persistent secrets, **always verify that the required secrets exist** before proceeding. If they don't, guide the user through creating them.

##### Step 1: Check if secrets exist

Look for secret files in the configured secret directory:

```bash
# Use SL_DUCKDB_SECRET_HOME if defined, otherwise SL_DUCKDB_HOME
ls -la <SL_DUCKDB_SECRET_HOME or SL_DUCKDB_HOME>/
```

If the directory is empty or missing, secrets need to be created.

##### Step 2: Determine which secrets are needed

DuckLake requires different secrets depending on the storage backend:

| Backend | Required Secrets |
|---------|-----------------|
| **Local filesystem** | A `ducklake` secret with local `DATA_PATH` |
| **PostgreSQL catalog + local data** | A `postgres` secret + a `ducklake` secret referencing it |
| **PostgreSQL catalog + GCS data** | A `gcs` secret + a `postgres` secret + a `ducklake` secret |
| **PostgreSQL catalog + S3 data** | An `s3` secret + a `postgres` secret + a `ducklake` secret |

##### Step 3: Create the secrets

Run the following in a DuckDB session, replacing placeholders with the user's actual values. The `secret_directory` **must match** `SL_DUCKDB_SECRET_HOME` (or `SL_DUCKDB_HOME` if `SL_DUCKDB_SECRET_HOME` is not defined) in the connection config.

**PostgreSQL catalog + GCS storage:**

```sql
INSTALL ducklake;
LOAD ducklake;
INSTALL postgres;
LOAD postgres;

SET secret_directory='<SL_DUCKDB_SECRET_HOME or SL_DUCKDB_HOME>';

-- 1. Cloud storage secret (GCS example)
CREATE OR REPLACE PERSISTENT SECRET gcs_<SL_DB_ID> (
    TYPE gcs,
    KEY_ID '<GCS_HMAC_ACCESS_KEY_ID>',
    SECRET '<GCS_HMAC_SECRET_ACCESS_KEY>'
);

-- 2. PostgreSQL catalog secret
CREATE OR REPLACE PERSISTENT SECRET pg_<SL_DB_ID> (
    TYPE postgres,
    HOST '<PG_HOST>',
    PORT <PG_PORT>,
    DATABASE '<PG_DATABASE>',
    USER '<PG_USER>',
    PASSWORD '<PG_PASSWORD>'
);

-- 3. DuckLake secret tying it all together
CREATE OR REPLACE PERSISTENT SECRET <SL_DB_ID> (
    TYPE ducklake,
    METADATA_PATH '',
    DATA_PATH 'gs://<GCS_BUCKET>/data_files/',
    METADATA_PARAMETERS MAP {
        'TYPE': 'postgres',
        'SECRET': 'pg_<SL_DB_ID>'
    }
);
```

**PostgreSQL catalog + S3 storage:**

```sql
SET secret_directory='<SL_DUCKDB_SECRET_HOME or SL_DUCKDB_HOME>';

-- 1. S3 storage secret
CREATE OR REPLACE PERSISTENT SECRET s3_<SL_DB_ID> (
    TYPE s3,
    KEY_ID '<S3_ACCESS_KEY_ID>',
    SECRET '<S3_SECRET_ACCESS_KEY>',
    REGION '<S3_REGION>',
    ENDPOINT '<S3_ENDPOINT>'
);

-- 2. PostgreSQL catalog secret
CREATE OR REPLACE PERSISTENT SECRET pg_<SL_DB_ID> (
    TYPE postgres,
    HOST '<PG_HOST>',
    PORT <PG_PORT>,
    DATABASE '<PG_DATABASE>',
    USER '<PG_USER>',
    PASSWORD '<PG_PASSWORD>'
);

-- 3. DuckLake secret
CREATE OR REPLACE PERSISTENT SECRET <SL_DB_ID> (
    TYPE ducklake,
    METADATA_PATH '',
    DATA_PATH 's3://<S3_BUCKET>/data_files/',
    METADATA_PARAMETERS MAP {
        'TYPE': 'postgres',
        'SECRET': 'pg_<SL_DB_ID>'
    }
);
```

**Local metadata + local data (no cloud secrets needed):**

```sql
SET secret_directory='<SL_DUCKDB_SECRET_HOME or SL_DUCKDB_HOME>';

CREATE OR REPLACE PERSISTENT SECRET <SL_DB_ID> (
    TYPE ducklake,
    METADATA_PATH '<DUCKLAKE_METADATA_PATH>',
    DATA_PATH '<DUCKLAKE_DATA_PATH>'
);
```

##### Step 4: Verify secrets were created

```bash
ls -la <SL_DUCKDB_SECRET_HOME or SL_DUCKDB_HOME>/
```

You should see `.duckdb_secret` files for each secret created.

> **Fallback chain for `secret_directory`:** `SL_DUCKDB_SECRET_HOME` option → `SL_DUCKDB_HOME` option → `SL_DUCKDB_SECRET_HOME` env var → `SL_DUCKDB_HOME` env var.

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