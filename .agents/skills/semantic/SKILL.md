---
name: semantic
description: Author semantic model YAML in metadata/semantic for BI tools and AI agents - logical tables, dimensions, facts, metrics, relationships, and verified queries
---

# Semantic Model Skill

Define the business semantic layer of a Starlake project. Semantic models live as YAML files in `metadata/semantic/` (the folder is created by `bootstrap`) and describe the warehouse in business terms: logical tables, dimensions, facts, metrics, relationships, and verified queries. They are consumed by the Starlake Cockpit's semantic model editor and by AI/BI agents that translate natural-language questions into SQL.

The format is aligned with the Snowflake semantic model specification (the YAML consumed by Cortex Analyst and convertible to native Snowflake semantic views). For vendor-neutral interchange, the same modeling concepts are standardized as **Apache Ossie (Incubating)**, formerly Open Semantic Interchange (OSI). Starlake exports models to Ossie natively: run `starlake semantic-export` (see the `semantic-export` skill), giving every model a portability path to any Ossie-compatible BI tool, query engine, or AI agent.

## File Layout

One model per file in `metadata/semantic/<model_name>.yaml`:

```yaml
name: ecommerce_analytics
description: >
  E-commerce analytics model for customers, orders, and products.
comments: Optional free-text notes
tables: [...]         # logical tables (see below)
relationships: [...]  # joins between logical tables
metrics: [...]        # model-level metrics (cross-table)
verified_queries: [...]
```

## Logical Tables

Each entry in `tables:` maps a physical table to a business view of it:

```yaml
tables:
  - name: orders
    description: >
      Order transactions. Join with customers for complete order analysis.
    base_table:
      database: ANALYTICS_DB
      schema: ECOMMERCE      # the Starlake domain
      table: ORDERS
    dimensions:
      - name: order_status
        description: Current status of the order
        synonyms: ["status"]
        expr: ORDER_STATUS   # physical column or SQL expression
        data_type: TEXT
        is_enum: true
        sample_values: ["Pending", "Shipped", "Delivered"]
      - name: order_id
        expr: ORDER_ID
        data_type: NUMBER
        unique: true
    time_dimensions:
      - name: order_date
        description: Date when the order was placed
        synonyms: ["purchase date"]
        expr: ORDER_DATE
        data_type: DATE
    facts:
      - name: order_total
        description: Total order amount including tax
        synonyms: ["total", "order amount"]
        expr: ORDER_TOTAL
        data_type: NUMBER
        access_modifier: public_access   # or private_access
    metrics:
      - name: avg_order_value
        description: Average order value
        synonyms: ["AOV"]
        expr: AVG(order_total)
        access_modifier: public_access
    filters:
      - name: recent_orders
        description: Orders from the last 30 days
        synonyms: ["Last 30 Days"]
        expr: order_date >= DATEADD(day, -30, CURRENT_DATE())
    primary_key:
      columns: [order_id]
```

Column roles:

- **dimensions**: attributes you group and filter by. Mark low-cardinality ones `is_enum: true`; mark identifier columns `unique: true`.
- **time_dimensions**: date/timestamp columns used for trends. Every model that has a temporal grain should declare at least one.
- **facts**: raw numeric columns at row grain. `expr` may be a computed expression (e.g. `QUANTITY * UNIT_PRICE * (1 - DISCOUNT)`).
- **metrics**: aggregations (`SUM`, `AVG`, `COUNT`) over facts or dimensions. Table-level metrics reference that table's columns; model-level metrics may span tables (e.g. `COUNT(DISTINCT customers.customer_id)`).
- **filters**: named, reusable WHERE fragments with business names.

## Relationships

Declare joins so consumers never guess them:

```yaml
relationships:
  - name: orders_to_customers
    left_table: orders
    right_table: customers
    relationship_columns:
      - left_column: customer_id
        right_column: customer_id
    join_type: left_outer        # inner | left_outer
    relationship_type: many_to_one   # many_to_one | one_to_one
```

Derive these from the foreign keys documented in your load schemas (`table-dependencies` can list them).

## Verified Queries

Curated question-to-SQL pairs that anchor AI agents and serve as onboarding examples:

```yaml
verified_queries:
  - name: top_customers_by_revenue
    question: Who are the top 10 customers by total revenue?
    verified_at: 1704067200          # epoch seconds
    verified_by: Analytics Team
    use_as_onboarding_question: true
    sql: |
      SELECT c.customer_name, SUM(o.order_total) AS total_revenue
      FROM customers c
      JOIN orders o ON c.customer_id = o.customer_id
      GROUP BY c.customer_name
      ORDER BY total_revenue DESC
      LIMIT 10
```

Only include SQL you have actually run against the warehouse: "verified" is a promise, not a label.

## Authoring Rules

- **`expr` must resolve.** Every expression references physical columns of the `base_table` (or, in metrics/filters, names defined in the model). A semantic model referencing a renamed column fails silently at query time: re-check after schema changes.
- **Synonyms are the product.** Analysts and AI agents find columns by business vocabulary (`"AOV"`, `"CLV"`, `"purchase date"`). A model without synonyms and descriptions is a schema dump, not a semantic layer.
- **Never expose PII.** Columns carrying a privacy annotation (`HIDE`, `SHA256`, `MD5`, `AES`) in the load schema must not appear as dimensions, and no real values may appear in `sample_values`. Use `access_modifier: private_access` for sensitive facts (e.g. cost, margin).
- **`sample_values` are illustrative**, not data: 2-3 representative, non-sensitive values that help query generation.
- **Engine-specific blocks**: `cortex_search_service` (per dimension) binds enum search to a Snowflake Cortex service; omit it on other engines. Keep filter/metric SQL portable unless the model is engine-pinned.
- **Keep models per business domain**, mirroring your Starlake domains: one broad model per analytical area beats one giant model of everything.

## Related Skills

- `semantic-export`: export models to the Apache Ossie interchange format
- `bootstrap`: creates the `metadata/semantic/` folder
- `table-dependencies`: lists foreign keys to derive `relationships` from
- `secure`: privacy annotations that dictate what must stay out of the model
- `yml2ddl` / `load`: the physical schemas the model maps onto
