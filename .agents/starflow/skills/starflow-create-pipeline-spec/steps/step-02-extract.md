---
extract_block: ''  # set in this step: the full YAML extract: ... block written into the spec
---

# Step 2 — Extract Specification

## Rules

- One source class at a time. If `{{source_class}}` is `mixed`, ask the user which to define first; loop back through this step for each remaining class before advancing.
- Reference the `extract` and `extract-rest-data` Starlake skills for full option lists when in doubt — do not invent flags.

## Preconditions

- Step 1 complete. `{{source_class}}` is set.

## Instructions

Branch on `{{source_class}}`:

### If `jdbc`

Ask:
- Connection name (will be defined in step 6).
- Source schema(s) and tables (or `*` for all).
- Per-table: which columns (or `*`), `partitionColumn`, `numPartitions`, `fetchSize`.
- Extraction mode: full / incremental (and the `incrementalField` if incremental).

Write into the spec:

```yaml
version: 1
extract:
  connectionRef: "<conn>"
  jdbcSchemas:
    - schema: "<schema>"
      tables:
        - name: "<table>"
          columns: ["..."]
          fetchSize: 10000
          partitionColumn: "<col>"
          numPartitions: 4
```

### If `rest`

Ask:
- `baseUrl`.
- Auth: `bearer` / `api_key` / `basic` / `oauth2_client_credentials` (and where the secret comes from — env var name).
- Pagination strategy per endpoint: `offset` / `cursor` / `link_header` / `page_number`.
- Rate limit (requests per second).
- Endpoints: path, target table name (`as`), domain, `responsePath`, `incrementalField`.
- Parent-child relationships (use `{parent.id}` placeholders if needed).

Write into the spec:

```yaml
version: 1
extract:
  restAPI:
    baseUrl: "https://api.example.com/v2"
    auth:
      type: bearer
      token: "{{API_TOKEN}}"
    rateLimit:
      requestsPerSecond: 10
    defaults:
      pagination:
        type: offset
        limitParam: "limit"
        offsetParam: "offset"
        pageSize: 100
    endpoints:
      - path: "/orders"
        as: "order"
        domain: "<domain>"
        responsePath: "$.data"
        incrementalField: "updated_at"
```

### If `file`

Ask:
- File location (landing path or bucket).
- Naming pattern (regex).
- Format: DSV / JSON / XML / Parquet (and delimiter / quote / header for DSV).
- Arrival cadence and trigger: schedule / file sensor / ACK file.

Document narratively in the spec under "Extract → File source" — there is no Starlake `extract:` YAML for file sources; the load step handles them via the `metadata.directory` pattern.

### If `stream`

Ask: topic, broker, format, watermark / offset strategy. Reference `kafkaload` skill for syntax.

## Save

1. Append the YAML block (or narrative for files/streams) to the spec under `## Extract`.
2. Append `2` to `stepsCompleted`. Save.

## Checkpoint

> **Extract defined for:** `{{source_class}}` — `<n>` table(s)/endpoint(s).
>
> Move on to load specification? (y/n / revise)

**HALT.** If `revise`, ask which field to change and re-prompt. If `y`, proceed.

## Next

Read fully and follow: `step-03-load.md`
