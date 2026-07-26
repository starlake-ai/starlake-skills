---
name: dag-template-generate
description: Generate a custom Jinja2 DAG template and its YAML DAG configuration from a natural-language pipeline description (Airflow, Dagster, Snowflake)
---

# DAG Template Generate Skill

Turns a natural-language pipeline description into two artifacts for a Starlake project:

1. A **YAML DAG configuration** (`metadata/dags/{name}.sl.yml`) — the input `starlake dag-generate` consumes. It selects the template, names the output file(s), and passes options. Which domains/tables (load) or tasks (transform) end up in the generated DAG — and the lineage JSON embedded in it — is determined by the project's `dagRef` assignments and schedules, not by this file.
2. Optionally, a **custom Jinja2 DAG template** placed under `metadata/dags/templates/{load|transform}/` — only when the built-in templates don't cover the need (e.g., extra orchestrator-native tasks such as an email notification).

Prefer a built-in template whenever it fits; write a custom template only for genuinely custom behavior.

## Workflow

1. **Gather requirements** (ask only for what's missing, then generate everything in one turn):
   - Orchestrator: `airflow`, `dagster`, or `snowflake`
   - DAG kind: **load** (`scheduled_table`) or **transform** (`scheduled_task`)
   - Execution environment: `shell`, `cloud_run`, `dataproc`, `fargate` (airflow/dagster) or `sql` (snowflake)
   - Scope: which domains/tables (load) or transform tasks — this maps to `dagRef` assignments, not to the DAG config file
   - Schedule: cron or `schedulePresets` name (5-field cron only — Snowflake `USING CRON` cannot run `@daily` aliases or 6-field seconds crons)
   - Pre-load strategy (load only): `imported`, `ack`, `pending`, or `none`
   - Extra tasks beyond `sl_*` actions (email, external trigger, ...) → custom template
2. **Read the target template's header comments** — they are the authoritative option list for that template.
3. **Write `metadata/dags/{name}.sl.yml`** using only header-documented options; warn on any option not documented by the template (unknown keys are silently ignored at runtime).
4. **Wire the scope**: set `application.dagRef.load/transform` (project default) or per-domain/table/task `dagRef` overrides; set table `metadata.schedule` / task cron.
5. If a custom template is needed, **generate it** (naming + directory rules below) and point `dag.template` at it.
6. **Validate**: `starlake dag-generate --outputDir /tmp/dags --clean` must render without error.

## YAML DAG configuration (`metadata/dags/{name}.sl.yml`)

The complete schema — there are no other top-level keys:

```yaml
version: 1
dag:
  comment: "dag for loading all {{domain}} tables"      # description; may use Jinja vars
  template: "load/airflow__scheduled_table__shell.py.j2" # REQUIRED — must resolve (see lookup order)
  filename: "airflow_{{domain}}_tables.py"               # REQUIRED — output name; {{domain}}/{{table}}/{{schedule}} vars control grouping
  options:                                               # free-form string map consumed by the template/framework
    sl_env_var: "{\"SL_ROOT\": \"{{SL_ROOT}}\", \"SL_ENV\": \"DUCKDB\"}"
    SL_STARLAKE_PATH: "starlake"
    pre_load_strategy: "imported"
    tags: "{{domain}}"
    retry_delay: "10"
```

Rules enforced by `starlake validate` / dag-generate:
- `template` and `filename` are required; neither may contain `..`; absolute paths (leading `/`) are rejected unless they point inside the project root — `SL_STARLAKE_PATH` option values are always exempt.
- Option values must be non-empty strings.
- Scheduling, catchup, pools etc. are NOT top-level keys — they are `options` entries when the chosen template documents them (e.g. `catchup`, `start_date`, `tags`), or they come from table/task metadata (schedule/cron).

`filename` Jinja variables control output granularity: `{{domain}}` → one file per domain, `{{table}}` → one per table, `{{schedule}}` → one per schedule group.

## How scope, schedule, and lineage are determined

- **DAG assignment hierarchy** (lowest → highest priority): `application.dagRef.load/transform` in `metadata/application.sl.yml` → domain `load.metadata.dagRef` in `metadata/load/{domain}/_config.sl.yml` → table `table.metadata.dagRef` in `metadata/load/{domain}/{table}.sl.yml` / transform `task.dagRef`. A DAG config only generates DAGs for the domains/tables/tasks that reference it (directly or by inheritance).
- **Load DAGs**: tables are grouped by their `metadata.schedule` (a cron or a `schedulePresets` name from `application.sl.yml`, e.g. `hourly: "0 * * * *"`). Each group renders into the template as a `StarlakeSchedule(name, cron, domains=[...tables...])` literal — that literal is the DAG's scope and drives data-aware scheduling.
- **Transform DAGs**: the task dependency graph (lineage) is computed by the CLI from SQL analysis and embedded in the generated DAG as JSON (`StarlakeDependencies(dependencies="""...""")`). The template's `cron` render var comes from the task-level cron; without a cron, orchestrator-native dataset/asset triggering is used (`dataset_triggering_strategy`: `any` (default) or `all`; note Dagster additionally requires all monitored assets to have materialized at least once, and Snowflake is ALL-only by design).
- **Pre-load pairing**: with `pre_load_strategy: "imported"` the generated pipeline chains `sl_pre_load >> sl_import >> sl_load`; with `ack` it waits on `global_ack_file_path` (with `ack_wait_timeout`); `pending` checks the pending area; `none` skips pre-load entirely.
- Write strategies (`APPEND`, `OVERWRITE`, `UPSERT_BY_KEY`, `SCD2`, ...) are table/task metadata (`writeStrategy`) applied by the Starlake CLI — they are never set in DAG configs or templates.

## Template naming and placement (mandatory)

- Name: `{orchestrator}__scheduled_{table|task}__{env}.py.j2` — exactly three `__`-separated parts. `scheduled_table` = load, `scheduled_task` = transform; `{env}` is the runner (`shell`, `cloud_run`, `dataproc`, `fargate`, `sql`).
- Directory: the file MUST sit in a `load/` or `transform/` parent directory matching its kind. Custom templates go in `metadata/dags/templates/load/` or `metadata/dags/templates/transform/` (note: `templates`, plural).
- Why the convention is mandatory: `dag-generate` derives the orchestrator from the filename segment before the first `__`, and the template listing (Starlake API) parses every custom template's name and directory — ONE misnamed or misplaced `.j2` file under `metadata/dags/templates/` makes the whole template listing fail for the project.
- Lookup order for `dag.template`: absolute path → `metadata/dags/templates/{template}` → CLI built-ins. A custom template with the same name as a built-in shadows it.
- Files starting with `_` are snippets, invisible to template listings.

## Template anatomy

A custom template is a header + three includes (or an inlined body):

```jinja2
# <one-line purpose> and requires the following dag generation options set:
#
# - my_option(default): description of the option [OPTIONAL]
# - my_required_option: description [REQUIRED]
#
{% include 'templates/dags/__starlake_airflow_orchestrator.py.j2' %}
{% include 'templates/dags/__starlake_shell_execution.py' %}
{% include 'templates/dags/load/__scheduled_table_tpl.py.j2' %}
```

- **Header comments are a machine-readable API** (parsed by the Starlake CLI and served by the Starlake API). Grammar per line: starts with `# - `; key first, optional `(default)` suffix; then EXACTLY ONE colon; then the description containing `[OPTIONAL]` or `[REQUIRED]` (trailing text after the tag is allowed). A second colon anywhere on the line makes the option invisible — never put colons in descriptions. A `# - ` line with NO colon at all is worse: it crashes the template parser and breaks template listing for the whole project — never use `# - ` for plain bullets in the header block. Document EVERY option your template consumes, including the ones inherited from the snippets you include.
- **Include paths resolve against the metadata root and the CLI classpath — never against the template's own directory.** Always write includes with their full built-in paths (`templates/dags/__starlake_airflow_orchestrator.py.j2`, `templates/dags/load/__scheduled_table_tpl.py.j2`, ...): they resolve from the CLI's bundled resources even when your custom template lives in `metadata/dags/templates/`.
- **Orchestrator snippet** (`__starlake_airflow_orchestrator.py.j2`, `__starlake_dagster_orchestrator.py.j2`, `__starlake_snowflake_orchestrator.py.j2`): includes the shared `__common__` (description/template/options literals) and sets `orchestrator = StarlakeOrchestrator.<AIRFLOW|DAGSTER|SNOWFLAKE>`. The Airflow snippet additionally wires `access_control` and `default_dag_args`.
- **Execution snippet** (`__starlake_shell_execution.py`, `__starlake_cloud_run_execution.py`, ... or `__starlake_sql_execution.py.j2` for Snowflake): sets `execution_environment`.
- **Pipeline body**: include the shared `load/__scheduled_table_tpl.py.j2` / `transform/__scheduled_task_tpl.py.j2` when the standard pipeline fits; inline a modified copy when you need extra tasks (see below). Note the Snowflake load built-in does not use the shared body — start from its source when customizing Snowflake.

## Built-in template options (authoritative excerpts)

Always re-read the actual header of the template you extend — it is the single source of truth and evolves with the framework. Key options by template family (as of starlake-airflow 0.6.13 / starlake-dagster 0.5.9):

- `load/airflow__scheduled_table__shell.py.j2`: `sl_env_var`, `SL_STARLAKE_PATH(starlake)`, `pre_load_strategy(none)` — one of `imported, ack, pending, none`, `global_ack_file_path`, `ack_wait_timeout(3600)` (ignored in sensor mode), `pre_load_sensor(false)`, `pre_load_poke_interval(300)`, `pre_load_timeout(3600)`, `pre_load_sensor_soft_fail(false)`, `pre_load_not_ready_sentinel_path`, `tags`, `start_date`, `end_date`, `retries(1)`, `retry_delay(300)`, `default_dag_args`, `sl_include_env_vars`.
- `load/dagster__scheduled_table__shell.py.j2`: the same core set minus the Airflow-only options (`tags`, `start_date`/`end_date`, `default_dag_args`, `sl_include_env_vars`): `sl_env_var`, `SL_STARLAKE_PATH(starlake)`, `pre_load_strategy(none)`, `global_ack_file_path`, `ack_wait_timeout(3600)`, `pre_load_sensor(false)` (in-op poke loop), `pre_load_poke_interval(300)`, `pre_load_timeout(3600)`, `pre_load_sensor_soft_fail(false)`, `pre_load_not_ready_sentinel_path`, `retries(1)`, `retry_delay(300)`.
- `transform/airflow__scheduled_task__shell.py.j2`: the pre-load options do NOT apply here (`pre_load_strategy`, `global_ack_file_path`, `ack_wait_timeout` and the `pre_load_*` sensor/sentinel options are load-only — putting them on a transform DAG config does nothing). Transform-specific options: `run_dependencies_first(False)`, `catchup(False)`, `data_cycle_enabled(False)`, `data_cycle`, `beyond_data_cycle_enabled(True)`, `optional_dataset_enabled(False)`, `dataset_triggering_strategy(any)` — one of `any, all`, `min_timedelta_between_runs(900)`; plus the common set (`sl_env_var`, `SL_STARLAKE_PATH`, `tags`, dates, `retries`, `retry_delay`, `default_dag_args`, `sl_include_env_vars`).
- `load/snowflake__scheduled_table__sql.py.j2`: `stage_location` [REQUIRED], `sl_incoming_file_stage` [REQUIRED], `warehouse(COMPUTE_WH)`, `timezone(UTC)`, `packages(croniter,python-dateutil,snowflake-snowpark-python)`, `sl_env_var`, `retries(1)`, `retry_delay(300)`.

Option hygiene: an option key the template never reads is silently ignored (e.g. `load_dependencies` does nothing — the real key is `run_dependencies_first`; `incoming_path` is likewise consumed by nothing). Cross-check every option you emit against the template header and warn the user about unknown keys — even example configs shipped with Starlake projects may carry inert options.

## Adding orchestrator-native tasks

When the user needs tasks beyond the `sl_*` actions (send an email, ping an external system, ...), add them with the orchestrator's OWN constructs — they are outside the starlake Python library.

- **Airflow** — inside `with orchestration.sl_create_pipeline(...) as pipeline:` the real Airflow DAG context is active, so any natively instantiated operator attaches to the DAG. To wire it with `>>`/`<<` against starlake tasks, wrap it: `orchestration.sl_create_task(task_id, native_operator_or_taskgroup, pipeline)`. `EmailOperator` import: Airflow 2.x `from airflow.operators.email import EmailOperator`; Airflow 3.x `from airflow.providers.smtp.operators.smtp import EmailOperator`. Sending email requires a configured SMTP connection (`smtp_default` or the SMTP provider settings) — Airflow admin territory, out of scope here.
- **Dagster** — use **hooks**, not extra ops: `from dagster import success_hook, failure_hook`. A `@success_hook(required_resource_keys={...})`-decorated function can notify on op success; attach hooks to the module's `defs`/job after the orchestration context exits, or use Dagster sensors on the emitted assets. Do NOT inject raw `OpDefinition`s into a starlake Dagster pipeline (the graph is sealed when the pipeline context exits), and do NOT use `sl_create_task` as a native-op surface on Dagster — it does not reach the graph. The hook's side effect (SMTP/Slack) needs a Dagster resource.
- **Snowflake** — no orchestrator-native extra-task surface: pipeline tasks are Snowflake Tasks calling stored procedures. For notifications use Snowflake alerting/error notifications outside the DAG.

Dependency-wiring gotchas:

- `A >> [B, C]` works, but `[A, B] >> C` raises `TypeError` (Python lists have no `>>`) — write fan-in as `C << [A, B]`.
- Guard `skip_or_start` for `None` before wiring (see the built-in templates).
- Do NOT copy `pipeline.sl_dummy_op(...)` from the built-in templates' `post_tasks` block — that method does not exist (the real one is `pipeline.dummy_task(task_id)`); the built-ins only avoid the crash because `post_tasks` defaults to `None`.

## End-to-end example

**User**: "I need an Airflow DAG that loads all `starbake` tables daily on our shell runner. Files land pre-staged, so use the imported pre-load strategy, and email data-team@acme.com when the load finishes."

**Step 1 — scope + schedule** (project metadata, not the DAG config): `application.dagRef.load: "starbake_load_notify"`; tables inherit `schedule: "daily"` from `metadata/load/starbake/_config.sl.yml` (preset `daily: "0 0 * * *"`).

**Step 2 — YAML DAG configuration** — `metadata/dags/starbake_load_notify.sl.yml`:

```yaml
version: 1
dag:
  comment: "daily load of all {{domain}} tables with email notification"
  template: "load/airflow__scheduled_table__notify.py.j2"
  filename: "airflow_{{domain}}_tables.py"
  options:
    sl_env_var: "{\"SL_ROOT\": \"{{SL_ROOT}}\"}"
    SL_STARLAKE_PATH: "starlake"
    pre_load_strategy: "imported"
    tags: "{{domain}}"
    retry_delay: "10"
    notify_email: "data-team@acme.com"
```

**Step 3 — custom template** — `metadata/dags/templates/load/airflow__scheduled_table__notify.py.j2`. The standard shell load template plus one native `EmailOperator` after the loads. The header is the built-in template's full option block (the composed snippets and job still consume all of those options) plus the new `notify_email` line. The body is the built-in `load/__scheduled_table_tpl.py.j2` with the email task added inside the pipeline context (native operators auto-attach to the DAG there; `orchestration.sl_create_task` wraps them so `>>`/`<<` wiring works):

```jinja2
# This template executes individual bash jobs and sends a completion email, and requires the following dag generation options set:
#
# - sl_env_var: starlake variables specified as a map in json format - at least the root project path SL_ROOT should be specified [OPTIONAL]
# - SL_STARLAKE_PATH(starlake): the path to the starlake executable [OPTIONAL]
# - pre_load_strategy(none): The optional pre-load strategy to use to conditionaly load a domain, one of imported, ack, pending or none (if not set, the default 'none' strategy will be used) [OPTIONAL]
# - global_ack_file_path: when the domain preloading strategy has been set to 'ack', the path to the global ack file [OPTIONAL]
# - ack_wait_timeout(3600): when the domain preloading strategy has been set to 'ack', the timeout in seconds to wait for the ack file (ignored in sensor mode) [OPTIONAL]
# - pre_load_sensor(false): when true, the pre-load task is built as a BashSensor (reschedule mode) that pokes 'starlake preload' until files arrive [OPTIONAL]
# - pre_load_poke_interval(300): seconds between two pokes in sensor mode [OPTIONAL]
# - pre_load_timeout(3600): wall-clock timeout in seconds for the pre-load sensor; on timeout downstream loads are skipped [OPTIONAL]
# - pre_load_sensor_soft_fail(false): when true, a sensor timeout marks the sensor SKIPPED instead of FAILED [OPTIONAL]
# - pre_load_not_ready_sentinel_path: opt-in pre-load not-ready sentinel parent prefix (an ABSOLUTE local path, requires starlake CLI 1.5.15 or newer) - a zero-byte marker under <prefix>/<domain>/ signals 'files not ready' (consumed by the task's own bash wrapper) and a failed CLI now fails the task instead of reading as 'nothing to load' [OPTIONAL]
# - tags: a list of tags to be applied to the dag [OPTIONAL]
# - start_date: the start date of the dag (eg. 2022-01-01) [OPTIONAL]
# - end_date: the end date of the dag (eg. 2024-12-31) [OPTIONAL]
# - retries(1): the number of retries to attempt before failing the task [OPTIONAL]
# - retry_delay(300): the delay between retries in seconds [OPTIONAL]
# - default_dag_args: the default dag arguments specified as a map in json format [OPTIONAL]
# - sl_include_env_vars: the default os environment variables to include (GOOGLE_APPLICATION_CREDENTIALS,AWS_KEY_ID,AWS_SECRET_KEY by default) [OPTIONAL]
# - notify_email: the recipient of the completion email [REQUIRED]
#
{% include 'templates/dags/__starlake_airflow_orchestrator.py.j2' %}
{% include 'templates/dags/__starlake_shell_execution.py' %}
from ai.starlake.job import StarlakePreLoadStrategy, StarlakeJobFactory

import os

import sys

sl_job = StarlakeJobFactory.create_job(
    filename=os.path.basename(__file__),
    module_name=f"{__name__}",
    orchestrator=orchestrator,
    execution_environment=execution_environment,
    options=options
)

from ai.starlake.common import sanitize_id
from ai.starlake.orchestration import StarlakeSchedule, StarlakeDomain, StarlakeTable, OrchestrationFactory

from ai.starlake.airflow import StarlakeAirflowOptions
from airflow.operators.email import EmailOperator  # Airflow 3.x: from airflow.providers.smtp.operators.smtp import EmailOperator

notify_email = StarlakeAirflowOptions.get_context_var(var_name="notify_email", options=options)

schedules= [{% for schedule in context.schedules %}
    StarlakeSchedule(
        name='{{ schedule.schedule }}',
        cron={% if schedule.cron is not none %}'{{ schedule.cron }}'{% else %}None{% endif %},
        domains=[{% for domain in schedule.domains %}
            StarlakeDomain(
                name='{{ domain.final_name }}',
                final_name='{{ domain.final_name }}',
                tables=[{% for table in domain.tables %}
                    StarlakeTable(
                        name='{{ table.final_name }}',
                        final_name='{{ table.final_name }}'
                    ){% if not loop.last  %},{% endif %}{% endfor %}
                ]
            ){% if not loop.last  %},{% endif %}{% endfor %}
    ]){% if not loop.last  %},{% endif %}{% endfor %}
]

with OrchestrationFactory.create_orchestration(job=sl_job) as orchestration:

    def generate_pipeline(schedule: StarlakeSchedule):
        if len(schedules) == 1:
            schedule.name = None
        with orchestration.sl_create_pipeline(
            schedule=schedule,
        ) as pipeline:

            schedule       = pipeline.schedule
            if schedule.name:
                schedule_name = sanitize_id(schedule.name)
            else:
                schedule_name = None

            start = pipeline.start_task()
            if not start:
                raise Exception("Start task not defined")

            def generate_load_domain(domain: StarlakeDomain):
                if schedule_name:
                    name = f"{domain.name}_{schedule_name}"
                else:
                    name = domain.name

                with orchestration.sl_create_task_group(group_id=sanitize_id(name), pipeline=pipeline) as ld:
                    pre_load_strategy = pipeline.pre_load_strategy

                    def pre_load(pre_load_strategy: StarlakePreLoadStrategy):
                        if pre_load_strategy != StarlakePreLoadStrategy.NONE:
                            with orchestration.sl_create_task_group(group_id=sanitize_id(f'pre_load_{name}'), pipeline=pipeline) as pre_load_tasks:
                                pre_load = pipeline.sl_pre_load(
                                        domain=domain.name,
                                        tables=set([table.name for table in domain.tables]),
                                    )
                                skip_or_start = pipeline.skip_or_start(
                                    task_id=f'skip_or_start_loading_{name}',
                                    upstream_task=pre_load
                                )
                                if pre_load_strategy == StarlakePreLoadStrategy.IMPORTED:
                                    sl_import = pipeline.sl_import(
                                            task_id=f"import_{name}",
                                            domain=domain.name,
                                            tables=set([table.name for table in domain.tables]),
                                        )
                                else:
                                    sl_import = None

                                if skip_or_start:
                                    pre_load >> skip_or_start
                                    if sl_import:
                                        skip_or_start >> sl_import
                                elif sl_import:
                                    pre_load >> sl_import

                            return pre_load_tasks
                        else:
                            return None

                    pld = pre_load(pre_load_strategy)

                    def load_domain_tables():
                        with orchestration.sl_create_task_group(group_id=sanitize_id(f'load_{name}'), pipeline=pipeline) as load_domain_tables:
                            for table in domain.tables:
                                pipeline.sl_load(
                                    task_id=sanitize_id(f'load_{domain.name}_{table.name}'),
                                    domain=domain.name,
                                    table=table.name,
                                )
                        return load_domain_tables

                    ld_tables = load_domain_tables()

                    if pld:
                        pld >> ld_tables

                return ld

            load_domains = [generate_load_domain(domain) for domain in schedule.domains]

            end = pipeline.end_task()

            start >> load_domains
            end << load_domains

            # --- custom: orchestrator-native completion email (outside the starlake library) ---
            notify = orchestration.sl_create_task(
                "notify_success",
                EmailOperator(
                    task_id="notify_success",
                    to=notify_email,
                    subject=f"[starlake] {pipeline.pipeline_id} succeeded",
                    html_content="All starbake tables loaded.",
                ),
                pipeline
            )
            end >> notify

        return pipeline

    pipelines = [generate_pipeline(schedule) for schedule in schedules]
```

**Step 4 — validate**:

```bash
starlake dag-generate --outputDir /tmp/dags --clean
python -c "import ast, pathlib; [ast.parse(p.read_text()) for p in pathlib.Path('/tmp/dags').rglob('*.py')]"
```

## Validation checklist

After generating the artifacts, always verify:

1. `starlake dag-generate --outputDir /tmp/dags --clean` exits 0 and emits the expected file(s) — the CLI renders unknown Jinja variables as EMPTY instead of failing, so a render without error is not enough on its own.
2. Every generated `.py` parses: `python -c "import ast, pathlib; [ast.parse(p.read_text()) for p in pathlib.Path('/tmp/dags').rglob('*.py')]"` — this is what catches typo'd template variables.
3. Every `# - ` header line of a custom template follows the grammar (exactly one colon, `[OPTIONAL]`/`[REQUIRED]` tag).
4. Every option in the YAML DAG config is documented by the target template's header.

## Related Skills

- [dag-generate](../dag-generate/SKILL.md) - Run DAG generation from the DAG configs this skill produces
- [dag-deploy](../dag-deploy/SKILL.md) - Deploy generated DAGs to target directory
- [load](../load/SKILL.md) - Load data (write strategies live in table metadata)
- [transform](../transform/SKILL.md) - Run transform tasks
- [config](../config/SKILL.md) - Configuration reference (environment variables)
- [connection](../connection/SKILL.md) - Database connections referenced by loads/transforms
