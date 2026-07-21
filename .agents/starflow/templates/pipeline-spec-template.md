---
stepsCompleted: []
inputDocuments: []
date: {{system-date}}
author: {{user_name}}
pipeline_name: {{pipeline_name}}
domain: {{domain_name}}
status: draft        # draft → ready-for-dev → in-progress → done (ready-for-review after an unattended run)
scale: standard      # light | standard | deep (set in step-01)
risks: []
sign_off: false
autoDecisions: []    # populated only in unattended mode: {step, question, decision}

# Per-step state (set as the workflow progresses)
business_objective: ''
sla: ''
source_class: ''      # jdbc | rest | file | stream | mixed
load_tables: []
transform_tasks: []
dag_name: ''
schedule: ''
connections: []
---

# Pipeline Specification: {{pipeline_name}}

## Overview
- **Domain:** {{domain_name}}
- **Business Objective:**
- **SLA:**
- **Schedule:**
- **Engine:** {{default_engine}} (dev) → {{target_engine}} (prod)
- **Source class:**

## Extract

<!-- step-02 fills this. JDBC / REST / file / stream blocks below. -->

## Load

### Table: <table_name>
- **Domain:**
- **File Pattern:** `<regex>`
- **Write Strategy:** APPEND / OVERWRITE / UPSERT_BY_KEY / SCD2 (with reason)
- **Format:** DSV / JSON / XML / Parquet

#### Schema
| Attribute | Type | Required | Privacy | Description |
|-----------|------|----------|---------|-------------|

#### Expectations
| Check | SQL | Severity |
|-------|-----|----------|

## Transform

### Task: <task_name>
- **Source Tables:**
- **Target Table:** {domain}.{table}
- **Write Strategy:**
- **Dependencies:** (auto-inferred from SQL; document explicitly)

```sql
-- SQL transformation
```

#### Expectations
| Check | SQL | Severity |
|-------|-----|----------|

### Transform DAG
<!-- bulleted list: task → depends on [task1, task2] -->

## Orchestrate

### DAG: <dag_name>
- **Schedule:** `<cron>`
- **Template:** dag_standard.py.j2
- **Tasks:**
- **Timeout:**
- **Retry Policy:**
- **Alerts:**
- **Upstream DAGs:**

## Environment Configuration

### Connections (env.sl.yml + env.PROD.sl.yml overlays)

| Name | Type | Dev | Staging | Production |
|------|------|-----|---------|------------|

### Required env vars

| Env var | Used by | Where to source |
|---------|---------|-----------------|

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|

## Ready-for-Dev Checklist
- [ ] All connection refs resolve to a defined connection
- [ ] Every load table has at least one expectation
- [ ] Every transform task has at least one expectation
- [ ] DAG schedule satisfies the SLA
- [ ] No secrets inlined anywhere in the spec
- [ ] Risks reviewed with owner
