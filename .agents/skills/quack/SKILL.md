---
name: quack
description: Manage Quack DuckDB query servers exposing DuckLake over a thin remote protocol — serve (foreground), start/stop/list/stop-all (background)
---

# Quack Skill

Hosts a [Quack](https://duckdb.org/docs/extensions/quack) DuckDB query server from the Starlake JVM. Quack lets a DuckDB instance expose its tables (typically backed by a DuckLake lakehouse) to remote clients **without** sharing object-storage credentials with those clients. The server owns DuckLake + S3 secrets; clients connect with a thin token and run ordinary SQL.

## Usage

```bash
starlake quack <action> [options]
```

## Actions

| Action     | Description                                                                |
|------------|----------------------------------------------------------------------------|
| `serve`    | Run a Quack server in the foreground (blocks until SIGTERM)                |
| `start`    | Spawn a Quack server as a detached daemon, tracked under `$SL_ROOT/.quack/` |
| `stop`     | Stop the server for a given connection                                     |
| `list`     | List all running Quack servers                                             |
| `stop-all` | Stop every running Quack server                                            |

## Options

- `action` (required): `serve`, `start`, `stop`, `list`, or `stop-all`
- `--connection <value>`: Connection name (required for `serve`, `start`, `stop`)
- `--bind <value>`: Bind address (default `127.0.0.1`; overrides `quackBind` connection option)
- `--port <value>`: Port (default `9494`; overrides `quackPort` connection option)
- `--token <value>`: Server token (overrides `quackServerToken` connection option)
- `--reportFormat <value>`: `console`, `json`, or `html`

## Configuration Context

### Client connection (consumer)

Reads/writes go through the server. The client connection has no DuckLake, no S3 secret.

```yaml
version: 1
application:
  connections:
    warehouse-quack:
      type: JDBC
      options:
        url: "jdbc:duckdb:"
        driver: "org.duckdb.DuckDBDriver"
        preActions: |
          INSTALL quack; LOAD quack;
          CREATE SECRET (TYPE quack, TOKEN '{{quackToken}}');
          ATTACH 'quack:warehouse-host:9494' AS remote;
        quote: "\""
```

### Server connection — file catalog + S3 data

Single Quack server, file-backed DuckLake catalog (good for dev and small deployments).

```yaml
version: 1
application:
  connections:
    warehouse-server:
      type: JDBC
      options:
        url: "jdbc:duckdb:"
        driver: "org.duckdb.DuckDBDriver"
        preActions: |
          INSTALL ducklake; LOAD ducklake;
          INSTALL quack;    LOAD quack;
          CREATE SECRET (TYPE s3,
              KEY_ID '{{AWS_ACCESS_KEY_ID}}',
              SECRET '{{AWS_SECRET_ACCESS_KEY}}',
              REGION '{{AWS_REGION}}');
          ATTACH 'ducklake:my_catalog.ducklake' AS lake (DATA_PATH 's3://{{S3_BUCKET}}/data/');
        quackServerToken: "{{quackToken}}"
        quackBind: "127.0.0.1"
        quackPort: "9494"
        quote: "\""
```

### Server connection — PostgreSQL catalog + S3 data

Shared, durable catalog stored in PostgreSQL. Use this when multiple Quack servers need to attach the same lakehouse. The Postgres connection fields (host, port, user, password, database) are interpolated **inside** the `ATTACH 'ducklake:postgres:...'` connection string — not as new top-level connection options.

```yaml
version: 1
application:
  connections:
    warehouse-server-pg:
      type: JDBC
      options:
        url: "jdbc:duckdb:"
        driver: "org.duckdb.DuckDBDriver"
        preActions: |
          INSTALL POSTGRES; LOAD POSTGRES;
          INSTALL ducklake; LOAD ducklake;
          INSTALL quack;    LOAD quack;
          CREATE SECRET (TYPE s3,
              KEY_ID '{{AWS_ACCESS_KEY_ID}}',
              SECRET '{{AWS_SECRET_ACCESS_KEY}}',
              REGION '{{AWS_REGION}}');
          ATTACH 'ducklake:postgres:
              dbname={{pgDatabase}}
              host={{pgHost}}
              port={{pgPort}}
              user={{pgUser}}
              password={{pgPassword}}' AS lake
            (DATA_PATH 's3://{{S3_BUCKET}}/data/');
        quackServerToken: "{{quackToken}}"
        quackBind: "127.0.0.1"
        quackPort: "9494"
        quote: "\""
```

### Connection options consumed by `quack serve|start`

| Option              | Description                                          | Default     |
|---------------------|------------------------------------------------------|-------------|
| `quackServerToken`  | Required. Token clients must present.                | (required)  |
| `quackBind`         | Bind address                                         | `127.0.0.1` |
| `quackPort`         | Port                                                 | `9494`      |
| `preActions`        | SQL run before `quack_serve` (DuckLake attach, S3 / Postgres secrets, etc.) | (recommended) |

## Examples

### Start a Quack server in the foreground

```bash
starlake quack serve --connection warehouse-server
```

### Start as a detached daemon

```bash
starlake quack start --connection warehouse-server
```

### List running servers

```bash
starlake quack list
```

Output columns: `connection`, `pid`, `bind`, `port`, `startedAt`, `log`

### Stop one server

```bash
starlake quack stop --connection warehouse-server
```

### Stop everything

```bash
starlake quack stop-all
```

### Connect from a client

```bash
starlake transform --name my_job --connection warehouse-quack
```

## Security notes

- Default bind is `127.0.0.1`. To expose on the network, set `quackBind: "0.0.0.0"` and put a TLS-terminating reverse proxy (nginx, Caddy) in front. Quack does not provide TLS on its own.
- The token never appears in log files. It does appear briefly in the child process's command line when using `start` (`ps` exposure). For stricter deployments, prefer `serve` under systemd/k8s with the token in an env-substituted YAML.

## Related Skills

- [connection](../connection/SKILL.md): Database connection configuration
- [gizmosql](../gizmosql/SKILL.md): Sibling command for the GizmoSQL/Flight server
- [settings](../settings/SKILL.md): Print settings and test connections
- [config](../config/SKILL.md): Configuration reference