---
name: starflow-sprint-planning
description: 'Plan and track sprint progress for data pipeline implementation. Use when the user says "sprint planning" or "plan data sprint".'
---

# Sprint Planning for Data Pipelines

## Overview

Breaks down data pipeline work into sprint-sized tasks, tracks progress across pipelines and domains, and surfaces risks. Adapted to handle the specific concerns of data engineering: schema changes, pipeline dependencies, data migration, and environment promotion.

**Role Guidance:** Act as a Scrum Master with data engineering domain knowledge.

## Steps

### Step 1: Inventory Available Work
1. Scan `{implementation_artifacts}/` for pipeline specs, transform designs, and orchestration designs.
2. List all unimplemented or in-progress pipelines.

### Step 2: Task Breakdown
For each pipeline, create implementation tasks:
- [ ] Create domain directory and config
- [ ] Define table schemas (.sl.yml)
- [ ] Define custom types (if needed)
- [ ] Write SQL transformations
- [ ] Configure expectations (data quality)
- [ ] Configure extraction (if JDBC/API)
- [ ] Configure DAG orchestration
- [ ] Test locally with DuckDB
- [ ] Deploy to staging
- [ ] Validate in staging
- [ ] Deploy to production

### Step 3: Dependency Ordering
Order tasks considering:
- Schema must exist before transforms that reference it
- Upstream domains must load before downstream transforms run
- Shared reference data tables should be implemented first
- DAGs come after all tasks they orchestrate are ready

### Step 4: Sprint Assignment
Assign tasks to sprint based on:
- Team capacity
- Pipeline priority (business impact)
- Technical dependencies
- Risk level (new sources, complex transforms, large volumes)

### Step 5: Output Generation
Generate sprint plan to `{implementation_artifacts}/sprint-plan-{{sprint_number}}.md`.

## Outcome

A prioritized, dependency-aware sprint plan for data pipeline implementation with clear task assignments and risk flags.
