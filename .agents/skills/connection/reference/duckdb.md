# DuckDB Connection Reference

Advanced DuckDB connection configuration for `metadata/application.sl.yml`: S3 access, custom home/secret directories, option filtering, and MotherDuck (cloud DuckDB). The basic template is in [../SKILL.md](../SKILL.md).

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

`url`, `driver`, `dbtable`, `numpartitions`, `sl_access_token`, `account`, `allowUnderscoresInHost`, `database`, `db`, `authenticator`, `user`, `password`, `preActions`, `postActions`, `DATA_PATH`, `SL_DATA_PATH`, `storageType`, `quoteIdentifiers`, `quote`, `separator`, `quackServerToken`, `quackBind`, `quackPort`

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
