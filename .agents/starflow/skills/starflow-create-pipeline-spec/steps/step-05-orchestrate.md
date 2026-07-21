---
dag_name: ''       # set in this step
schedule: ''       # set in this step
---

# Step 5: Orchestration Specification

## Rules

- Do **not** hand-write Airflow / Dagster code. Define the inputs and let `dag-generate` produce the DAG file.
- Schedule must be expressible as a cron expression OR a sensor trigger; if neither fits, the answer is "event-driven via file/Kafka sensor", not "custom Python operator".

### Scale

- **light**: derive the trigger from the SLA and take the documented defaults (catchup `false`, `retries: 2`, `retry_delay: 5m`, timeout 2× run time) without asking. Ask only for the alert channel. Then **skip this step's checkpoint**: continue straight into step-06 and confirm orchestration + environment together at the step-06 checkpoint.
- **deep**: additionally do the SLA math out loud (expected runtime + retry budget vs SLA window, with numbers), and ask about backfill needs; if catchup is `true`, document the backfill window and idempotence argument.

## Preconditions

- Step 4 complete (or skipped with explicit "load only").

## Instructions

1. **DAG name**: `dag_{{pipeline_name}}_{{cadence}}` (e.g. `dag_orders_daily`).
2. **Trigger**: pick one:
   - **Schedule**: cron expression mapped from the SLA in step 1 (e.g. SLA "daily by 6 AM UTC" → `0 6 * * *`).
   - **File sensor**: filename pattern + landing path. Use when extract is file-based.
   - **Event / Kafka sensor**: topic + watermark.
3. **Catchup**: default `false` unless the user explicitly wants historical backfill. Document the reason if `true`.
4. **Timeout**: default 2× expected run time, never longer than the SLA window.
5. **Retry policy**: count, delay (exponential backoff), max delay. Defaults: `retries: 2`, `retry_delay: 5m`, `max_retry_delay: 30m`. Override only with reason.
6. **Alerts**: pager channel(s) for SLA-critical pipelines. List both success-silent and failure-noisy channels.
7. **Dependencies**: upstream DAGs that must complete first.

Write under `## Orchestrate`:

```yaml
version: 1
dag:
  comment: "<one-sentence purpose>"
  template: "dag_template.py.j2"
  filename: "<dag_name>"
  schedule: "<cron or schedule_interval keyword>"
  options:
    catchup: false
    dagrun_timeout: 7200
    retries: 2
    retry_delay: 300
  alerts:
    on_failure:
      - "<channel>"
  upstream_dags:
    - "<other_dag>"
```

If the trigger is a sensor, swap `schedule:` for a `sensors:` block per `dag-generate` reference.

Set `dag_name` and `schedule` in this step's frontmatter.

## Save

1. Append `5` to `stepsCompleted`.
2. Save the spec file.

## Checkpoint

> **Orchestration defined:** DAG `{{dag_name}}`, trigger `{{schedule}}`, retries `{{retries}}`, alerts `<channels>`.
>
> Ready to lock down environment configs? (y/n / revise)

**HALT.** Default: `y`. (At `light` scale this checkpoint is skipped: see Scale above.)

## Next

Read fully and follow: `step-06-environment.md`
