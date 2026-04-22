---
name: extract-rest-schema
description: Extract schemas from REST API endpoints by fetching sample responses and inferring data structure
---

# Extract REST Schema Skill

Extracts Starlake table schemas from REST API endpoints. Fetches a sample response from each configured endpoint, infers the JSON structure, and generates Starlake YAML configuration files (domain + table definitions). Supports nested objects, arrays, parent-child endpoint relationships, and automatic type inference (string, long, decimal, boolean, date, timestamp, struct).

## Usage

```bash
starlake extract-rest-schema [options]
```

## Options

- `--config <value>`: REST API extraction config name (required) — references a file in `metadata/extract/`
- `--outputDir <value>`: Where to output YAML schema files
- `--connectionRef <value>`: Connection reference name
- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`

## Configuration

### REST API Extract Configuration

```yaml
# metadata/extract/my-rest-api.sl.yml
version: 1
extract:
  restAPI:
    baseUrl: "https://api.example.com/v2"
    auth:
      type: bearer
      token: "{{API_TOKEN}}"
    endpoints:
      - path: "/customers"
        as: "customer"
        domain: "crm"
        responsePath: "$.data"
      - path: "/orders"
        as: "order"
        domain: "crm"
        pagination:
          type: cursor
          cursorParam: "after"
          cursorPath: "$.meta.next_cursor"
          pageSize: 50
        responsePath: "$.results"
        children:
          - path: "/orders/{parent.id}/items"
            as: "order_item"
            responsePath: "$.items"
```

### Authentication Types

| Type | Fields | Description |
|------|--------|-------------|
| `bearer` | `token` | Bearer token in Authorization header |
| `api_key` | `key`, `header` (default: X-API-Key) | API key in custom header |
| `basic` | `username`, `password` | HTTP Basic authentication |
| `oauth2_client_credentials` | `tokenUrl`, `clientId`, `clientSecret`, `scope` | OAuth2 client credentials flow with automatic token refresh |

All credential fields support `{{ENV_VAR}}` syntax for environment variable resolution.

### Pagination Strategies

| Type | Fields | Description |
|------|--------|-------------|
| `offset` | `limitParam`, `offsetParam`, `pageSize` | Offset-based (e.g. `?limit=100&offset=200`) |
| `cursor` | `cursorParam`, `cursorPath`, `pageSize`, `limitParam` | Cursor from response (e.g. `?after=abc123`) |
| `link_header` | `pageSize`, `limitParam` | RFC 5988 Link header with `rel="next"` |
| `page_number` | `pageParam`, `pageSize`, `limitParam` | Page number (e.g. `?page=3`) |

### Endpoint Configuration

| Field | Description |
|-------|-------------|
| `path` | API endpoint path (required) |
| `method` | HTTP method: `GET` (default) or `POST` |
| `as` | Table name override (default: derived from last path segment) |
| `domain` | Domain name for grouping (default: `default`) |
| `headers` | Additional HTTP headers |
| `queryParams` | Additional query parameters |
| `requestBody` | JSON body for POST requests |
| `pagination` | Pagination strategy (overrides defaults) |
| `responsePath` | JSONPath to data array in response (e.g. `$.data`) |
| `incrementalField` | Field for incremental extraction tracking |
| `children` | Child endpoints using `{parent.fieldName}` path placeholders |
| `excludeFields` | Regex patterns to exclude fields from schema |

### Global Defaults

```yaml
restAPI:
  defaults:
    pagination:
      type: offset
      limitParam: "limit"
      offsetParam: "offset"
      pageSize: 100
    headers:
      X-Custom: "value"
  endpoints:
    - path: "/endpoint1"  # inherits default pagination
    - path: "/endpoint2"
      pagination:          # overrides default
        type: cursor
        cursorParam: "next"
        cursorPath: "$.cursor"
        pageSize: 50
```

## Type Inference

The schema extractor infers Starlake types from JSON values:

| JSON Type | Starlake Type |
|-----------|--------------|
| String (ISO date `2024-01-15`) | `date` |
| String (ISO datetime `2024-01-15T10:30:00Z`) | `timestamp` |
| String (other) | `string` |
| Integer | `long` |
| Decimal | `decimal` |
| Boolean | `boolean` |
| Object | `struct` (with nested attributes) |
| Array of objects | `struct` with `array: true` |
| Array of scalars | scalar type with `array: true` |

## Schema Evolution Detection

When re-extracting schemas, Starlake compares the inferred schema against existing YAML definitions and logs warnings when:
- **New fields** appear in the API response that weren't in the previous schema
- **Fields are removed** from the API response that existed in the previous schema

This helps detect API changes early before they break downstream pipelines.

## Examples

### Extract Schema from REST API

```bash
starlake extract-rest-schema --config my-rest-api
```

### Extract to Custom Output Directory

```bash
starlake extract-rest-schema --config my-rest-api --outputDir /tmp/schemas
```

## Related Skills

- [extract-rest-data](../extract-rest-data/SKILL.md) - Extract data from REST API endpoints
- [extract](../extract/SKILL.md) - Extract schema and data from JDBC sources
- [extract-schema](../extract-schema/SKILL.md) - Extract schema from JDBC databases
- [load](../load/SKILL.md) - Load extracted data into the warehouse