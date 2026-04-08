# Starflow — Guided Data Engineering Method

Starflow is an optional methodology layer on top of Starlake skills. It provides structured workflows and agent personas to guide you through the full data engineering lifecycle — from domain discovery to production deployment.

## How It Works

Starflow adds two things on top of Starlake's CLI skills:

1. **Phased workflows** — a step-by-step method that ensures you build pipelines in the right order (discover domains first, design schemas second, implement third)
2. **Agent personas** — specialized AI agents (Lea, Winston, Amelia, Quinn, Max) that bring domain expertise and opinionated guidance

## Phases

```
Discovery → Architecture → Pipeline Design → Implementation
```

### Phase 1: Discovery
- `starflow-domain-discovery` — Map data domains, sources, and ownership
- `starflow-source-analysis` — Deep-dive into a specific data source

### Phase 2: Architecture
- `starflow-create-data-architecture` — Design layers, engines, governance
- `starflow-schema-design` — Define Starlake-compatible table schemas

### Phase 3: Pipeline Design
- `starflow-create-pipeline-spec` — Full ETL/ELT pipeline specification
- `starflow-transform-design` — Design SQL transformations
- `starflow-orchestration-design` — Design scheduling and DAGs

### Phase 4: Implementation
- `starflow-dev-pipeline` — Implement pipeline from spec
- `starflow-sprint-planning` — Plan and track sprint progress
- `starflow-code-review` — Review pipeline configuration and SQL

## Agents

| Agent | Name | When to Use |
|-------|------|-------------|
| `starflow-data-analyst` | Lea | Starting a project, mapping data sources |
| `starflow-data-architect` | Winston | Designing schemas and architecture |
| `starflow-data-engineer` | Amelia | Building pipelines, writing transforms |
| `starflow-data-quality-engineer` | Quinn | Setting up expectations, reviewing quality |
| `starflow-platform-engineer` | Max | Orchestration, deployment, CI/CD |

## Configuration

Copy `config/starflow.yaml` to your project and customize:
- `project_name` — your project identifier
- `user_name` — your name (used in agent greetings)
- `output_folder` — where Starflow writes planning and implementation artifacts
- `default_engine` — local development engine (default: duckdb)
- `target_engines` — production deployment targets

## Templates

The `templates/` directory contains document templates used by workflow skills:
- `domain-discovery-template.md`
- `pipeline-spec-template.md`
- `project-context-template.md`
