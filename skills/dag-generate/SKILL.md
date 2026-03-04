---
name: dag-generate
description: Generate orchestration DAGs (Airflow/Dagster) from your Starlake project
---

# DAG Generate Skill

Generates orchestration DAG files (Airflow Python DAGs or Dagster jobs) from your Starlake project configuration. DAGs are generated from Jinja2 templates and can be customized per domain, table, or task.

## Usage

```bash
starlake dag-generate [options]
```

## Options

- `--outputDir <value>`: Output directory for generated DAG files
- `--clean`: Clean the output directory before generating
- `--tags <value>`: Generate DAGs only for tasks/tables matching these tags
- `--tasks`: Generate DAG files for transform tasks
- `--domains`: Generate DAG files for load domains
- `--withRoles`: Include role definitions in generated DAGs
- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`

## Configuration Context

### DAG Configuration Files (`metadata/dags/{name}.sl.yml`)

Each DAG configuration specifies a template and output filename:

```yaml
# metadata/dags/airflow_load_shell.sl.yml
version: 1
dag:
  comment: "sample dag configuration"
  template: "load/airflow__scheduled_table__shell.py.j2"
  filename: "airflow_all_tables.py"
  options:
    sl_env_var: '{"SL_ROOT": "{{SL_ROOT}}"}'
```

```yaml
# metadata/dags/airflow_transform_shell.sl.yml
dag:
  comment: "sample dag configuration"
  template: "transform/airflow__scheduled_task__shell.py.j2"
  filename: "airflow_all_tasks.py"
  options:
    run_dependencies_first: "true"
```

### Dagster DAG Configuration

```yaml
# metadata/dags/dagster_load_shell.sl.yml
dag:
  comment: "data loading for {{domain}}"
  template: "load/dagster__scheduled_table__shell.py.j2"
  filename: "dagster_all_load.py"
  options:
    run_dependencies_first: "true"
    sl_env_var: '{"SL_ROOT": "{{SL_ROOT}}"}'
    SL_STARLAKE_PATH: "{{SL_ROOT}}/starlake"
    pre_load_strategy: "none"       # pending, imported, ack, none
    global_ack_file_path: "{{SL_ROOT}}/datasets/pending/starbake/GO.ack"
    ack_wait_timeout: "60"          # seconds
```

### DAG Reference Assignment

DAGs are assigned in `application.sl.yml` at the project level, and can be overridden at domain or table level:

```yaml
# metadata/application.sl.yml
application:
  dagRef:
    load: "airflow_load_shell"       # Default DAG for all load tasks
    transform: "airflow_transform_shell"  # Default DAG for all transforms
```

Override at domain level:

```yaml
# metadata/load/starbake/_config.sl.yml
load:
  metadata:
    dagRef: "custom_load_dag"
```

Override at table/task level:

```yaml
# metadata/load/starbake/orders.sl.yml
table:
  metadata:
    dagRef: "orders_specific_dag"
```

**Priority** (lowest to highest): project -> domain -> table/task

### DAG Scheduling Options

```yaml
# metadata/dags/sales_load_dag.sl.yml
dag:
  name: "sales_load_dag"
  schedule: "0 2 * * *" # Cron expression (2 AM daily)
  catchup: true # Process historical runs
  default_pool: "default_pool"
  description: "Daily sales data load from SFTP"

  tags:
    - "production"
    - "sales"
    - "daily"

  options:
    sl_env_var: '{"SL_ROOT": "${root_path}", "SL_DATASETS": "${root_path}/datasets", "SL_TIMEZONE": "Europe/Paris"}'
```

### Load Strategy Options

Control how load DAGs detect and trigger file processing:

```yaml
dag:
  load:
    strategy: "FILE_SENSOR" # How to trigger load
    options:
      incoming_path: "{{SL_ROOT}}/incoming/{{domain}}"
      pending_path: "{{SL_ROOT}}/datasets/pending/{{domain}}"
      global_ack_file_path: "{{SL_ROOT}}/datasets/pending/{{domain}}/{{{{ds}}}}.ack"
```

| Strategy | Description |
|---|---|
| `FILE_SENSOR` | Watch for new files in incoming directory per table |
| `FILE_SENSOR_DOMAIN` | Watch for new files at domain level |
| `ACK_FILE_SENSOR` | Wait for an acknowledgment (.ack) file before processing |
| `NONE` | No sensor -- triggered by schedule only |

### Custom DAG Templates

Override the default Jinja2 template for full control over DAG generation:

```yaml
dag:
  template:
    file: "custom_template.py.j2" # Relative to metadata/dags/template or absolute
```

Place custom templates in `metadata/dags/template/`.

### DAG Assignment Hierarchy

**Priority (lowest to highest):**

1. **Project level**: `application.dagRef.load` / `application.dagRef.transform`
2. **Domain level**: `load.metadata.dagRef` in `_config.sl.yml`
3. **Table level**: `table.metadata.dagRef` in `table.sl.yml`
4. **Transform level**: `task.dagRef` in `task.sl.yml`

Lower levels override higher levels.

## Examples

### Generate All DAGs

```bash
starlake dag-generate --outputDir /tmp/dags --clean
```

### Generate Only Load DAGs

```bash
starlake dag-generate --domains --outputDir /tmp/dags
```

### Generate Only Transform DAGs

```bash
starlake dag-generate --tasks --outputDir /tmp/dags
```

### Generate DAGs for Specific Tags

```bash
starlake dag-generate --tags daily,critical --outputDir /tmp/dags
```

### Generate with Role Definitions

```bash
starlake dag-generate --outputDir /tmp/dags --withRoles --clean
```

## Related Skills

- [dag-deploy](../dag-deploy/SKILL.md) - Deploy generated DAGs to target directory
- [transform](../transform/SKILL.md) - Run transform tasks
- [load](../load/SKILL.md) - Load data
- [lineage](../lineage/SKILL.md) - Visualize task dependencies
- [config](../config/SKILL.md) - Configuration reference (environment variables)
