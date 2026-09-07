---
name: extract
description: 'Extract both schema AND data from a JDBC database in one shot with `starlake extract`: reverse-engineer tables into Starlake YAML then export the rows to files; also drives REST API and OpenAPI/Swagger extract configs'
---

# Extract Skill

Combines schema extraction and data extraction in a single command. First extracts the database schema metadata into Starlake YAML files, then extracts the actual data into files. This is a convenience command that runs `extract-schema` followed by `extract-data`.

## Usage

```bash
starlake extract [options]
```

## Options

Combines all options from [extract-schema](../extract-schema/SKILL.md) and [extract-data](../extract-data/SKILL.md) — see those skills for the full, authoritative option lists.

## Configuration Context

Extract commands use a configuration file (`metadata/extract/{name}.sl.yml`) to define which schemas and tables to extract:

```yaml
# metadata/extract/externals.sl.yml
version: 1
extract:
  connectionRef: "duckdb"
  jdbcSchemas:
    - schema: "starbake"
      tables:
        - name: "*"              # "*" to extract all tables
      tableTypes:
        - "TABLE"
```

Advanced `jdbcSchemas` configuration (incremental extraction via `fullExport`/`timestamp`, parallel extraction via `partitionColumn`/`numPartitions`, `fetchSize`, custom SQL, column selection, remarks queries) is documented in [extract-schema](../extract-schema/SKILL.md).

### Connection Configuration

The `connectionRef` in the extract config must name a connection defined in `application.sl.yml` — see [connection](../connection/SKILL.md) for connection templates by database.

## REST API Extract Configuration

When the extract config contains a `restAPI:` block instead of `jdbcSchemas:`, extraction targets REST API endpoints (auth: `bearer`, `api_key`, `basic`, `oauth2_client_credentials`; pagination: `offset`, `cursor`, `link_header`, `page_number`). The `restAPI` configuration format is documented in the dedicated skills:

- [extract-rest-schema](../extract-rest-schema/SKILL.md): infer schemas from API responses
- [extract-rest-data](../extract-rest-data/SKILL.md): extract data with pagination, auth, rate limiting, incremental, and resume

## OpenAPI Extract Configuration

Extract schemas from OpenAPI/Swagger specifications:

```yaml
# metadata/extract/api.sl.yml
version: 1
extract:
  openAPI:
    basePath: /api/v2

    domains:
      - name: customers_api

        # Schema filtering (regex)
        schemas:
          exclude:
            - "Model\\.Common\\.Id"
            - "Internal\\..*"

        # Route selection
        routes:
          - paths:
              include:
                - "/users"
                - "/orders"
                - "/products"
```

## Freshness Monitoring

Track data freshness with timestamp columns after extraction:

```bash
# Check freshness for specific tables
starlake freshness --tables dataset1.table1,dataset2.table2 --persist true
```

Monitoring table: `SL_LAST_EXPORT` in audit schema.

## Examples

### Extract Schema and Data

```bash
starlake extract --config externals --outputDir metadata/load
```

### Extract with Incremental Mode

```bash
starlake extract --config source_db --outputDir /tmp/output --incremental
```

### Extract Specific Tables

```bash
starlake extract --config source_db --tables sales.orders,sales.customers
```

## Related Skills

- [extract-schema](../extract-schema/SKILL.md) - Extract schema from JDBC databases
- [extract-data](../extract-data/SKILL.md) - Extract data from JDBC databases
- [extract-rest-schema](../extract-rest-schema/SKILL.md) - Extract schema from REST API endpoints
- [extract-rest-data](../extract-rest-data/SKILL.md) - Extract data from REST API endpoints
- [extract-script](../extract-script/SKILL.md) - Generate extraction scripts from templates
- [freshness](../freshness/SKILL.md) - Check data freshness
- [load](../load/SKILL.md) - Load extracted data into the warehouse
