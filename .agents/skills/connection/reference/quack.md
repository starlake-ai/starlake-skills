# Quack Connection Reference

Quack client/server connection templates, the embedded CLI, and server authentication/authorization hooks. Overview in [../SKILL.md](../SKILL.md); server lifecycle commands in the `quack` skill.

### Quack (DuckDB Remote)

[Quack](https://duckdb.org/docs/extensions/quack) is a DuckDB extension that turns one DuckDB instance into a query server. Pair it with DuckLake on the server to let ODBC/JDBC clients query a lakehouse **without ever holding object-storage credentials or touching Parquet files directly**.

Starlake detects Quack connections automatically:
- **Client**: `preActions` contains `'quack:` (but not `'ducklake:quack:`).
- **Server**: connection option `quackServerToken` is set (the embedded `starlake quack` CLI uses this).

#### Quack Client (consumer)

A thin DuckDB engine that forwards every query to a remote Quack server. No `ducklake` extension, no S3 secret, no catalog credentials.

```yaml
connections:
  warehouse-quack:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      preActions: |
        INSTALL quack; LOAD quack;
        CREATE SECRET (TYPE quack, TOKEN '{{quackToken}}');
        ATTACH 'quack:{{warehouseHost}}:9494' AS remote;
      quote: "\""
```

#### Quack Server — Local DuckLake catalog

Single-server setup: catalog is a local `.ducklake` file, data lives in S3. Server-side ATTACH means the client never learns DuckLake is involved.

```yaml
connections:
  warehouse-server:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      preActions: |
        INSTALL ducklake; LOAD ducklake; INSTALL quack; LOAD quack;
        CREATE SECRET (TYPE s3, KEY_ID '{{s3Key}}', SECRET '{{s3Secret}}', REGION 'eu-west-1');
        ATTACH 'ducklake:my_catalog.ducklake' AS lake (DATA_PATH 's3://my-bucket/data/');
      quackServerToken: "{{quackToken}}"
      quackBind: "127.0.0.1"   # optional, default 127.0.0.1
      quackPort: "9494"         # optional, default 9494
      quote: "\""
```

#### Quack Server — PostgreSQL catalog (inline credentials)

Use Postgres as the catalog backend when running multiple Quack servers against the same lake. Credentials are interpolated directly into the `ATTACH 'ducklake:postgres:...'` string.

```yaml
connections:
  warehouse-server-pg:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      preActions: |
        INSTALL POSTGRES; LOAD POSTGRES;
        INSTALL ducklake; LOAD ducklake;
        INSTALL quack;    LOAD quack;
        CREATE SECRET (
          TYPE s3,
          KEY_ID '{{s3Key}}',
          SECRET '{{s3Secret}}',
          REGION 'eu-west-1'
        );
        ATTACH 'ducklake:postgres:
            dbname={{pgDatabase}}
            host={{pgHost}}
            port={{pgPort}}
            user={{pgUser}}
            password={{pgPassword}}' AS lake
          (DATA_PATH 's3://my-bucket/data/');
      quackServerToken: "{{quackToken}}"
      quackBind: "127.0.0.1"
      quackPort: "9494"
      quote: "\""
```

#### Quack Server — PostgreSQL catalog via DuckDB SECRET

Move the host/port/user/password out of the ATTACH literal into a named Postgres secret. The ATTACH then only needs `dbname=...`; DuckDB resolves the rest from the matching secret. Easier to rotate credentials and to combine with persistent secrets.

```yaml
connections:
  warehouse-server-pg-secret:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      preActions: |
        INSTALL POSTGRES; LOAD POSTGRES;
        INSTALL ducklake; LOAD ducklake;
        INSTALL quack;    LOAD quack;
        CREATE SECRET pg_catalog (
          TYPE postgres,
          HOST '{{pgHost}}',
          PORT {{pgPort}},
          DATABASE '{{pgDatabase}}',
          USER '{{pgUser}}',
          PASSWORD '{{pgPassword}}'
        );
        CREATE SECRET s3_lake (
          TYPE s3,
          KEY_ID '{{s3Key}}',
          SECRET '{{s3Secret}}',
          REGION 'eu-west-1'
        );
        ATTACH 'ducklake:postgres:dbname={{pgDatabase}}' AS lake
          (DATA_PATH 's3://my-bucket/data/');
      quackServerToken: "{{quackToken}}"
      quackBind: "127.0.0.1"
      quackPort: "9494"
      quote: "\""
```

> **Secret names are not referenced from ATTACH.** Names like `pg_catalog` and `s3_lake` are management labels for `DROP SECRET` and `FROM duckdb_secrets()`. DuckDB resolves secrets by *scope* (matching `TYPE` + URL/host), not by name. Add an explicit `SCOPE` clause only when two secrets of the same type would otherwise both match.

#### Quack Server — Multi-bucket S3 with SCOPE

When catalog metadata and data files live in different buckets (or use different IAM roles), scope each S3 secret to its URL prefix. The longest matching prefix wins; an unscoped secret of the same type acts as a catch-all default.

```yaml
connections:
  warehouse-server-multi-bucket:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      preActions: |
        INSTALL POSTGRES; LOAD POSTGRES;
        INSTALL ducklake; LOAD ducklake;
        INSTALL quack;    LOAD quack;

        CREATE SECRET s3_catalog (
          TYPE s3,
          SCOPE 's3://catalog-bucket',
          KEY_ID '{{s3CatalogKey}}',
          SECRET '{{s3CatalogSecret}}',
          REGION 'eu-west-1'
        );
        CREATE SECRET s3_lake (
          TYPE s3,
          SCOPE 's3://data-bucket',
          KEY_ID '{{s3LakeKey}}',
          SECRET '{{s3LakeSecret}}',
          REGION 'eu-west-1'
        );

        ATTACH 'ducklake:postgres:dbname={{pgDatabase}}' AS lake
          (DATA_PATH 's3://data-bucket/lake/');
      quackServerToken: "{{quackToken}}"
      quackBind: "127.0.0.1"
      quackPort: "9494"
      quote: "\""
```

Reads from `s3://catalog-bucket/...` resolve via `s3_catalog`; reads/writes under `s3://data-bucket/...` resolve via `s3_lake`. Postgres secrets follow the same model — DuckDB matches on the connection's `HOST`/`PORT`/`DATABASE` triple, so two Postgres secrets targeting different hosts coexist without explicit scopes.

#### Quack CLI

Run a Quack server in the Starlake JVM (no Docker, no external orchestrator):

```bash
starlake quack serve    --connection warehouse-server   # foreground
starlake quack start    --connection warehouse-server   # detached daemon
starlake quack stop     --connection warehouse-server
starlake quack list
starlake quack stop-all
```

Flags `--bind`, `--port`, `--token` override the connection's `quackBind`, `quackPort`, `quackServerToken` for that invocation. State for detached servers lives under `$SL_ROOT/.quack/`. Default `quackBind` is `127.0.0.1` — bind to `0.0.0.0` only behind a TLS-terminating reverse proxy.

> **Version requirements:** DuckDB engine 1.5.3+ (Quack is a core extension; DuckLake supports a Quack catalog). Starlake bundles the 1.5.3 DuckDB JDBC driver. The DuckDB ODBC driver used by client apps must also bundle a 1.5.3+ engine.

#### Quack Server Authentication & Authorization

A Quack server exposes the **full SQL surface** of its DuckDB session — every table the server can see is readable and writable by any client that knows the token. Lock the server down with two server-side callbacks. Both are added to the server connection's `preActions` so they are registered before `starlake quack serve` starts accepting clients.

| Hook | Setting | Default | Signature |
|------|---------|---------|-----------|
| Authentication | `quack_authentication_function` | `quack_check_token` | `(session_id, client_token, server_token) -> BOOLEAN` |
| Authorization  | `quack_authorization_function`  | `quack_nop_authorization` | `(connection_id, query) -> BOOLEAN` |

Rules:
- Use **`SET GLOBAL`** (a plain `RESET` only clears the session view and the auth path keeps reading the stale global value).
- Callbacks are **fail-closed** — any error rejects the request, so a buggy macro locks every client out.
- Each callback runs in a **fresh server-side connection**, so it cannot rely on session-local state. Python UDFs created with `con.create_function` do not work; use SQL macros or an extension-registered scalar function.

##### Read-only Quack server

Restrict every client to `SELECT` / `FROM` / `WITH` / `EXPLAIN` / `DESCRIBE` / `SHOW`:

```yaml
connections:
  warehouse-server-readonly:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      preActions: |
        INSTALL ducklake; LOAD ducklake; INSTALL quack; LOAD quack;
        CREATE SECRET (TYPE s3, KEY_ID '{{s3Key}}', SECRET '{{s3Secret}}', REGION 'eu-west-1');
        ATTACH 'ducklake:my_catalog.ducklake' AS lake (DATA_PATH 's3://my-bucket/data/');

        CREATE OR REPLACE MACRO read_only(sid, query) AS
            regexp_matches(upper(trim(query)), '^(SELECT|FROM|WITH|EXPLAIN|DESCRIBE|SHOW)\b');
        SET GLOBAL quack_authorization_function = 'read_only';
      quackServerToken: "{{quackToken}}"
      quote: "\""
```

##### Per-user tokens (multi-tenant)

Authenticate against a table of allowed tokens instead of the single `quackServerToken`:

```yaml
connections:
  warehouse-server-multitoken:
    type: "jdbc"
    options:
      url: "jdbc:duckdb:"
      driver: "org.duckdb.DuckDBDriver"
      preActions: |
        INSTALL ducklake; LOAD ducklake; INSTALL quack; LOAD quack;
        CREATE SECRET (TYPE s3, KEY_ID '{{s3Key}}', SECRET '{{s3Secret}}', REGION 'eu-west-1');
        ATTACH 'ducklake:my_catalog.ducklake' AS lake (DATA_PATH 's3://my-bucket/data/');

        CREATE TABLE IF NOT EXISTS quack_tokens (auth_token VARCHAR, user_name VARCHAR);
        -- INSERT rows out-of-band: INSERT INTO quack_tokens VALUES ('alice-key-123', 'alice');
        CREATE OR REPLACE MACRO check_token(sid, client_token, server_token) AS (
            EXISTS (SELECT 1 FROM quack_tokens WHERE auth_token = client_token)
        );
        SET GLOBAL quack_authentication_function = 'check_token';
      quackServerToken: "{{quackToken}}"
      quote: "\""
```

> `quackServerToken` is still required (it is the token Starlake itself uses to bootstrap the server). The `check_token` macro replaces the default token check for client connections so every user can present their own token.

##### Per-user ACLs (combine auth + authz)

The authorization hook receives a `connection_id` that matches the `session_id` the authentication hook saw. Use a `quack_sessions` table to link them and a per-user policy table to drive `acl_check`. See `docs/quack-auth.md` for the full pattern (the lookup macro plus a scalar UDF that records sessions — a SQL macro alone cannot do DML).

##### Inspecting the query the hook sees

The `query` argument is the raw SQL the client sent — including any `remote.query('...')` wrapper. Enable Quack logging to see exactly what each hook will be matched against:

```sql
CALL enable_logging('Quack');
-- run a client query, then:
SELECT * FROM duckdb_logs_parsed('Quack');
```

Regex-on-SQL is reliable for kind-level matches (SELECT vs INSERT) but fragile for table-level rules. For genuine table isolation, restrict what the server's session sees (expose only specific views) and use the authorization hook for the read/write distinction.
