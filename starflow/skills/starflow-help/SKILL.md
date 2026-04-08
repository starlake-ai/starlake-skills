---
name: starflow-help
description: 'Analyzes current state and user query to answer Starflow questions or recommend the next workflow. Use when user asks what to do next or asks about Starflow.'
---

# Starflow Help & Navigation

## Overview

Helps users navigate the Starflow framework by analyzing the current project state, available artifacts, and recommending the appropriate next workflow or agent.

**Role Guidance:** Act as a helpful guide who understands the full Starflow framework and Starlake ecosystem.

## Starflow Workflow Phases

### Phase 1: Discovery
Start here when beginning a new data project.
- **starflow-domain-discovery** — Map data domains, sources, and ownership
- **starflow-source-analysis** — Deep-dive into a specific data source

### Phase 2: Architecture
After discovery, design the data platform.
- **starflow-create-data-architecture** — Design layers, engines, governance
- **starflow-schema-design** — Define Starlake-compatible table schemas

### Phase 3: Pipeline Design
With architecture in place, design the pipelines.
- **starflow-create-pipeline-spec** — Full ETL/ELT pipeline specification
- **starflow-transform-design** — Design SQL transformations
- **starflow-orchestration-design** — Design scheduling and DAGs

### Phase 4: Implementation
Build and deploy the pipelines.
- **starflow-dev-pipeline** — Implement pipeline from spec
- **starflow-sprint-planning** — Plan and track sprint progress
- **starflow-code-review** — Review pipeline configuration and SQL

## Available Agents

| Agent | Name | Specialty |
|-------|------|-----------|
| data-analyst | Lea | Domain discovery, source analysis |
| data-architect | Winston | Architecture, schemas, pipeline design |
| data-engineer | Amelia | Pipeline implementation, transforms |
| data-quality-engineer | Quinn | Data quality, lineage, expectations |
| platform-engineer | Max | Orchestration, deployment, operations |

## Starlake Skills Integration

Starflow methodology skills work alongside the Starlake CLI skills. When executing workflow steps, use the relevant Starlake skills for implementation details:

| Starflow Phase | Starlake Skills to Use |
|----------------|----------------------|
| Schema Design | `config` (types reference), `load` (write strategies), `infer-schema` (from files) |
| Pipeline Implementation | `load`, `transform`, `extract-schema`, `extract-data` |
| Data Quality | `expectations` (Jinja2 macros, validation syntax) |
| Lineage Review | `lineage`, `col-lineage`, `table-dependencies`, `acl-dependencies` |
| Orchestration | `dag-generate`, `dag-deploy` |
| Validation | `validate`, `freshness`, `test` |

## How to Navigate

1. Check `{planning_artifacts}/` for existing planning documents.
2. Check `{implementation_artifacts}/` for existing implementation work.
3. Recommend the next logical workflow based on what exists and what's missing.
4. If the user is unsure, suggest starting with domain discovery.

## Outcome

Clear guidance on the appropriate next step in the Starflow workflow.
