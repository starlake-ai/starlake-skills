---
name: load
description: Load data from the pending area into the data warehouse
---

# Load Skill

Loads data files from the pending area into the data warehouse. Files must match the patterns defined in table configuration files (`table.sl.yml`). The load process validates data against the schema, applies write strategies, enforces data quality expectations, and applies privacy transformations.

## Usage

```bash
starlake load [options]
```

## Options

- `--domains <value>`: Comma-separated list of domains to load (default: all domains)
- `--tables <value>`: Comma-separated list of tables to load (default: all tables)
- `--accessToken <value>`: Access token for authentication (e.g. GCP)
- `--options k1=v1,k2=v2`: Substitution arguments passed to the load job
- `--test`: Run in test mode by running against the files stored in the metadata/tests directory without committing changes to the data warehouse
- `--files <value>`: Load only this specific file (fully qualified path)
- `--primaryKeys <value>`: Primary keys to set on the table schema (when inferring schema)
- `--scheduledDate <value>`: Scheduled date for the job, format: `yyyy-MM-dd'T'HH:mm:ss.SSSZ`
- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`
- `--inPlace`: Ingest files from their current location without moving or deleting them. Requires `--files`

## Configuration Context

### Domain Configuration (`metadata/load/{domain}/_config.sl.yml`)

Defines the domain name and shared metadata for all tables in the domain:

```yaml
# metadata/load/starbake/_config.sl.yml
version: 1
load:
  name: "starbake"
  metadata:
    directory: "{{incoming_path}}/starbake"
```

### Table Configuration (`metadata/load/{domain}/{table}.sl.yml`)

Defines the table schema, file pattern, format, write strategy, and attributes:

```yaml
# metadata/load/starbake/orders.sl.yml
version: 1
table:
  name: "orders"
  pattern: "orders_.*.json"
  attributes:
    - name: "customer_id"
      type: "long"
      sample: "9"
    - name: "order_id"
      type: "long"
      sample: "99"
    - name: "status"
      type: "string"
      sample: "Pending"
    - name: "timestamp"
      type: "iso_date_time"
      sample: "2024-03-01T09:01:12.529Z"
  metadata:
    format: "JSON"
    encoding: "UTF-8"
    array: true
    writeStrategy:
      type: "APPEND"
```

### CSV Table Example

```yaml
# metadata/load/starbake/order_lines.sl.yml
version: 1
table:
  name: "order_lines"
  pattern: "order-lines_.*.csv"
  attributes:
    - name: "order_id"
      type: "int"
      sample: "99"
    - name: "product_id"
      type: "int"
      sample: "9"
    - name: "quantity"
      type: "int"
      sample: "5"
    - name: "sale_price"
      type: "double"
      sample: "8.68"
  metadata:
    format: "DSV"
    encoding: "UTF-8"
    withHeader: true
    separator: ";"
    writeStrategy:
      type: "APPEND"
```

### XML Table Example

```yaml
# metadata/load/starbake/products.sl.yml
version: 1
table:
  name: "products"
  pattern: "products.*.xml"
  attributes:
    - name: "category"
      type: "string"
    - name: "cost"
      type: "double"
    - name: "name"
      type: "string"
    - name: "price"
      type: "double"
    - name: "product_id"
      type: "long"
  metadata:
    format: "XML"
    encoding: "UTF-8"
    options:
      rowTag: "record"
    writeStrategy:
      type: "OVERWRITE"
```

### Write Strategies

| Strategy | Description | Required Options | Use Case |
|---|---|---|---|
| `APPEND` | Insert all rows | None | Event logs, fact tables |
| `OVERWRITE` | Replace entire table | None | Staging, full refresh |
| `UPSERT_BY_KEY` | Update existing, insert new | `key`, `on: TARGET` | Dimension tables |
| `UPSERT_BY_KEY_AND_TIMESTAMP` | Upsert with timestamp check | `key`, `timestamp`, `on: TARGET` | CDC, incremental |
| `OVERWRITE_BY_PARTITION` | Replace specific partitions | Requires `sink.partition` | Partitioned fact tables |
| `DELETE_THEN_INSERT` | Delete matching keys, then insert | `key` | Transactional updates |
| `SCD2` | Slowly Changing Dimension Type 2 | `key`, `timestamp`, `startTs`, `endTs`, `on: BOTH` | Historical tracking |
| `ADAPTATIVE` | Runtime strategy selection | `types: { strategy: 'condition' }` | Dynamic routing |

#### APPEND Strategy

```yaml
writeStrategy:
  type: "APPEND"
```

Use for: Event logs, transaction logs, append-only fact tables.

#### OVERWRITE Strategy

```yaml
writeStrategy:
  type: "OVERWRITE"
```

Use for: Staging tables, full refresh scenarios, temporary tables.

#### UPSERT_BY_KEY Strategy

```yaml
writeStrategy:
  type: "UPSERT_BY_KEY"
  key: ["customer_id"]
  on: TARGET # Check key in target table
```

Use for: Dimension tables, master data, configuration tables.

#### UPSERT_BY_KEY_AND_TIMESTAMP Strategy

```yaml
writeStrategy:
  type: "UPSERT_BY_KEY_AND_TIMESTAMP"
  key: ["order_id"]
  timestamp: "updated_at"
  on: TARGET
```

Use for: Change Data Capture (CDC), incremental updates with timestamps.

#### OVERWRITE_BY_PARTITION Strategy

```yaml
writeStrategy:
  type: "OVERWRITE_BY_PARTITION"
  on: TARGET

# Requires sink.partition configuration
sink:
  partition:
    - "year"
    - "month"
    - "day"
```

Use for: Daily/monthly partitioned fact tables.

#### DELETE_THEN_INSERT Strategy

```yaml
writeStrategy:
  type: "DELETE_THEN_INSERT"
  key: ["product_id", "store_id"]
```

Use for: Transactional updates, clearing specific records before insert.

#### SCD2 Strategy (Slowly Changing Dimension Type 2)

```yaml
writeStrategy:
  type: "SCD2"
  key: ["customer_id"]
  timestamp: "effective_date"
  startTs: "valid_from" # Optional, defaults to application.scd2StartTimestamp
  endTs: "valid_to" # Optional, defaults to application.scd2EndTimestamp
  on: BOTH
```

Use for: Historical tracking of dimension changes, audit trails.

**SCD2 Behavior:**

- Inserts new version with `valid_from = timestamp`, `valid_to = NULL`
- Updates previous version: `valid_to = timestamp`
- Maintains complete history of changes

#### ADAPTATIVE Strategy (Dynamic Selection)

```yaml
# By day of week (full refresh on Sunday)
writeStrategy:
  types:
    APPEND: 'dayOfWeek != 7'
    OVERWRITE: 'dayOfWeek == 7'

# By filename pattern (named group)
table:
  pattern: "orders_(?<mode>FULL|INCR)_.*\\.csv"
  writeStrategy:
    types:
      OVERWRITE: 'group("mode") == "FULL"'
      APPEND: 'group("mode") == "INCR"'

# By file size (full load if large)
writeStrategy:
  types:
    OVERWRITE: 'fileSizeMo > 100'
    APPEND: 'fileSizeMo <= 100'
```

**Adaptative Criteria:**

| Criteria | Description | Example |
|---|---|---|
| `group(index/name)` | Capture group from pattern | `group("mode") == "FULL"` |
| `fileSize`, `fileSizeB` | File size in bytes | `fileSize > 1000` |
| `fileSizeKo/Mo/Go/To` | File size in units | `fileSizeMo > 100` |
| `isFirstDayOfMonth` | Current date check | `isFirstDayOfMonth` |
| `isLastDayOfMonth` | Current date check | `isLastDayOfMonth` |
| `dayOfWeek` | 1-7 (Mon-Sun) | `dayOfWeek == 7` |
| `isFileFirstDayOfMonth` | File mod date check | `isFileFirstDayOfMonth` |
| `fileDayOfWeek` | File mod day 1-7 | `fileDayOfWeek == 1` |

### File Format Options

| Format | Description | Configuration Key |
|---|---|---|
| **DSV** | Delimited values (CSV, TSV, etc.) | `format: DSV` |
| **JSON** | One JSON object per line | `format: JSON` |
| **JSON_FLAT** | Flat JSON (no nested/repeated) | `format: JSON_FLAT` |
| **JSON_ARRAY** | Single array of objects | `format: JSON_ARRAY` |
| **XML** | XML files | `format: XML` |
| **POSITION** | Fixed-width positional | `format: POSITION` |

### Advanced Attribute Configuration

```yaml
attributes:
  - name: "product_id"
    type: "integer"
    required: true
    comment: "Product primary key"

    # Optional transformations
    rename: "id" # Original column name (rename in database)
    default: "0" # Default value if null
    trim: "Both" # None, Left, Right, Both
    ignore: false # Skip loading this column
    script: "UPPER(product_id)" # Transform expression

    # Relationships
    foreignKey: "products.product_id"

    # Metrics (for automatic metric computation)
    metric: "continuous" # or "discrete"

    # Privacy transformations
    privacy: "SHA256" # HIDE, MD5, SHA1, SHA256, SHA512, AES

    # BigQuery Column-Level Security
    accessPolicy: "PII" # References BigQuery policy tag

    # Fixed-width format (POSITION)
    position:
      first: 0
      last: 10
```

### Sink Configuration

```yaml
metadata:
  sink:
    connectionRef: "bigquery" # Optional: override connection

    # BigQuery: single field, Spark: list of fields
    partition:
      field: "order_date" # BigQuery
      # - "order_date"     # Spark

    clustering:
      - "customer_id"
      - "status"

    requirePartitionFilter: false # BigQuery only
    days: 90 # BigQuery: partition expiration days

    materializedView: false # BigQuery
    enableRefresh: false # BigQuery
    refreshIntervalMs: 3600000 # BigQuery: 1 hour

    format: "parquet" # Spark: parquet, delta, iceberg
    coalesce: true # Spark: reduce partitions before write

    options:
      compression: "snappy" # Spark options
```

### Data Quality Expectations

```yaml
table:
  expectations:
    - expect: "is_col_value_not_unique('order_id') => result(0) == 1"
      failOnError: true
    - expect: "is_row_count_to_be_between(1, 1000000) => result(0) == 1"
      failOnError: false
```

## Examples

### Load All Domains

```bash
starlake load
```

### Load Specific Domain

```bash
starlake load --domains starbake
```

### Load Specific Table

```bash
starlake load --domains starbake --tables orders
```

### Load Multiple Tables

```bash
starlake load --domains starbake --tables orders,order_lines,products
```

### Test Load (Dry Run)

Run the load in test mode without writing to the warehouse:

```bash
starlake load --test
```

### Load a Specific File

```bash
starlake load --files /path/to/incoming/starbake/orders_20240301.json
```

### Load a File In-Place (No Move/Delete)

Ingest a file directly from its current location without moving or deleting it:

```bash
starlake load --domains starbake --tables orders --files /mnt/shared/orders_20240301.json --inPlace
```

### Load with Custom Options

```bash
starlake load --domains starbake --options date=2024-03-01,env=prod
```

### Load with JSON Report

```bash
starlake load --domains starbake --reportFormat json
```

## Related Skills

- [autoload](../autoload/SKILL.md) - Automatically infer schemas and load
- [stage](../stage/SKILL.md) - Move files from landing to pending area
- [preload](../preload/SKILL.md) - Check for files available for loading
- [infer-schema](../infer-schema/SKILL.md) - Infer schema from data files
- [transform](../transform/SKILL.md) - Run transformations on loaded data
- [expectations](../expectations/SKILL.md) - Data quality expectations reference
- [config](../config/SKILL.md) - Configuration reference (environment variables, types)
