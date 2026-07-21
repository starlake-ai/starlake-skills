# Starflow: Guided Data Engineering Method

Starflow is an optional methodology layer on top of Starlake skills. It provides structured workflows and agent personas to guide you through the full data engineering lifecycle: from domain discovery to production deployment.

## How It Works

Starflow adds two things on top of Starlake's CLI skills:

1. **Phased workflows**: a step-by-step method that ensures you build pipelines in the right order (discover domains first, design schemas second, implement third)
2. **Agent personas**: specialized AI agents (Lea, Winston, Amelia, Quinn, Max) that bring domain expertise and opinionated guidance

## Phases

```
Discovery → Architecture → Pipeline Design → Implementation
```

### Phase 1: Discovery
- [`starflow-domain-discovery`](skills/starflow-domain-discovery/SKILL.md): Map data domains, sources, and ownership
- [`starflow-source-analysis`](skills/starflow-source-analysis/SKILL.md): Deep-dive into a specific data source

### Phase 2: Architecture
- [`starflow-create-data-architecture`](skills/starflow-create-data-architecture/SKILL.md): Design layers, engines, governance
- [`starflow-schema-design`](skills/starflow-schema-design/SKILL.md): Define Starlake-compatible table schemas

### Phase 3: Pipeline Design
- [`starflow-create-pipeline-spec`](skills/starflow-create-pipeline-spec/SKILL.md): Full ETL/ELT pipeline specification
- [`starflow-transform-design`](skills/starflow-transform-design/SKILL.md): Design SQL transformations
- [`starflow-orchestration-design`](skills/starflow-orchestration-design/SKILL.md): Design scheduling and DAGs
- [`starflow-semantic-model-design`](skills/starflow-semantic-model-design/SKILL.md): Design the business semantic model for BI and AI consumers

### Phase 4: Implementation
- [`starflow-dev-pipeline`](skills/starflow-dev-pipeline/SKILL.md): Implement pipeline from spec
- [`starflow-sprint-planning`](skills/starflow-sprint-planning/SKILL.md): Plan and track sprint progress
- [`starflow-code-review`](skills/starflow-code-review/SKILL.md): Review pipeline configuration and SQL

## Agents

| Agent | Name | When to Use |
|-------|------|-------------|
| [`starflow-data-analyst`](skills/starflow-data-analyst/SKILL.md) | Lea | Starting a project, mapping data sources |
| [`starflow-data-architect`](skills/starflow-data-architect/SKILL.md) | Winston | Designing schemas and architecture |
| [`starflow-data-engineer`](skills/starflow-data-engineer/SKILL.md) | Amelia | Building pipelines, writing transforms |
| [`starflow-data-quality-engineer`](skills/starflow-data-quality-engineer/SKILL.md) | Quinn | Setting up expectations, reviewing quality |
| [`starflow-platform-engineer`](skills/starflow-platform-engineer/SKILL.md) | Max | Orchestration, deployment, CI/CD |

## Utility Skills

- [`starflow-help`](skills/starflow-help/SKILL.md): Navigate the Starflow method and get recommendations
- [`starflow-builder`](skills/starflow-builder/SKILL.md): Scaffold custom personas and workflow skills, or customize existing ones
- [`starflow-data-quality-review`](skills/starflow-data-quality-review/SKILL.md): Review data quality expectations coverage
- [`starflow-lineage-review`](skills/starflow-lineage-review/SKILL.md): Trace and document data lineage

## Configuration

Copy [`config/starflow.yaml`](config/starflow.yaml) to your project and customize:
- `project_name`: your project identifier
- `user_name`: your name (used in agent greetings)
- `output_folder`: where Starflow writes planning and implementation artifacts
- `default_engine`: local development engine (default: duckdb)
- `target_engines`: production deployment targets
- `unattended`: auto-answer confirmation checkpoints with documented defaults (decisions are logged and the output lands as `ready-for-review`, never `ready-for-dev`)

## Templates

The [`templates/`](templates/) directory contains document templates used by workflow skills:
- [`domain-discovery-template.md`](templates/domain-discovery-template.md)
- [`pipeline-spec-template.md`](templates/pipeline-spec-template.md)
- [`project-context-template.md`](templates/project-context-template.md)
