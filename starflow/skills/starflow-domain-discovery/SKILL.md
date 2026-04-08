---
name: starflow-domain-discovery
description: 'Discover and document data domains, sources, and ownership. Use when the user says "discover data domains" or "map data sources".'
---

# Data Domain Discovery

## Overview

Guides the user through identifying and documenting all data domains in their organization, mapping data sources to domains, establishing ownership, and defining the boundaries of the data landscape. This produces a domain map that serves as the foundation for all subsequent pipeline design.

**Role Guidance:** Act as a Business Data Analyst with expertise in data governance and domain-driven design.

**Design Rationale:** Domain discovery must happen before any pipeline work. Without clear domain boundaries and ownership, pipelines become tangled and ungovernable. This workflow follows Starlake's domain-based organization where each domain maps to a database schema/namespace.

## Steps

### Step 1: Context Gathering
1. Ask the user about their organization's data landscape:
   - What business functions generate or consume data?
   - What existing databases, data warehouses, or data lakes exist?
   - What are the key business processes that depend on data?
2. Document initial understanding.

### Step 2: Domain Identification
1. Group related data entities into logical domains (e.g., `sales`, `inventory`, `customers`, `finance`).
2. For each domain, identify:
   - **Name**: kebab-case identifier (maps to Starlake domain directory)
   - **Description**: Business purpose of this domain
   - **Owner**: Team or person responsible
   - **Sources**: Where data originates (databases, APIs, files, streams)
   - **Consumers**: Who/what uses this data downstream
3. Present domain map for review.

### Step 3: Source Cataloging
For each identified source within each domain, document:
| Field | Description |
|-------|-------------|
| Source name | Unique identifier |
| Source type | JDBC, file (CSV/JSON/XML/Parquet), API, stream (Kafka) |
| Connection | Database/endpoint details |
| Format | DSV, JSON, XML, POSITION, Parquet, Avro |
| Refresh frequency | Real-time, hourly, daily, weekly, on-demand |
| Volume | Approximate row count and growth rate |
| Schema stability | Stable, evolving, unpredictable |

### Step 4: Dependency Mapping
1. Map data flows between domains (which domains feed into which).
2. Identify shared reference data (e.g., country codes, product catalogs).
3. Flag circular dependencies or tight coupling.
4. Document the resulting dependency graph.

### Step 5: Output Generation
Generate the domain discovery document and save to `{planning_artifacts}/domain-discovery-{{project_name}}.md` using the template structure.

## Outcome

A comprehensive domain discovery document that maps all data domains, sources, ownership, and dependencies — ready to inform data architecture design and Starlake domain configuration.