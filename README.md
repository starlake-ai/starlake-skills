# Starlake Skills

**Agent Skills bundle** for the [Starlake](https://starlake.ai) data pipeline CLI: a core skill for every CLI command and configuration pattern, plus the optional Starflow guided methodology with workflow skills and expert personas for data engineering.

Covers all CLI commands (load, transform, extract, autoload, dag-generate...), configuration patterns, connection types, write strategies, data quality expectations, and production best practices for DuckDB, BigQuery, Snowflake, Redshift, and Airflow/Dagster orchestration.

## Installation

There are two ways to install, and both end in the same state: every skill folder in this bundle is **symlinked** into the skills directory of each AI assistant, where it is discovered automatically.

- **Release install** (end users): downloads a versioned archive from GitHub Releases into `~/.starlake-skills`, then links the skills. No git or Node required, only `curl` and `tar` (PowerShell 5.1+ on Windows).
- **Git clone** (contributors): links point straight into your clone, so edits to any `SKILL.md` and every `git pull` are live immediately, with no re-install.

### What gets installed where

| Link created | Points to | Purpose |
|--------------|-----------|---------|
| `~/.claude/skills/<skill>` | `.agents/skills/<skill>` and `.agents/starflow/skills/<skill>` | Skill discovery for Claude Code |
| `~/.copilot/skills/<skill>` | same | Skill discovery for GitHub Copilot |
| `~/.gemini/skills/<skill>` | same | Skill discovery for Gemini CLI |
| `~/.<platform>/starflow` | `.agents/starflow` | Starflow config, templates, and the config-resolver scripts |

Each assistant reads the `name` and `description` frontmatter of every linked `SKILL.md` to decide when a skill applies; no build step or registration is involved. Because links are directories, step files, templates, and configs inside a skill folder come along automatically. The installer only ever removes symlinks that resolve back into this bundle: it never deletes real files or links belonging to other tools. With `--local`, links go into `./.<platform>/skills/` of the current project instead of `$HOME`.

### 1. Quick Install from a Release (recommended)

Downloads the latest [GitHub Release](https://github.com/starlake-ai/starlake-skills/releases) into `~/.starlake-skills` and links the skills. No git or Node required.

**On macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/starlake-ai/starlake-skills/main/scripts/install-remote.sh | bash
```

**On Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/starlake-ai/starlake-skills/main/scripts/install-remote.ps1 -OutFile "$env:TEMP\install-remote.ps1"; & "$env:TEMP\install-remote.ps1"
```

Pass `--pin vX.Y.Z` (`-Pin` on Windows) for an exact release; re-run the same command any time to update to the latest release. Extra options (`--platforms claude`, `--local`, `--uninstall`) pass through to the inner installer.

### 2. Install from a Git Clone (contributors)

Clone the repository and run the install script ([scripts/install.sh](scripts/install.sh) on macOS/Linux, [scripts/install.ps1](scripts/install.ps1) on Windows). Skills are symlinked from the clone, so edits and `git pull` are live immediately:

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

### 3. Project-Local Installation

Install skills into the current project directory instead of globally using [scripts/install.sh](scripts/install.sh) (or [scripts/install.ps1](scripts/install.ps1) on Windows):

```bash
git clone https://github.com/starlake-ai/starlake-skills.git /tmp/starlake-skills
/tmp/starlake-skills/scripts/install.sh --local
```

### 4. Updating

**Release installs**: re-run the quick-install one-liner; it replaces `~/.starlake-skills` with the latest release and re-links.

**Git clones**: skill content updates the moment you `git pull` (the links point into the clone). Re-run the installer with `--update` only to pick up added or removed skill folders:

```bash
~/.starlake-skills/scripts/install.sh --update
```

### 5. Versions and channels (git clone)

By default the installer links whatever is checked out and never touches the repo's git state. To follow a release channel instead, pass `--channel` (bash) / `-Channel` (PowerShell):

```bash
~/.starlake-skills/scripts/install.sh --update --channel stable   # newest vX.Y.Z release tag
~/.starlake-skills/scripts/install.sh --update --channel latest   # main branch (bleeding edge)
~/.starlake-skills/scripts/install.sh --pin v1.2.0                # exact release
~/.starlake-skills/scripts/install.sh --version                   # print installed version
```

A channel or pin switch checks out the requested ref and re-links from scratch, since skills may have been added or removed between versions. Releases are published by tagging the repository `vX.Y.Z`.

### 6. Uninstalling

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

### Semantic Layer
- **semantic**: Author semantic models in `metadata/semantic/` (dimensions, facts, metrics, relationships, verified queries) for BI tools and AI agents

### Lineage & Diagrams
- **acl-dependencies** / **col-lineage** / **lineage** / **table-dependencies**

### Operations
- **console** / **freshness** / **gizmosql** / **metrics** / **migrate** / **serve** / **settings** / **validate**

### Security
- **iam-policies**: IAM policies
- **secure**: RLS, CLS, privacy transformations

### Orchestration
- **dag-create**: Create a ready-to-deploy one-off DAG (Airflow/Dagster) from a natural-language pipeline description
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
| 3. Pipeline Design | `starflow-create-pipeline-spec`, `starflow-transform-design`, `starflow-orchestration-design`, `starflow-semantic-model-design` | Specify pipelines end-to-end, including the semantic layer |
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
- **starflow-builder**: Scaffold custom personas and workflow skills, or customize existing ones via the layered config
- **starflow-data-quality-review**: Review data quality expectations coverage
- **starflow-lineage-review**: Trace and document data lineage
- **starflow-retrospective**: End-of-epic retrospective with follow-through check on the previous retro's action items

### Scale-Adaptive Depth and Unattended Mode

Pipeline specs carry a `scale` field (`light` / `standard` / `deep`) classified in step-01: light pipelines skip optional ceremony and merge checkpoints, deep pipelines get extra rigor prompts (failure modes, backfill, SLA math). Small diffs can opt into a light single-reviewer code review instead of the full three-persona pass.

Setting `unattended: true` in the config (or asking for it per run) makes workflows auto-answer confirmation checkpoints with their documented defaults, logging every choice to `autoDecisions:` in the output frontmatter. Information-gathering questions still halt, and unattended specs finish as `ready-for-review` (never `ready-for-dev`) until a human reviews the decision log.

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
