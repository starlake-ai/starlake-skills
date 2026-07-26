---
name: dag-create
description: Create a ready-to-deploy one-off orchestration DAG (Airflow or Dagster Python file) from a natural-language pipeline description, composing sl_load, sl_transform, sl_import and sl_pre_load via the starlake-orchestration API
---

# DAG Create Skill

Turns a natural-language pipeline description ("load these tables, run these transforms, on this schedule, for this orchestrator") into ONE complete, deployable Python DAG file built on the `starlake-orchestration` Python API. The output is NOT a Jinja2 template and does not require `starlake dag-generate` — it is a bespoke, hand-deployable DAG.

Use this skill when the user wants a one-off DAG mixing loads and transforms in a single file. For recurring, metadata-driven DAGs regenerated on every schema change, prefer [dag-generate](../dag-generate/SKILL.md) with a DAG config under `metadata/dags/`.

**Respond in a single conversation turn**: read the metadata, then emit the complete DAG file in one reply. Never split the file across turns.

## Prerequisites

- The Starlake project root (`SL_ROOT`) with its `metadata/` directory.
- The orchestrator's starlake package installed where the DAG will run (PyPI): `starlake-airflow>=0.6.1` (Airflow 2 and 3) or `starlake-dagster>=0.5.1`, both pulling `starlake-orchestration>=0.5.1`.
- The Starlake CLI (`starlake`, 1.5.x) reachable from the DAG's execution environment (`SL_STARLAKE_PATH` option, defaults to `starlake` on PATH).
- **Snowflake is not supported by this skill**: the starlake-snowflake executor runs CLI-embedded SQL statements that only `starlake dag-generate` can produce — a hand-written file fails at DAG definition time. For Snowflake, use [dag-generate](../dag-generate/SKILL.md) with the snowflake templates.

## Step 1 — Read the project metadata (never guess)

Derive every configuration value from the project's YAML metadata:

| Read | Derive |
|---|---|
| `metadata/application.sl.yml` | `connectionRef`, `schedulePresets` (name → cron), project-level `dagRef.load` / `dagRef.transform` |
| `metadata/load/{domain}/_config.sl.yml` | domain name, incoming `directory`, domain-level `schedule` (preset name or cron), domain-level `metadata.dagRef` override |
| `metadata/load/{domain}/{table}.sl.yml` | table name, file `pattern`, `metadata.writeStrategy.type`, table-level `schedule` / `dagRef` overrides |
| `metadata/transform/{domain}/{task}.sl.yml` + `.sql` | task name (fully qualified `domain.task`), `writeStrategy`, and upstream references from the SQL `FROM`/`JOIN` clauses |

Rules:

- **Schedules**: resolve preset names (`daily`, `hourly`, …) through `application.schedulePresets`. Tables with a different schedule than the requested one belong in a DIFFERENT pipeline — ask, or generate one pipeline per schedule (they can share one file via `pipelines = [pipeline_a, pipeline_b]`). Always use standard 5-field cron expressions (`@daily` aliases and 6-field crons are not portable).
- **Write strategies** (`APPEND`, `OVERWRITE`, `UPSERT_BY_KEY`, `SCD2`, …) are applied by the Starlake CLI from the table/task YAML. Read them to explain behavior to the user — NEVER pass them to `sl_load`/`sl_transform` (they are not orchestration parameters). Note: load tables declare them under `table.metadata.writeStrategy`, transforms at the top-level `task.writeStrategy`.
- **Transform ordering**: a transform whose SQL reads another transform's sink must run after it (e.g. `kpi.top_customers` reads `kpi.order_summary` → `order_summary >> top_customers`). For complex projects use the [lineage](../lineage/SKILL.md) skill (`starlake lineage`) to compute the ordering instead of parsing SQL by hand.
- **Pre-load strategy**: from the user's request or an existing DAG config (`metadata/dags/*.sl.yml` `options.pre_load_strategy`). Valid values: `imported`, `ack`, `pending`, `none` (strict lowercase). Invalid strings make the job constructor raise — do not invent values.

## Step 2 — Respect the DAG assignment hierarchy

DAG configs are assigned project → domain → table/task (lowest to highest priority): `application.dagRef.load|transform`, then `metadata.dagRef` in the domain `_config.sl.yml`, then `metadata.dagRef` in `{table}.sl.yml` / `dagRef` in `{task}.sl.yml`. See [dag-generate](../dag-generate/SKILL.md) "DAG Reference Assignment".

For a one-off DAG this means:

- Group generated tasks by domain (one task group per domain), tables inside.
- If a requested table/task resolves to an existing generated DAG (any `dagRef` in scope), WARN the user: the table would be scheduled twice (once by the generated DAG, once by this one-off DAG). Proceed only if they confirm.
- Never invent a `dagRef`: a one-off DAG is deployed directly and is not referenced from the YAML metadata.

## Step 3 — Compose the DAG file

Every one-off DAG has the same skeleton (this is the real API of `starlake-orchestration` ≥ 0.5.1, not pseudo-code):

```python
from ai.starlake.job import StarlakeOrchestrator, StarlakeExecutionEnvironment, StarlakeJobFactory

orchestrator = StarlakeOrchestrator.AIRFLOW          # or DAGSTER
execution_environment = StarlakeExecutionEnvironment.SHELL

description = "<one-line pipeline description>"

options = {
    'sl_env_var': '{"SL_ROOT": "<project root>", "SL_ENV": "<env>"}',
    'SL_STARLAKE_PATH': 'starlake',
    'pre_load_strategy': 'imported',   # imported | ack | pending | none
    'tags': '<tags>',
    'retries': 1,
    'retry_delay': 300,
}

import os
sl_job = StarlakeJobFactory.create_job(
    filename=os.path.basename(__file__),
    module_name=f"{__name__}",
    orchestrator=orchestrator,
    execution_environment=execution_environment,
    options=options,
)

from ai.starlake.common import sanitize_id
from ai.starlake.orchestration import StarlakeSchedule, StarlakeDomain, StarlakeTable, OrchestrationFactory

with OrchestrationFactory.create_orchestration(job=sl_job) as orchestration:
    with orchestration.sl_create_pipeline(schedule=...) as pipeline:
        ...  # tasks and dependencies (see composition rules)

pipelines = [pipeline]   # REQUIRED module-level export
```

### Composition rules (dependency ordering)

1. Every pipeline starts with `start = pipeline.start_task()` and ends with `end = pipeline.end_task()`.
2. **IMPORTED pre-load chain is mandatory and ordered**: `sl_pre_load >> skip_or_start >> sl_import >> (loads)`. NEVER chain `sl_pre_load` directly to `sl_load` when the strategy is `imported` — the import (stage) step moves the files the load consumes:

   ```python
   pre_load = pipeline.sl_pre_load(domain=domain, tables=tables)
   gate = pipeline.skip_or_start(task_id=f"skip_or_start_loading_{domain}", upstream_task=pre_load)
   imp = pipeline.sl_import(task_id=f"import_{domain}", domain=domain, tables=tables)
   if gate:
       pre_load >> gate >> imp
   else:
       imp << pre_load
   ```

   (`skip_or_start` may return `None` on some orchestrators — always guard.) With strategy `none`, omit the whole pre-load group. With `ack`, also set `global_ack_file_path` and `ack_wait_timeout` in `options`.
3. One `sl_load(task_id=..., domain=..., table=...)` per table, grouped per domain with `orchestration.sl_create_task_group(group_id=sanitize_id(name), pipeline=pipeline)`.
4. One `sl_transform(task_id=..., transform_name="domain.task")` per transform, chained in lineage order.
5. Chaining: `a >> b >> c` works; fan-out `a >> [b, c]` works; **fan-in MUST be `c << [a, b]`** — `[a, b] >> c` raises `TypeError` (Python lists have no `__rshift__`).
6. Use `pipeline.dummy_task(task_id=...)` for join points (NOT `sl_dummy_op`, which does not exist on the pipeline).
7. **Snowflake**: never generate a one-off Snowflake DAG. The starlake-snowflake executor needs CLI-embedded module context (`statements`, `json_context`) that only `starlake dag-generate` produces — without it the file raises `ValueError` at definition time. Route the user to [dag-generate](../dag-generate/SKILL.md).
8. Pass domain/table/task names exactly as they appear in the YAML metadata — they become the CLI references.
9. `StarlakeSchedule.name` suffixes the DAG id: `pipeline_id = <filename stem>_<name>` (lowercased). Pass `name=None` when you want the DAG id to be exactly the filename stem.
10. One file may export several pipelines (e.g. one per schedule): `pipelines = [pipeline_a, pipeline_b]` — the loader returns the whole list.

## Step 4 — What the generated tasks execute (CLI contract)

Each `sl_*` task shells out to the Starlake CLI with arguments built by the framework — never hand-write these commands in the DAG:

| Pipeline call | CLI command executed |
|---|---|
| `sl_import(domain="starbake", tables={"customers","orders"})` | `starlake stage --domains starbake --tables customers,orders --options ...` |
| `sl_pre_load(domain="starbake", tables=...)` (strategy `imported`) | `starlake preload --domain starbake --tables ... --strategy imported --options SL_RUN_MODE=main,SL_LOG_LEVEL=info` |
| `sl_load(domain="starbake", table="orders")` | `starlake load --domains starbake --tables orders` |
| `sl_transform(transform_name="kpi.order_summary")` | `starlake transform --name kpi.order_summary` |

Environment for these commands comes from the `sl_env_var` option (JSON map — at minimum `SL_ROOT`); the executable path from `SL_STARLAKE_PATH`.

## Options reference (job `options` dict)

- `sl_env_var`: JSON map of Starlake env vars — at least `SL_ROOT` [RECOMMENDED]
- `SL_STARLAKE_PATH` (default `starlake`): path to the starlake executable [OPTIONAL]
- `pre_load_strategy` (default `none`): `imported` | `ack` | `pending` | `none` [OPTIONAL]
- `global_ack_file_path`, `ack_wait_timeout`: required companions of the `ack` strategy [OPTIONAL]
- `retries` (default 1), `retry_delay` (default 300 s) [OPTIONAL]
- Airflow only: `tags` (space-separated), `start_date`, `end_date`, `catchup`, `default_dag_args` (JSON map), `sl_include_env_vars` [OPTIONAL]

These are the same options documented in the header comments of the bundled dag-generate templates — they are the option API shared by generated and one-off DAGs. The options dict is a free-form map: a key the framework never reads is **silently ignored** (e.g. `load_dependencies` does nothing — the real key is `run_dependencies_first`). Only emit documented keys and warn the user about any unknown ones.

## Validate the generated DAG

Always finish by telling the user how to prove the DAG is deployable:

```bash
# 1. The file must import cleanly with the pipelines export present
python -c "
from ai.starlake.orchestration.__main__ import load_pipelines
ps = load_pipelines('<path>/my_dag.py'); assert ps, 'no pipelines exported'
print([p.pipeline_id if hasattr(p, 'pipeline_id') else p for p in ps])"

# 2a. Airflow: the DagBag must parse it without errors
# (include_examples exists on Airflow 2 only — Airflow 3 removed it and skips examples by default)
python -c "
import airflow
from airflow.models import DagBag
kwargs = {'include_examples': False} if airflow.__version__.startswith('2') else {}
db = DagBag('<dags folder>', **kwargs)
assert not db.import_errors, db.import_errors"

# 2b. Dagster: the module exposes 'defs' (Definitions) — validate the code location
dagster definitions validate -f <path>/my_dag.py
```

Deploy with [dag-deploy](../dag-deploy/SKILL.md) or by copying the file to the orchestrator's DAG folder / code location.

## Example

User: *"Create an Airflow DAG that loads the three starbake tables daily at 2am with the imported pre-load strategy, then runs the kpi transforms."*

The skill reads the metadata, confirms `starbake.orders` normally runs hourly (warns about the schedule override and the existing dagRef coverage), derives `kpi.order_summary >> kpi.top_customers` from the transform SQL, and emits the complete DAG file in one reply: the Step 3 skeleton with a `StarlakeSchedule` for the `starbake` domain, the IMPORTED pre-load group, one `sl_load` per table in a domain task group, the two transforms chained in lineage order, and `start >> pre_load >> loads >> transforms >> end`.

## Related Skills

- [dag-generate](../dag-generate/SKILL.md) - Template-driven DAG generation (reusable, metadata-regenerated)
- [dag-deploy](../dag-deploy/SKILL.md) - Deploy DAG files to the target directory
- [load](../load/SKILL.md) - Load semantics and write strategies
- [transform](../transform/SKILL.md) - Transform tasks the DAG orchestrates
- [lineage](../lineage/SKILL.md) - Compute transform dependency ordering
- [config](../config/SKILL.md) - Environment variables and application structure
- [connection](../connection/SKILL.md) - Connections referenced by `connectionRef`
