---
name: starflow-orchestration-design
description: 'Design orchestration DAGs for scheduling and managing data pipeline execution. Use when the user says "design orchestration" or "create DAG configuration".'
---

# Orchestration Design

## Overview

Guides the design of orchestration workflows that schedule and manage pipeline execution. Produces Starlake DAG configuration files that generate Airflow or Dagster Python code, along with scheduling, dependency, retry, and alerting strategies.

**Role Guidance:** Act as a Platform Engineer with expertise in workflow orchestration, Airflow/Dagster, and Starlake's DAG generation system.

**Design Rationale:** Orchestration code should be generated, not hand-written. Starlake derives task dependencies from SQL references and generates DAG code from YAML configuration + Jinja2 templates. This approach eliminates orchestration bugs caused by manually maintained dependency lists.

## Steps

### Step 1: Context Loading
1. Load available artifacts:
   - `{implementation_artifacts}/pipeline-spec-*.md`
   - `{implementation_artifacts}/transform-design-*.md`
2. Identify all pipelines that need orchestration.

### Step 2: DAG Inventory
Group pipeline tasks into logical DAGs:
| DAG Name | Schedule | Trigger | Tasks | SLA |
|----------|----------|---------|-------|-----|
| `dag_daily_sales` | `0 6 * * *` | Cron | extract_orders, load_orders, transform_daily_agg | 8 AM |
| `dag_realtime_events` | N/A | File sensor | load_events | 15 min |

### Step 3: Scheduling Strategy
For each DAG, define:
- **Trigger type**: Cron schedule, file sensor, ACK file sensor, API trigger, or dependency-based
- **Schedule expression**: Cron format for time-based triggers
- **Catchup policy**: Whether to backfill missed runs
- **Concurrency**: Max parallel task execution
- **Timeout**: Maximum DAG runtime before alerting
- **Retry policy**: Number of retries and delay between them. Default `retries` is `0` — retries must be opted in explicitly. On the Cloud Run runner, `retry_delay` is overridden per-task by `retry_delay_in_seconds` (default `10s`); tune that option when running on Cloud Run.
- **Pre-load "not ready" sentinel** (Cloud Run only): For load DAGs whose pre-load step waits for files, set `pre_load_not_ready_sentinel_path` to a GCS prefix. Orchestration auto-appends `<domain>/<run_id>.notready` and uses the sentinel to distinguish "files not here yet, retry" from "real error" — keeps the Cloud Run console clean of red "Failed" executions for routine waiting polls. Requires `retries > 0` and a tuned `retry_delay_in_seconds` to define the wait window.

### Step 4: DAG Configuration
Create Starlake DAG definitions:
```yaml
version: 1
dag:
  comment: "Daily sales pipeline - extracts, loads, and transforms sales data"
  template: "dag_standard.py.j2"
  filename: "dag_daily_sales"
  schedule: "0 6 * * *"
  options:
    catchup: false
    dagrun_timeout: 7200
    start_date: "2024-01-01"
    retries: 2
    retry_delay_in_seconds: 300  # on Cloud Run; use retry_delay for other runners
    # Optional: opt-in sentinel for Cloud Run pre-load "not ready" signaling.
    # pre_load_not_ready_sentinel_path: "gs://my-bucket/_sl/preload"
```

### Step 5: DAG Assignment
Document the DAG assignment hierarchy:
1. **Project default**: `application.sl.yml` → `dagRef` (applies to all tasks)
2. **Domain override**: `{domain}/_config.sl.yml` → `dagRef` (applies to domain tasks)
3. **Task override**: `{task}.sl.yml` → `dagRef` (applies to specific task)

### Step 6: Monitoring & Alerting
- Define SLA miss alerts per DAG
- Configure failure notification channels (email, Slack, PagerDuty)
- Set up freshness monitoring for critical tables
- Define pipeline health dashboard requirements
- Establish on-call procedures for pipeline failures

### Step 7: Output Generation
Generate:
1. Orchestration design document to `{implementation_artifacts}/orchestration-design-{{project_name}}.md`
2. DAG YAML configurations to `{implementation_artifacts}/dags/`

Run `starlake dag-generate` to produce Airflow/Dagster Python files from the YAML configurations.

## Related Starlake Skills

- Use the `dag-generate` skill for Airflow/Dagster DAG template options
- Use the `dag-deploy` skill for DAG deployment procedures

## Outcome

Complete orchestration design with DAG configurations, scheduling strategies, and monitoring plans — ready for deployment to Airflow or Dagster.
