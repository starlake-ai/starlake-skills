---
skill_name: config
version: 3.0.0
description: Starlake configuration reference — environment variables, application structure, attribute types, storage patterns, and best practices
tags:
  [
    starlake,
    data-engineering,
    etl,
    yaml,
    configuration,
    schema,
    spark,
    duckdb,
    bigquery,
    snowflake,
    airflow,
    dagster,
  ]
author: Starlake Team
created: 2026-02-06
updated: 2026-03-04
---

# Starlake Configuration Skill (Transversal Reference)

Expert knowledge for creating and validating Starlake data pipeline configurations using the official JSON Schema and production-tested patterns extracted from official documentation.

> **Note:** Domain-specific configuration details have been distributed to specialized skills. This skill focuses on cross-cutting concerns. See cross-references below for specialized topics.

## Overview

Starlake uses YAML configuration files validated against a JSON Schema available at:

- **Schema URL**: https://www.schemastore.org/starlake.json
- **Schema ID**: `https://json.schemastore.org/starlake.json`
- **Draft Version**: JSON Schema Draft-07

## Core Configuration Files

### File Structure

```
metadata/
├── application.sl.yml           # Global app configuration, connections
├── env.sl.yml                   # Global environment variables
├── env.{ENV}.sl.yml            # Environment-specific overrides (PROD, DEV, etc.)
├── types/
│   ├── default.sl.yml          # Built-in type definitions
│   └── custom.sl.yml           # Custom type definitions
├── load/
│   └── {domain}/
│       ├── _config.sl.yml      # Domain-level configuration
│       └── {table}.sl.yml      # Table schemas
├── transform/
│   └── {domain}/
│       ├── {task}.sl.yml       # Task configuration
│       ├── {task}.sql          # SQL transform
│       └── {task}.py           # Python transform (optional)
├── extract/
│   └── {config}.sl.yml         # JDBC/API extraction configs
├── dags/
│   ├── {dag}.sl.yml            # DAG configuration
│   └── template/
│       └── {template}.py.j2    # Custom DAG templates
└── expectations/
    └── {name}.j2               # Jinja data quality macros
```

---

## Environment Variables Reference

### Core Variables

| Variable      | Purpose                            | Default             | Example                            |
| ------------- | ---------------------------------- | ------------------- | ---------------------------------- |
| `SL_ROOT`     | Root directory for project         | -                   | `/projects/100/101`                |
| `SL_ENV`      | Environment selector for env files | -                   | `DEV`, `PROD`, `DUCKDB`, `BQ`      |
| `SL_DATASETS` | Location of datasets directory     | `{{root}}/datasets` | `/projects/100/101/datasets`       |
| `SL_METADATA` | Metadata directory location        | `{{root}}/metadata` | `/projects/100/101/metadata`       |
| `SL_INCOMING` | Incoming files directory           | `{{root}}/incoming` | `/projects/100/101/incoming`       |
| `SL_ARCHIVE`  | Archive processed files            | `true`              | `true` / `false`                   |
| `SL_FS`       | Filesystem type                    | -                   | `file://`, `s3a://`, `hdfs://`     |
| `SL_TIMEZONE` | Timezone for date operations       | `UTC`               | `Europe/Paris`, `America/New_York` |

### Area-Specific Variables

| Variable                | Purpose                     | Default             |
| ----------------------- | --------------------------- | ------------------- |
| `SL_AREA_PENDING`       | Files pending processing    | `pending`           |
| `SL_AREA_UNRESOLVED`    | Files not matching patterns | `unresolved`        |
| `SL_AREA_ARCHIVE`       | Processed files archive     | `archive`           |
| `SL_AREA_INGESTING`     | Files being processed       | `ingesting`         |
| `SL_AREA_ACCEPTED`      | Valid records location      | `accepted`          |
| `SL_AREA_REJECTED`      | Invalid records location    | `rejected`          |
| `SL_AREA_BUSINESS`      | Transform results location  | `business`          |
| `SL_AREA_REPLAY`        | Rejected records replay     | `replay`            |
| `SL_AREA_HIVE_DATABASE` | Hive database name pattern  | `${domain}_${area}` |

### Component-Specific Variables

| Variable             | Purpose                         | Component      | Default                   |
| -------------------- | ------------------------------- | -------------- | ------------------------- |
| `SL_METRICS_ACTIVE`  | Enable metrics computation      | Load/Transform | `true`                    |
| `SL_HIVE`            | Store as Hive/Databricks tables | Spark          | `false`                   |
| `SL_AUDIT_SINK_TYPE` | Audit log destination           | Audit          | `BigQuerySink`, `FsSink`  |
| `SL_API_HTTP_PORT`   | API server port                 | API            | `11000`                   |
| `SL_API_DOMAIN`      | API server domain/IP            | API            | `localhost`               |
| `SL_UI_PORT`         | UI server port                  | UI             | `8080`                    |
| `SL_STARLAKE_PATH`   | Path to starlake executable     | Orchestrator   | `/usr/local/bin/starlake` |

### Predefined Template Variables (Auto-Generated)

| Variable          | Format                  | Example          | Usage              |
| ----------------- | ----------------------- | ---------------- | ------------------ |
| `sl_date`         | yyyyMMdd                | `20260206`       | Filename patterns  |
| `sl_datetime`     | yyyyMMddHHmmss          | `20260206143000` | Timestamp patterns |
| `sl_year`         | yyyy                    | `2026`           | Partitioning       |
| `sl_month`        | MM                      | `02`             | Partitioning       |
| `sl_day`          | dd                      | `06`             | Partitioning       |
| `sl_hour`         | HH                      | `14`             | Time partitions    |
| `sl_minute`       | mm                      | `30`             | Time partitions    |
| `sl_second`       | ss                      | `00`             | Time partitions    |
| `sl_milli`        | SSS                     | `123`            | Precision          |
| `sl_epoch_second` | Seconds since 1970      | `1738850400`     | Timestamps         |
| `sl_epoch_milli`  | Milliseconds since 1970 | `1738850400000`  | Timestamps         |

---

## Application Configuration

### Complete Application Structure

```yaml
# metadata/application.sl.yml
version: 1
application:
  name: "my-data-platform"
  connectionRef: "{{activeConnection}}"

  # Default write format
  defaultWriteFormat: parquet # parquet, delta, iceberg, json, csv

  # Load strategy class (how files are ordered for processing)
  loadStrategyClass: "ai.starlake.job.load.IngestionTimeStrategy"

  # SCD2 default column names
  scd2StartTimestamp: "sl_start_ts"
  scd2EndTimestamp: "sl_end_ts"

  # Timezone for date operations
  timezone: "UTC"

  # Storage paths
  datasets: "{{root}}/datasets"
  incoming: "{{root}}/incoming"
  metadata: "{{root}}/metadata"

  # Processing
  loader: native # or spark
  grouped: true
  parallelism: 4

  # Area configuration
  area:
    pending: "pending"
    unresolved: "unresolved"
    archive: "archive"
    ingesting: "ingesting"
    accepted: "accepted"
    rejected: "rejected"
    business: "business"
    replay: "replay"
    hiveDatabase: "${domain}_${area}"

  # Audit configuration
  audit:
    sink:
      connectionRef: "{{activeConnection}}"

  # Access policies — see [secure](../secure/SKILL.md)
  accessPolicies:
    apply: true
    location: EU
    taxonomy: RGPD

  # Default DAG references — see [dag-generate](../dag-generate/SKILL.md)
  dagRef:
    load: "default_load_dag"
    transform: "default_transform_dag"

  # Connections — see [settings](../settings/SKILL.md) for all connection types
  connections:
    duckdb-local:
      type: jdbc
      options:
        url: "jdbc:duckdb:{{sl_root_local}}/datasets/duckdb.db"
        driver: "org.duckdb.DuckDBDriver"

  # Data quality — see [expectations](../expectations/SKILL.md)
  expectations:
    active: true

  # Metrics — see [metrics](../metrics/SKILL.md)
  metrics:
    active: true
    discreteMaxCardinality: 10
    path: "{{SL_ROOT}}/metrics"

  # Spark configuration (if using Spark loader)
  spark:
    # Delta Lake
    sql:
      extensions: "io.delta.sql.DeltaSparkSessionExtension"
      catalog:
        spark_catalog: "org.apache.spark.sql.delta.catalog.DeltaCatalog"

    # Hadoop S3A configuration (for Spark S3 access)
    hadoop.fs.s3a.endpoint: "http://localhost:8333"
    hadoop.fs.s3a.access.key: "{{S3_ACCESS_KEY}}"
    hadoop.fs.s3a.secret.key: "{{S3_SECRET_KEY}}"
    hadoop.fs.s3a.path.style.access: "true"
    hadoop.fs.s3a.impl: "org.apache.hadoop.fs.s3a.S3AFileSystem"
```

---

## Attribute Types Catalog

### Built-in Primitive Types

| Type             | Primitive | Pattern                                        | Example            | Use Case         |
| ---------------- | --------- | ---------------------------------------------- | ------------------ | ---------------- |
| `string`         | string    | `.+`                                           | "Hello World"      | Text fields      |
| `int`, `integer` | long      | `[-\|\\+\|0-9][0-9]*`                          | `1234`             | IDs, counts      |
| `long`           | long      | `[-\|\\+\|0-9][0-9]*`                          | `-64564`           | Large numbers    |
| `short`          | short     | `-?\\d+`                                       | `564`              | Small integers   |
| `byte`           | byte      | `.`                                            | `x`                | Single byte      |
| `double`         | double    | `[-+]?\\d*\\.?\\d+[Ee]?[-+]?\\d*`              | `-45.78`           | Floating point   |
| `decimal`        | decimal   | `-?\\d*\\.{0,1}\\d+`                           | `-45.787686786876` | Precise decimals |
| `boolean`        | boolean   | `(?i)true\|yes\|[y1]<-TF->(?i)false\|no\|[n0]` | `TruE`             | Boolean flags    |

### Date/Time Types

| Type                   | Pattern/Format           | Example                             | Use Case             |
| ---------------------- | ------------------------ | ----------------------------------- | -------------------- |
| `date`                 | yyyy-MM-dd               | `2018-07-21`                        | Standard dates       |
| `timestamp`            | ISO_DATE_TIME            | `2019-12-31 23:59:02`               | Timestamps           |
| `basic_iso_date`       | yyyyMMdd                 | `20180721`                          | Compact dates        |
| `iso_local_date`       | yyyy-MM-dd               | `2018-07-21`                        | Local dates          |
| `iso_offset_date`      | yyyy-MM-ddXXX            | `2018-07-21+02:00`                  | Dates with offset    |
| `iso_date`             | yyyy-MM-ddXXX            | `2018-07-21+02:00`                  | ISO dates            |
| `iso_local_date_time`  | yyyy-MM-ddTHH:mm:ss      | `2018-07-21T14:30:00`               | Local datetime       |
| `iso_offset_date_time` | yyyy-MM-ddTHH:mm:ssXXX   | `2018-07-21T14:30:00+02:00`         | Datetime with offset |
| `iso_zoned_date_time`  | yyyy-MM-ddTHH:mm:ss[VV]  | `2018-07-21T14:30:00[Europe/Paris]` | Datetime with zone   |
| `iso_date_time`        | ISO_DATE_TIME            | `2018-07-21T14:30:00+02:00`         | Full ISO datetime    |
| `iso_ordinal_date`     | yyyy-DDD                 | `2018-202`                          | Ordinal dates        |
| `iso_week_date`        | YYYY-Www-D               | `2018-W29-6`                        | Week dates           |
| `iso_instant`          | yyyy-MM-ddTHH:mm:ss.SSSZ | `2018-07-21T14:30:00.000Z`          | UTC instants         |
| `rfc_1123_date_time`   | RFC 1123                 | `Sat, 21 Jul 2018 14:30:00 GMT`     | HTTP dates           |

### Custom Types

```yaml
# metadata/types/custom.sl.yml
types:
  - name: "email"
    pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    primitiveType: "string"
    sample: "user@example.com"
    comment: "Email address format"

  - name: "phone_fr"
    pattern: "^(\\+33|0)[1-9](\\d{2}){4}$"
    primitiveType: "string"
    sample: "+33612345678"
    comment: "French phone number"

  - name: "iban"
    pattern: "^[A-Z]{2}\\d{2}[A-Z0-9]{1,30}$"
    primitiveType: "string"
    sample: "FR7630006000011234567890189"
    comment: "IBAN format"
```

---

## Storage Configuration Patterns

### S3/MinIO/SeaweedFS with Spark

```yaml
# Hadoop S3A configuration
spark:
  hadoop.fs.s3a.endpoint: "http://localhost:8333"
  hadoop.fs.s3a.access.key: "{{S3_ACCESS_KEY}}"
  hadoop.fs.s3a.secret.key: "{{S3_SECRET_KEY}}"
  hadoop.fs.s3a.path.style.access: "true"
  hadoop.fs.s3a.connection.ssl.enabled: "false"
  hadoop.fs.s3a.impl: "org.apache.hadoop.fs.s3a.S3AFileSystem"
```

### DuckDB S3 Extension

```yaml
connections:
  duckdb:
    type: jdbc
    options:
      url: "jdbc:duckdb:{{DUCKDB_PATH}}"
      driver: "org.duckdb.DuckDBDriver"

      # DuckDB S3 extension
      preActions: |
        INSTALL httpfs;
        LOAD httpfs;
        SET s3_region='us-east-1';
        SET s3_endpoint='localhost:8333';
        SET s3_access_key_id='{{S3_ACCESS_KEY}}';
        SET s3_secret_access_key='{{S3_SECRET_KEY}}';
        SET s3_use_ssl=false;
        SET s3_url_style='path';
```

---

## Cross-Reference: Specialized Skills

| Topic | Skill | Details |
|---|---|---|
| Connection types (BigQuery, Snowflake, DuckDB...) | [settings](../settings/SKILL.md) | Full connection YAML examples |
| Write strategies (APPEND, SCD2, ADAPTATIVE...) | [load](../load/SKILL.md) | Strategy comparison, YAML examples |
| Privacy transformations (HIDE, SHA256, AES...) | [secure](../secure/SKILL.md) | Privacy types, BigQuery policies |
| Data quality expectations | [expectations](../expectations/SKILL.md) | Syntax, macros, variables |
| DAG configuration & scheduling | [dag-generate](../dag-generate/SKILL.md) | Schedule, sensors, templates |
| OpenAPI extraction | [extract](../extract/SKILL.md) | basePath, domains, routes |
| Advanced JDBC extraction | [extract-schema](../extract-schema/SKILL.md) | Custom remarks, column selection |
| Load strategies (file ordering) | [autoload](../autoload/SKILL.md) | IngestionTime/Name, custom |
| Metrics configuration | [metrics](../metrics/SKILL.md) | SL_METRICS, path config |

---

## Complete Examples

### Example 1: E-Commerce Order Processing

```yaml
# metadata/application.sl.yml
version: 1
application:
  name: "ecommerce-platform"
  connectionRef: "{{activeConnection}}"
  defaultWriteFormat: delta
  timezone: "UTC"

  connections:
    spark:
      type: spark

  spark:
    sql:
      extensions: "io.delta.sql.DeltaSparkSessionExtension"
      catalog:
        spark_catalog: "org.apache.spark.sql.delta.catalog.DeltaCatalog"

# metadata/load/orders/_config.sl.yml
load:
  name: "orders"
  metadata:
    format: DSV
    separator: ","
    withHeader: true

# metadata/load/orders/transactions.sl.yml
table:
  pattern: "orders_(?<type>FULL|DELTA)_.*\\.csv"
  primaryKey: ["order_id"]

  metadata:
    writeStrategy:
      types:
        OVERWRITE: 'group("type") == "FULL"'
        UPSERT_BY_KEY_AND_TIMESTAMP: 'group("type") == "DELTA"'
      key: ["order_id"]
      timestamp: "updated_at"
      on: TARGET

    sink:
      partition:
        - "order_date"
      clustering:
        - "customer_id"
        - "status"

  attributes:
    - name: "order_id"
      type: "long"
      required: true

    - name: "customer_id"
      type: "long"
      required: true
      foreignKey: "customers.customer_id"

    - name: "order_date"
      type: "date"
      required: true

    - name: "status"
      type: "string"
      required: true
      metric: "discrete"

    - name: "total_amount"
      type: "decimal"
      required: true
      metric: "continuous"

    - name: "customer_email"
      type: "string"
      privacy: "SHA256"

    - name: "updated_at"
      type: "timestamp"
      required: true

  expectations:
    - expect: "is_col_value_not_unique('order_id') => result(0) == 1"
      failOnError: true
    - expect: "SELECT COUNT(*) FROM SL_THIS WHERE total_amount <= 0 => count == 0"
      failOnError: true

# metadata/transform/analytics/daily_revenue.sl.yml
task:
  domain: "analytics"
  table: "daily_revenue"

  writeStrategy:
    type: "OVERWRITE_BY_PARTITION"

  sink:
    partition:
      - "report_date"

  attributesDesc:
    - name: "total_revenue"
      comment: "Sum of all order amounts"

# metadata/transform/analytics/daily_revenue.sql
SELECT
  DATE(order_date) as report_date,
  COUNT(*) as order_count,
  SUM(total_amount) as total_revenue,
  AVG(total_amount) as avg_order_value,
  COUNT(DISTINCT customer_id) as unique_customers
FROM {{orders}}.transactions
WHERE order_date = '{{sl_date}}'
  AND status IN ('COMPLETED', 'SHIPPED')
GROUP BY DATE(order_date)
```

### Example 2: SCD2 Customer Dimension

```yaml
# metadata/load/customers/customer_master.sl.yml
table:
  pattern: "customers_.*\\.csv"
  primaryKey: ["customer_id"]

  metadata:
    format: DSV
    separator: ","
    withHeader: true

    writeStrategy:
      type: "SCD2"
      key: ["customer_id"]
      timestamp: "effective_date"
      startTs: "valid_from"
      endTs: "valid_to"
      on: BOTH

  attributes:
    - name: "customer_id"
      type: "long"
      required: true

    - name: "customer_name"
      type: "string"
      required: true

    - name: "email"
      type: "string"
      privacy: "SHA256"

    - name: "address"
      type: "string"

    - name: "city"
      type: "string"

    - name: "country"
      type: "string"
      metric: "discrete"

    - name: "tier"
      type: "string"
      metric: "discrete"

    - name: "effective_date"
      type: "date"
      required: true

    - name: "valid_from"
      type: "timestamp"
      comment: "SCD2 start timestamp (auto-populated)"

    - name: "valid_to"
      type: "timestamp"
      comment: "SCD2 end timestamp (auto-populated)"
```

**Result:** Maintains complete history of customer changes:

- Current row: `valid_to = NULL`
- Historical rows: `valid_to` set to change timestamp

---

## Best Practices

### 1. Use Variable Substitution Everywhere

**Good:**

```yaml
url: "jdbc:postgresql://{{PG_HOST}}:{{PG_PORT}}/{{PG_DB}}"
incoming: "{{SL_ROOT}}/incoming/{{domain}}"
```

**Bad:**

```yaml
url: "jdbc:postgresql://localhost:5432/mydb"
incoming: "/projects/100/101/incoming/sales"
```

### 2. Separate Environment Configuration

```yaml
# env.sl.yml (global)
env:
  root: "/opt/starlake"
  activeConnection: "duckdb"
  PG_HOST: "localhost"

# env.PROD.sl.yml (production overrides)
env:
  root: "/data/production/starlake"
  activeConnection: "bigquery"
  PG_HOST: "${POSTGRES_HOST}"  # Injected from env var
```

### 3. Define Reusable Custom Types

```yaml
# types/custom.sl.yml
types:
  - name: "product_sku"
    pattern: "^[A-Z]{3}-\\d{6}$"
    primitiveType: string
    sample: "PRD-123456"

  - name: "iso_country_code"
    pattern: "^[A-Z]{2}$"
    primitiveType: string
    sample: "US"
```

### 4. Layer Expectations for Data Quality

```yaml
expectations:
  # Critical: fail on error
  - expect: "is_col_value_not_unique('id') => result(0) == 1"
    failOnError: true

  # Warning: log but continue
  - expect: "is_row_count_to_be_between(100, 1000000) => result(0) == 1"
    failOnError: false
```

See [expectations](../expectations/SKILL.md) for full syntax and macros.

### 5. Choose Write Strategies by Use Case

| Table Type                   | Recommended Strategy     | Reason                   |
| ---------------------------- | ------------------------ | ------------------------ |
| **Dimension (master data)**  | `UPSERT_BY_KEY`          | Keep latest version      |
| **Dimension (with history)** | `SCD2`                   | Track changes over time  |
| **Fact (partitioned)**       | `OVERWRITE_BY_PARTITION` | Replace daily/monthly    |
| **Fact (append-only)**       | `APPEND`                 | Event logs, transactions |
| **Staging**                  | `OVERWRITE`              | Temporary, full refresh  |

See [load](../load/SKILL.md) for detailed strategy YAML examples.

### 6. Apply Privacy Transformations Early

```yaml
attributes:
  - name: "ssn"
    type: "string"
    privacy: "HIDE" # Never stored

  - name: "email"
    type: "string"
    privacy: "SHA256" # One-way hash
```

See [secure](../secure/SKILL.md) for all privacy types.

### 7. Partition Large Tables

```yaml
# BigQuery
sink:
  partition:
    field: "event_date"
  clustering:
    - "user_id"
    - "event_type"
  requirePartitionFilter: true  # Force partition pruning

# Spark
sink:
  partition:
    - "year"
    - "month"
    - "day"
```

### 8. Document with Comments and Tags

```yaml
table:
  name: "orders"
  comment: "E-commerce order transactions from Shopify API"
  tags: ["revenue", "critical", "daily", "pii"]

  attributes:
    - name: "order_id"
      comment: "Unique order identifier from Shopify"
```

---

## Validation

### CLI Validation

```bash
# Validate all metadata
starlake validate --all

# Validate specific domain
starlake validate --domain sales
```

### IDE Integration (VS Code)

Add to `.vscode/settings.json`:

```json
{
  "yaml.schemas": {
    "https://json.schemastore.org/starlake.json": [
      "metadata/**/*.sl.yml",
      "**/metadata/**/*.sl.yml"
    ]
  }
}
```

---

## Troubleshooting

### 1. Schema Validation Errors

**Error:** `Missing required property: version`

**Fix:** Always include `version: 1` at the top of configuration files.

### 2. Connection Failures

**Error:** `Connection refused to postgres:5432`

**Check:**

- Network connectivity: `telnet postgres 5432`
- Credentials in `env.sl.yml`
- JDBC driver availability in classpath

### 3. Write Strategy Conflicts

**Error:** `Key column 'order_id' not found`

**Fix:** Ensure key columns exist in attributes:

```yaml
writeStrategy:
  type: UPSERT_BY_KEY
  key: ["order_id"] # Must be in attributes list

attributes:
  - name: "order_id" # Must exist
    type: "long"
    required: true
```

### 4. S3 Access Issues

**Error:** `Status Code: 403; Error Code: AccessDenied`

**Check:**

- S3 credentials are correct
- Endpoint URL format: `http://host:port` (no trailing slash)
- Bucket permissions allow read/write
- S3 path style: `path` vs `virtual-hosted`

### 5. Partition Column Mismatch

**Error:** `Partition column 'date' not found in schema`

**Fix:** Partition columns must exist in attributes:

```yaml
sink:
  partition:
    - "order_date"

attributes:
  - name: "order_date" # Must exist
    type: "date"
    required: true
```

---

## Resources

- **JSON Schema**: https://www.schemastore.org/starlake.json
- **Starlake Documentation**: https://docs.starlake.ai
- **GitHub**: https://github.com/starlake-ai/starlake
- **Examples**: https://github.com/starlake-ai/starlake-examples
- **Starlake Airflow**: https://github.com/starlake-ai/starlake-airflow
- **Starlake Dagster**: https://github.com/starlake-ai/starlake-dagster

---

## Version History

- **1.0.0** (2026-02-06): Initial version with core patterns and JSON Schema reference
- **2.0.0** (2026-02-06): Comprehensive update with complete environment variables catalog, all connection types, adaptative write strategies, complete attribute types, expectations framework, metrics, extract configuration, DAG patterns, and production-ready examples
- **3.0.0** (2026-03-04): Redistributed domain-specific content to specialized skills. Config now focuses on transversal concerns (env vars, app structure, types, storage, best practices, troubleshooting)
