---
name: dag-create
description: Create a ready-to-deploy one-off orchestration DAG (Airflow or Dagster Python file) from a natural-language pipeline description, composing sl_load, sl_transform, sl_import and sl_pre_load via the starlake-orchestration API
---

# DAG Create Skill

Turns a natural-language pipeline description ("load these tables, run these transforms, on this schedule, for this orchestrator") into ONE complete, deployable Python DAG file built on the `starlake-orchestration` Python API. The output is NOT a Jinja2 template and does not require `starlake dag-generate` — it is a bespoke, hand-deployable DAG.

Use this skill when the user wants a one-off DAG mixing loads and transforms in a single file. For recurring, metadata-driven DAGs regenerated on every schema change, prefer [dag-generate](../dag-generate/SKILL.md) with a DAG config under `metadata/dags/`.

**Respond in a single conversation turn**: read the metadata, then emit the complete DAG file in one reply. Never split the file across turns.

## Invocation

Describe the pipeline in natural language — the skill triggers on requests like:

- "Create an Airflow DAG that loads the starbake tables daily and then runs the kpi transforms"
- "I need a one-off Dagster job for these three tables plus two transforms, hourly"
- "Build me a deployable DAG file for my project — no templates, just one Python file"

The skill reads the project's `metadata/` and replies with the complete DAG file (see Example conversations).

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
- **Write strategies** (`APPEND`, `OVERWRITE`, `UPSERT_BY_KEY`, `SCD2`, …) are applied by the Starlake CLI from the table/task YAML. Read them to explain behavior to the user — NEVER pass them to `sl_load`/`sl_transform` (they are not orchestration parameters). Note: load tables declare them under `table.metadata.writeStrategy`, transforms at the top-level `task.writeStrategy`. While reading them, validate their own YAML requirements (`key`/`timestamp`/`sink.partition` — see [load](../load/SKILL.md)) and flag violations before generating; `type: "ADAPTATIVE"` is not a real value (adaptive selection is the `types:` condition map — a literal `ADAPTATIVE` string is silently accepted and degrades to APPEND).
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
- `pre_load_sensor` (default `false`), `pre_load_poke_interval`, `pre_load_timeout`, `pre_load_sensor_soft_fail`, `pre_load_not_ready_sentinel_path`: sensor/sentinel variants of the pre-load task (in sensor mode `ack_wait_timeout` is ignored) — see [preload](../preload/SKILL.md) [OPTIONAL]
- `retries` (default 1), `retry_delay` (default 300 s) [OPTIONAL]
- Airflow only: `tags` (space-separated), `start_date`, `end_date`, `catchup`, `default_dag_args` (JSON map), `sl_include_env_vars` [OPTIONAL]

These are the same options documented in the header comments of the bundled dag-generate templates — they are the option API shared by generated and one-off DAGs. The options dict is a free-form map: a key the framework never reads is **silently ignored** (e.g. `load_dependencies` does nothing — the real key is `run_dependencies_first`). Only emit documented keys and warn the user about any unknown ones.

## Strategy semantics and consistency checks

Before emitting the DAG file, cross-check the derived configuration against these rules. Three outcomes: **refuse and fix** (the output would be broken), **warn and ask** (valid but suspicious — proceed only on confirmation), or **inform**.

### Refuse and fix (never generate these)

- **Broken IMPORTED chain**: with `pre_load_strategy: "imported"` the chain is `sl_pre_load >> skip_or_start >> sl_import >> loads`. Never wire `sl_pre_load` straight to `sl_load` — the import (stage) step moves the files the load consumes.
- **Invalid strategy string**: `pre_load_strategy` must be exactly one of `imported`, `ack`, `pending`, `none` (lowercase). Anything else — including `IMPORTED` uppercase or sensor-style names — makes the job constructor raise `ValueError` at DAG definition time.
- **Write strategy as a parameter**: `sl_load`/`sl_transform` have no write-strategy argument and the options dict has no write-strategy key. If the user wants a different write behavior, the change belongs in the table/task YAML (`writeStrategy` — see [load](../load/SKILL.md)); offer that as a separate step.
- **Snowflake one-off DAG**: not composable by hand (the executor needs CLI-embedded statements/json context and fails at definition time). Route to [dag-generate](../dag-generate/SKILL.md).

### Warn and ask

- **`ack` without `global_ack_file_path`**: works, but the framework falls back to a date-coupled default (`{datasets}/pending/{domain}/{YYYY-MM-DD}.ack`) — the producer must write TODAY's file name. Recommend an explicit stable path.
- **Ack companions without `ack`**: `global_ack_file_path`/`ack_wait_timeout` are read only when the strategy is `ack`; under any other strategy they are inert.
- **`sl_import` under `ack`/`pending`**: the canonical chains are `imported → pre_load >> gate >> import >> loads`; `ack`/`pending → pre_load >> gate >> loads`; `none → loads`. Adding an import step to `ack`/`pending` is non-canonical — confirm the user really has co-arriving incoming files to stage.
- **Schedule conflict**: a table whose own `metadata.schedule` differs from the requested DAG schedule (e.g. an hourly table in a daily DAG) is being re-scheduled. Offer one pipeline per schedule instead (a single file may export `pipelines = [a, b]`).
- **Double scheduling**: requested tables/tasks already covered by a `dagRef` in scope will run under BOTH the generated DAG and this one-off DAG.
- **YAML strategy misconfiguration**: while reading `writeStrategy`, flag definitions `starlake validate` would reject — `UPSERT_BY_KEY`/`DELETE_THEN_INSERT` without `key`; `UPSERT_BY_KEY_AND_TIMESTAMP`/`SCD2` without `key` + `timestamp`; `OVERWRITE_BY_PARTITION` without `sink.partition`. The DAG would deploy but every load run would fail.
- **`type: "ADAPTATIVE"` literal**: not a real strategy value — it is silently accepted as a custom no-op that degrades to APPEND behavior. Adaptive selection is a `types: {STRATEGY: 'condition'}` map with NO `type` key. `SCD2` inside a `types:` map is not implemented (ingestion-time error).
- **Unknown option keys**: the options dict is free-form; unknown keys are silently ignored (`load_dependencies` and `incoming_path` are known inert examples — real key for the former is `run_dependencies_first`).
- **Invalid `dataset_triggering_strategy`**: values other than `any`/`all` (lowercase) silently fall back to `any` at runtime — no error will ever surface it, so catch it here.

### Inform

- With both a cron and upstream datasets, cron wins (Airflow). Event semantics differ by orchestrator: Dagster `any` still requires every monitored asset to have materialized at least once; Snowflake supports `all` semantics only.

### "DAG load strategy" vocabulary

Older Starlake material names a DAG-level load-strategy axis (`FILE_SENSOR`, `FILE_SENSOR_DOMAIN`, `ACK_FILE_SENSOR`, `NONE`). **These are not configuration keys** — express the intent with `pre_load_strategy`:

| If the user says | Configure | Behavior |
|---|---|---|
| file sensor (table or domain) | `pre_load_strategy: "imported"` | preload scans the domain's incoming directory (per-table counts; domain-granular) |
| ack file sensor | `pre_load_strategy: "ack"` + `global_ack_file_path` | preload waits on the ack file (retry every `ack_wait_timeout` s by default; the `pre_load_sensor` option family switches to a poke-loop sensor) and **deletes it** on success |
| check staged/pending files | `pre_load_strategy: "pending"` | preload matches files already in the pending area against table patterns |
| no sensor | `pre_load_strategy: "none"` | no pre-load task |

For a true orchestrator-native sensor on an arbitrary path, add a native task (Airflow `FileSensor`) alongside the starlake tasks — that is orchestrator territory, not a starlake option. See [preload](../preload/SKILL.md) for what each strategy actually checks.

## Validate the generated DAG

Always finish by telling the user how to prove the DAG is deployable:

```bash
# 1. The file must import cleanly with the pipelines export present
python -c "
from ai.starlake.orchestration.__main__ import load_pipelines
ps = load_pipelines('<path>/my_dag.py'); assert ps, 'no pipelines exported'
print([p.pipeline_id if hasattr(p, 'pipeline_id') else p for p in ps])"

# 2a. Airflow: the DagBag must parse it without errors AND actually contain the DAG
# (include_examples exists on Airflow 2 only — Airflow 3 removed it and skips examples by default)
python -c "
import airflow
from airflow.models import DagBag
kwargs = {'include_examples': False} if airflow.__version__.startswith('2') else {}
db = DagBag('<dags folder>', **kwargs)
assert not db.import_errors, db.import_errors
assert '<expected dag id>' in db.dags, list(db.dags)"

# 2b. Dagster: the module exposes 'defs' (Definitions) — validate the code location
dagster definitions validate -f <path>/my_dag.py
```

Airflow's safe mode only parses files whose text contains BOTH the strings `dag` and `airflow` (case-insensitive). A one-off file built with `StarlakeJobFactory` has no `import airflow` line — `airflow` is usually only matched via the `StarlakeOrchestrator.AIRFLOW` literal — and may legitimately never contain the word `dag` at all. Make sure the module `description` (or a comment) mentions the Airflow DAG (e.g. `"Airflow DAG loading the starbake tables"`), otherwise the scheduler silently skips the file and a DagBag check without the dag-id assertion false-passes.

Deploy with [dag-deploy](../dag-deploy/SKILL.md) or by copying the file to the orchestrator's DAG folder / code location.

## Example conversations

### Conversation 1 — happy path

User: *"Create an Airflow DAG that loads the three starbake tables daily at 2am with the imported pre-load strategy, then runs the kpi transforms."*

The skill reads the metadata, confirms `starbake.orders` normally runs hourly (warns about the schedule override and the existing dagRef coverage), derives `kpi.order_summary >> kpi.top_customers` from the transform SQL, and emits the complete DAG file in one reply: the Step 3 skeleton with a `StarlakeSchedule` for the `starbake` domain, the IMPORTED pre-load group, one `sl_load` per table in a domain task group, the two transforms chained in lineage order, and `start >> pre_load >> loads >> transforms >> end`.

### Conversation 2 — consistency checks in action

**User**: "Create an Airflow DAG that loads all three starbake tables daily using an ACK file sensor, and upsert customers by customer id. Then run the kpi transforms."

**Assistant** (first reply — checks before generating):

- "ACK file sensor" is not a configuration key — it maps to `pre_load_strategy: "ack"` (see the vocabulary table above).
- No ack path was given: the framework default is date-coupled (`{SL_ROOT}/datasets/pending/starbake/{YYYY-MM-DD}.ack` — the producer must write TODAY's filename). An explicit `global_ack_file_path` is recommended.
- `starbake.orders` is configured `hourly` in its own metadata; pulling it into a daily DAG re-schedules it. Alternative: one pipeline per schedule in the same file (`pipelines = [daily_p, hourly_p]`).
- Upsert cannot be set from the DAG: `sl_load` has no write-strategy parameter. The change belongs in `customers.sl.yml` (`writeStrategy.type: "UPSERT_BY_KEY"`, `key: ["id"]` — the customers primary key is `id`; `customer_id` is the orders-side foreign key). Offered as a separate metadata edit.
- `application.dagRef.load` already covers these tables — they would be scheduled by BOTH the generated DAG and this one-off DAG.

It then asks: proceed daily-only with an explicit ack path, and keep APPEND for now?

**User**: "Daily only is fine, use /data/acks/starbake.ack, keep APPEND."

**Assistant** (second reply): emits the complete Airflow DAG file — the Step 3 skeleton with a `description` mentioning the Airflow DAG, `pre_load_strategy: 'ack'`, `global_ack_file_path: '/data/acks/starbake.ack'`, `ack_wait_timeout`, the ACK chain `sl_pre_load >> skip_or_start >> loads` (no `sl_import` under `ack`), the transforms chained `order_summary >> top_customers`, and the validation commands.

Note on the single-turn rule: once configuration is settled, the full file always arrives in ONE reply. Warn-and-confirm checks (like the schedule conflict above) legitimately precede generation — they are user agency, not drip-feeding.

## Related Skills

- [dag-generate](../dag-generate/SKILL.md) - Template-driven DAG generation (reusable, metadata-regenerated)
- [dag-deploy](../dag-deploy/SKILL.md) - Deploy DAG files to the target directory
- [load](../load/SKILL.md) - Load semantics and write strategies
- [preload](../preload/SKILL.md) - Pre-load strategy semantics (imported/ack/pending/none)
- [transform](../transform/SKILL.md) - Transform tasks the DAG orchestrates
- [lineage](../lineage/SKILL.md) - Compute transform dependency ordering
- [config](../config/SKILL.md) - Environment variables and application structure
- [connection](../connection/SKILL.md) - Connections referenced by `connectionRef`
