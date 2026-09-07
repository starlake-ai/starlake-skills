# DuckLake Connection Reference

DuckLake connection templates and the secret setup guide for `metadata/application.sl.yml`. Overview in [../SKILL.md](../SKILL.md).

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
