# Starlake Skills

**Agent Skills bundle** providing 49 core AI skills for the [Starlake](https://starlake.ai) data pipeline CLI, plus the optional Starflow guided methodology (19 workflow skills and personas) for data engineering.

Covers all CLI commands (load, transform, extract, autoload, dag-generate...), configuration patterns, connection types, write strategies, data quality expectations, and production best practices for DuckDB, BigQuery, Snowflake, Redshift, and Airflow/Dagster orchestration.

## Installation

### 1. Global Installation (recommended)

Clone the repository and run the install script ([scripts/install.sh](scripts/install.sh) on macOS/Linux, [scripts/install.ps1](scripts/install.ps1) on Windows):

**On macOS / Linux:**
```bash
git clone https://github.com/starlake-ai/starlake-skills.git ~/.starlake-skills
~/.starlake-skills/scripts/install.sh
```

**On Windows (PowerShell):**
```powershell
git clone https://github.com/starlake-ai/starlake-skills.git "$HOME\.starlake-skills"
& "$HOME\.starlake-skills\scripts\install.ps1"
```

This installs skills for **Claude Code**, **GitHub Copilot**, and **Gemini CLI**. To install for specific platforms only:

```bash
~/.starlake-skills/scripts/install.sh --platforms claude,copilot
```

### 2. Project-Local Installation

Install skills into the current project directory instead of globally using [scripts/install.sh](scripts/install.sh) (or [scripts/install.ps1](scripts/install.ps1) on Windows):

```bash
git clone https://github.com/starlake-ai/starlake-skills.git /tmp/starlake-skills
/tmp/starlake-skills/scripts/install.sh --local
```

### 3. Updating

To pick up new skills after a `git pull`, re-run [scripts/install.sh](scripts/install.sh) with `--update`:

```bash
~/.starlake-skills/scripts/install.sh --update
```

### 4. Uninstalling

Run [scripts/install.sh](scripts/install.sh) with `--uninstall` to remove all symlinks:

```bash
~/.starlake-skills/scripts/install.sh --uninstall
```

## Skills Catalog

### Reference
- **config**: Configuration reference (env vars, app structure, types, best practices)
- **connection**: Create or modify database connections in `application.sl.yml`

### Ingestion & Loading
- **autoload**: Auto-infer schemas and load data
- **cnxload**: Load files into JDBC tables
- **esload** / **index**: Load into Elasticsearch
- **ingest**: Generic data ingestion
- **kafkaload**: Kafka load/offload
- **load**: Load from pending area (write strategies, sink config)
- **preload**: Check landing area
- **stage**: Move files landing → pending

### Transformation
- **job** / **transform**: Run SQL/Python transformations

### Extraction
- **extract**: Schema + data extraction
- **extract-bq-schema**: BigQuery schema extraction
- **extract-data**: Data extraction to files
- **extract-rest-data**: REST API data extraction (pagination, auth, rate limiting, incremental)
- **extract-rest-schema**: REST API schema extraction (infer from sample responses)
- **extract-schema**: JDBC schema extraction (custom remarks, column selection)
- **extract-script**: Generate extraction scripts

### Schema Management
- **bootstrap**: New project from template
- **infer-schema**: Infer schema from file
- **xls2yml** / **xls2ymljob**: Excel to YAML conversion
- **yml2ddl**: YAML to SQL DDL
- **yml2xls**: YAML to Excel

### Data Quality
- **expectations**: Expectation syntax, Jinja2 macros, validation patterns

### Lineage & Diagrams
- **acl-dependencies** / **col-lineage** / **lineage** / **table-dependencies**

### Operations
- **console** / **freshness** / **gizmosql** / **metrics** / **migrate** / **serve** / **settings** / **validate**

### Security
- **iam-policies**: IAM policies
- **secure**: RLS, CLS, privacy transformations

### Orchestration
- **dag-deploy** / **dag-generate**: Airflow/Dagster DAG generation

### Utilities
- **bq-info** / **compare** / **parquet2csv** / **site** / **summarize** / **test**

## Starflow Method (Optional)

Starflow is an optional guided methodology layer that helps you plan and implement data pipelines step-by-step. While the skills above give you direct access to every Starlake command, Starflow provides a structured workflow with specialized agent personas.

### Workflow Phases

| Phase | Skills | Description |
|-------|--------|-------------|
| 1. Discovery | `starflow-domain-discovery`, `starflow-source-analysis` | Map data domains, analyze sources |
| 2. Architecture | `starflow-create-data-architecture`, `starflow-schema-design` | Design platform and schemas |
| 3. Pipeline Design | `starflow-create-pipeline-spec`, `starflow-transform-design`, `starflow-orchestration-design` | Specify pipelines end-to-end |
| 4. Implementation | `starflow-dev-pipeline`, `starflow-sprint-planning`, `starflow-code-review`, `starflow-retrospective` | Build, plan sprints, review, retro |

### Step-File Workflows

The heavier workflows (`starflow-create-pipeline-spec`, `starflow-code-review`, `starflow-retrospective`) use **step-file architecture**: each step is a self-contained `steps/step-NN-*.md` file with explicit halt-for-input checkpoints, and progress persists in `stepsCompleted: [...]` in the output file's frontmatter so a session can resume across context windows.

### Adversarial Code Review

`starflow-code-review` spawns three independent persona subagents in parallel: Winston (architecture), Amelia (engineering), and Quinn (data quality). Findings are deduplicated and triaged into BLOCKER / WARNING / SUGGESTION / APPROVED. Each persona has a focused prompt; independence is the point.

### Adaptive Help

`starflow-help` reads `.agents/starflow/_config/starflow-help.csv` (the skill manifest with `phase`, `after`, `before`, `required`, `output-location`, `outputs` columns) and scans the artifacts directory to detect which steps are done. It recommends the next required skill based on dependencies, not a hard-coded list.

### Agent Personas

Talk to a specialized agent for guided assistance:

| Skill | Agent | Specialty |
|-------|-------|-----------|
| `starflow-data-analyst` | Lea | Domain discovery, source analysis |
| `starflow-data-architect` | Winston | Architecture, schemas, pipeline design |
| `starflow-data-engineer` | Amelia | Pipeline implementation, transforms |
| `starflow-data-quality-engineer` | Quinn | Data quality, lineage, expectations |
| `starflow-platform-engineer` | Max | Orchestration, deployment, operations |

### Utility Skills

- **starflow-help**: Adaptive help: reads the manifest, scans artifacts, recommends the next step
- **starflow-data-quality-review**: Review data quality expectations coverage
- **starflow-lineage-review**: Trace and document data lineage
- **starflow-retrospective**: End-of-epic retrospective with follow-through check on the previous retro's action items

### Layered Configuration

Starflow config uses three layers (highest wins): base `config/starflow.yaml` → team `config/custom/starflow.yaml` → personal `config/custom/starflow.user.yaml` (gitignored). The same model applies to per-skill `customize.yaml`. See [`.agents/starflow/config/README.md`](/.agents/starflow/config/README.md) for merge semantics. Resolve at runtime with `python3 .agents/starflow/scripts/resolve_config.py --starflow-root .agents/starflow` (requires PyYAML).

### Getting Started with Starflow

1. Run `starflow-help` to see where to start
2. Begin with `starflow-domain-discovery` to map your data landscape
3. Follow the phases in order, or jump to the phase you need
4. Each Starflow skill references the relevant Starlake CLI skills for implementation details

## Links

- [Starlake Documentation](https://docs.starlake.ai)
- [Starlake GitHub](https://github.com/starlake-ai/starlake)
- [Starlake Examples](https://github.com/starlake-ai/starlake-examples)

## License

Apache-2.0. See [LICENSE](LICENSE) for details.
