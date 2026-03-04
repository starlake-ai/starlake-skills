---
name: settings
description: Print project settings or test a database connection
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

### BigQuery

```yaml
connections:
  bigquery:
    type: "bigquery"
    sparkFormat: "bigquery" # Optional: use Spark connector
    options:
      location: "europe-west1" # or "us-central1"
      authType: "APPLICATION_DEFAULT" # Most common
      # authType: "SERVICE_ACCOUNT_JSON_KEYFILE"  # For service accounts
      # jsonKeyfile: "/path/to/key.json"
      # authType: "ACCESS_TOKEN"  # For short-lived tokens
      # gcpAccessToken: "TOKEN"
      authScopes: "https://www.googleapis.com/auth/cloud-platform"
      writeMethod: "direct" # or "indirect" (required with sparkFormat)
      temporaryGcsBucket: "bucket_name" # Without gs:// prefix
```

### Snowflake

```yaml
connections:
  snowflake:
    type: jdbc
    sparkFormat: snowflake # Optional: for Spark operations
    options:
      url: "jdbc:snowflake://{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      user: "{{SNOWFLAKE_USER}}"
      password: "{{SNOWFLAKE_PASSWORD}}"
      warehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      db: "{{SNOWFLAKE_DB}}"
      keep_column_case: "off"
      preActions: "ALTER SESSION SET TIMESTAMP_TYPE_MAPPING = 'TIMESTAMP_LTZ'; ALTER SESSION SET QUOTED_IDENTIFIERS_IGNORE_CASE = true"

      # With sparkFormat, use sf-prefixed keys:
      # sfUrl: "{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com"
      # sfUser: "{{SNOWFLAKE_USER}}"
      # sfPassword: "{{SNOWFLAKE_PASSWORD}}"
      # sfWarehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      # sfDatabase: "{{SNOWFLAKE_DB}}"
```

### Amazon Redshift

```yaml
connections:
  redshift:
    type: jdbc
    sparkFormat: "io.github.spark_redshift_community.spark.redshift"
    # On Databricks: sparkFormat: "redshift"
    options:
      url: "jdbc:redshift://account.region.redshift.amazonaws.com:5439/database"
      driver: com.amazon.redshift.Driver
      user: "{{REDSHIFT_USER}}"
      password: "{{REDSHIFT_PASSWORD}}"
      tempdir: "s3a://bucketName/data"
      tempdir_region: "eu-central-1" # Required outside AWS
      aws_iam_role: "arn:aws:iam::aws_count_id:role/role_name"
```

### PostgreSQL

```yaml
connections:
  postgresql:
    type: jdbc
    sparkFormat: jdbc # Optional: for Spark operations
    options:
      url: "jdbc:postgresql://{{POSTGRES_HOST}}:{{POSTGRES_PORT}}/{{POSTGRES_DATABASE}}"
      driver: "org.postgresql.Driver"
      user: "{{DATABASE_USER}}"
      password: "{{DATABASE_PASSWORD}}"
      quoteIdentifiers: false
```

### DuckDB

```yaml
connections:
  duckdb:
    type: jdbc
    options:
      url: "jdbc:duckdb:{{DUCKDB_PATH}}"
      driver: "org.duckdb.DuckDBDriver"
      user: "{{DATABASE_USER}}"
      password: "{{DATABASE_PASSWORD}}"
      # DuckDB S3 extension
      s3_endpoint: "{{S3_ENDPOINT}}"
      s3_access_key_id: "{{S3_ACCESS_KEY}}"
      s3_secret_access_key: "{{S3_SECRET_KEY}}"
      s3_use_ssl: "false"
      s3_url_style: "path"
      s3_region: "us-east-1"
      # DuckDB custom home directory
      # SL_DUCKDB_HOME: "{{SL_ROOT}}/.duckdb"

      # DuckDB SECRET custom home directory
      # SL_DUCKDB_SECRET_HOME: "{{SL_ROOT}}/.duckdb/stored_secrets"
```

### DuckLake

```yaml
connections:
  duckdb:
    type: jdbc
    options:
      url: "jdbc:duckdb:{{DUCKDB_PATH}}"
      driver: "org.duckdb.DuckDBDriver"
      user: "{{DATABASE_USER}}"
      password: "{{DATABASE_PASSWORD}}"

      # DuckLake (DuckDB metadata store on PostgreSQL)
      # The user should have first the postgres database
      # The user should have also created the secrets with the following SQL commands in DuckDB:
      # CREATE OR REPLACE PERSISTENT SECRET pg_{{SL_DB_ID}}
      #     (TYPE postgres, HOST '{{PG_HOST}}',PORT {{PG_PORT}}, DATABASE {{SL_DB_ID}}, USER '{{PG_USERNAME}}',PASSWORD '{{PG_PASSWORD}}')
      # CREATE OR REPLACE PERSISTENT SECRET {{SL_DB_ID}}
      #     (TYPE ducklake, METADATA_PATH '',DATA_PATH '{{SL_DATA_PATH}}', METADATA_PARAMETERS MAP {'TYPE': 'postgres', 'SECRET': 'pg_{{SL_DB_ID}}'});

      preActions: "ATTACH IF NOT EXISTS 'ducklake:{{SL_DB_ID}}' AS {{SL_DB_ID}}; USE {{SL_DB_ID}};"

      # DuckDB S3 extension if SL_DATA_PATH is on S3
      s3_endpoint: "{{S3_ENDPOINT}}"
      s3_access_key_id: "{{S3_ACCESS_KEY}}"
      s3_secret_access_key: "{{S3_SECRET_KEY}}"
      s3_use_ssl: "false"
      s3_url_style: "path"
      s3_region: "us-east-1"

      SL_DATA_PATH: "{{SL_ROOT}}/ducklake_data/{{SL_DB_ID}}" # DuckLake data path (can be on S3 or local)

      # DuckDB custom home directory
      # SL_DUCKDB_HOME: "{{SL_ROOT}}/.duckdb"

      # DuckDB SECRET custom home directory
      # SL_DUCKDB_SECRET_HOME: "{{SL_ROOT}}/.duckdb/stored_secrets"
```

### Apache Spark (Local/Databricks)

```yaml
connections:
  spark:
    type: "spark"
    options: {} # Any spark.* config can go in application.spark section
```

### Local Filesystem

```yaml
connections:
  local:
    type: local
```

## Related Skills

- [validate](../validate/SKILL.md) - Validate full project configuration
- [config](../config/SKILL.md) - Configuration reference (environment variables, application structure)
