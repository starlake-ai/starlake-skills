---
name: extract-rest-data
description: Extract data from REST API endpoints into CSV or JSON Lines files with pagination, auth, incremental, resume, proxy, and mTLS support
---

# Extract REST Data Skill

Extracts data from REST API endpoints into CSV or JSON Lines files. Handles pagination (offset, cursor, link header, page number), authentication (bearer, API key, basic, OAuth2), rate limiting, retries with configurable backoff, timeouts, proxy, mTLS/custom certificates, nested JSON flattening, parent-child endpoint relationships, incremental extraction with state tracking, resume on failure, and response validation for error-in-200 APIs. The extracted files can then be loaded using `starlake load`.

## Usage

```bash
starlake extract-rest-data [options]
```

## Options

- `--config <value>`: REST API extraction config name (required) — references a file in `metadata/extract/`
- `--outputDir <value>`: Where to output files (required)
- `--limit <value>`: Limit number of records extracted per endpoint
- `--parallelism <value>`: Parallelism level for endpoint extraction (default: available CPU cores)
- `--incremental`: Only extract new data since last extraction (uses `incrementalField` from endpoint config)
- `--resume`: Resume extraction from where a previous run failed, skipping already-extracted pages
- `--outputFormat <value>`: Output format: `csv` (default) or `jsonl` (JSON Lines, preserves nested structures)
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
    headers:
      Accept: "application/json"
    rateLimit:
      requestsPerSecond: 10
    retry:
      maxRetries: 3
      initialBackoffMs: 1000
      maxBackoffMs: 30000
    timeout:
      connectTimeoutMs: 30000
      readTimeoutMs: 60000
    # proxy:                        # Optional HTTP proxy
    #   host: "proxy.corp.com"
    #   port: 8080
    # tls:                          # Optional mTLS / custom CA
    #   trustStorePath: "/path/to/truststore.jks"
    #   trustStorePassword: "{{TRUST_PASS}}"
    defaults:
      pagination:
        type: offset
        limitParam: "limit"
        offsetParam: "offset"
        pageSize: 100
    endpoints:
      - path: "/customers"
        as: "customer"
        domain: "crm"
        responsePath: "$.data"
        incrementalField: "updated_at"

      - path: "/orders"
        as: "order"
        domain: "crm"
        pagination:
          type: cursor
          cursorParam: "after"
          cursorPath: "$.meta.next_cursor"
          pageSize: 50
          limitParam: "per_page"
        responsePath: "$.results"
        children:
          - path: "/orders/{parent.id}/items"
            as: "order_item"
            domain: "crm"
            responsePath: "$.items"

      - path: "/products"
        as: "product"
        domain: "catalog"
        pagination:
          type: page_number
          pageParam: "page"
          pageSize: 25
          limitParam: "per_page"
```

### Authentication Types

| Type | Fields | Description |
|------|--------|-------------|
| `bearer` | `token` | Bearer token in Authorization header |
| `api_key` | `key`, `header` (default: X-API-Key) | API key in custom header |
| `basic` | `username`, `password` | HTTP Basic authentication |
| `oauth2_client_credentials` | `tokenUrl`, `clientId`, `clientSecret`, `scope` | OAuth2 with automatic token refresh on expiry and 401 |

All credential fields support `{{ENV_VAR}}` syntax.

### Pagination Strategies

| Type | Fields | Description |
|------|--------|-------------|
| `offset` | `limitParam`, `offsetParam`, `pageSize` | Offset-based pagination |
| `cursor` | `cursorParam`, `cursorPath`, `pageSize`, `limitParam` | Cursor extracted from response body |
| `link_header` | `pageSize`, `limitParam` | RFC 5988 Link header with `rel="next"` |
| `page_number` | `pageParam`, `pageSize`, `limitParam` | Page number pagination |

### Rate Limiting

```yaml
rateLimit:
  requestsPerSecond: 10  # Max 10 requests/second
```

### Retry Configuration

```yaml
retry:
  maxRetries: 5           # Default: 3
  initialBackoffMs: 2000  # Default: 1000 (doubles on each retry)
  maxBackoffMs: 60000     # Default: 30000
```

Automatic retry with exponential backoff on HTTP 429 (Too Many Requests), 5xx errors, and connection failures.

### Timeout Configuration

```yaml
timeout:
  connectTimeoutMs: 15000  # Default: 30000
  readTimeoutMs: 120000    # Default: 60000
```

### Proxy Support

```yaml
proxy:
  host: "proxy.corp.com"
  port: 8080
  username: "{{PROXY_USER}}"   # Optional
  password: "{{PROXY_PASS}}"   # Optional
```

### TLS / mTLS

```yaml
tls:
  trustStorePath: "/path/to/truststore.jks"
  trustStorePassword: "{{TRUST_PASS}}"
  keyStorePath: "/path/to/keystore.jks"     # For mTLS client cert
  keyStorePassword: "{{KEY_PASS}}"
  # insecure: true                          # Dev only: trust all certs
```

### Response Validation (Error-in-200)

```yaml
endpoints:
  - path: "/data"
    errorPath: "$.error"   # Treat as error if $.error is non-null in 200 response
```

### Parent-Child Endpoints

Use `{parent.fieldName}` placeholders in child endpoint paths:

```yaml
endpoints:
  - path: "/orders"
    as: "order"
    domain: "sales"
    children:
      - path: "/orders/{parent.id}/items"
        as: "order_item"
        domain: "sales"
      - path: "/orders/{parent.id}/payments"
        as: "order_payment"
        domain: "sales"
```

For each parent record, the child endpoints are called with the parent's field values substituted.

### POST Endpoints with Request Body

```yaml
endpoints:
  - path: "/search"
    method: "POST"
    as: "search_results"
    domain: "catalog"
    requestBody: '{"query": "active", "filters": {"status": "published"}}'
    responsePath: "$.hits"
```

## Output Format

Data is written to `{outputDir}/{domain}/{tableName}-{timestamp}.csv`:

```
/tmp/api-data/
  crm/
    customer-20240115103000.csv
    order-20240115103000.csv
    order_item-20240115103000.csv
  catalog/
    product-20240115103000.csv
```

Nested JSON objects are flattened using dot notation:
```
id,name,address.city,address.country
1,Alice,Paris,France
```

## Incremental Extraction

When `--incremental` is used with endpoints that have `incrementalField` configured:

1. **First run**: Extracts all data, saves the max value of `incrementalField` to a state file
2. **Subsequent runs**: Reads the last extracted value from state and passes it as a query parameter

State files are stored in `{outputDir}/.state/{domain}/{tableName}.json`:
```json
{"lastValue": "2024-01-15", "extractedAt": "20240115103000"}
```

## XML Response Support

REST API responses with `Content-Type: application/xml` are automatically converted to JSON for processing. XML elements become JSON fields, repeated elements become arrays, and attributes are prefixed with `@`.

## Examples

### Full Data Extraction

```bash
starlake extract-rest-data --config my-rest-api --outputDir /tmp/api-data
```

### Incremental Extraction

```bash
starlake extract-rest-data --config my-rest-api --outputDir /tmp/api-data --incremental
```

### Extract with Record Limit

```bash
starlake extract-rest-data --config my-rest-api --outputDir /tmp/api-data --limit 1000
```

### Parallel Extraction

```bash
starlake extract-rest-data --config my-rest-api --outputDir /tmp/api-data --parallelism 4
```

### JSON Lines Output

```bash
starlake extract-rest-data --config my-rest-api --outputDir /tmp/api-data --outputFormat jsonl
```

### Resume After Failure

```bash
starlake extract-rest-data --config my-rest-api --outputDir /tmp/api-data --resume
```

## End-to-End Workflow

```bash
# 1. Extract schema (generates YAML table definitions)
starlake extract-rest-schema --config my-rest-api --outputDir metadata/load

# 2. Extract data (generates CSV files)
starlake extract-rest-data --config my-rest-api --outputDir /tmp/api-data

# 3. Load into warehouse
starlake load
```

## Related Skills

- [extract-rest-schema](../extract-rest-schema/SKILL.md) - Extract schema from REST API endpoints
- [extract](../extract/SKILL.md) - Extract schema and data from JDBC sources
- [extract-data](../extract-data/SKILL.md) - Extract data from JDBC databases
- [load](../load/SKILL.md) - Load extracted data into the warehouse
- [connection](../connection/SKILL.md) - Configure connections