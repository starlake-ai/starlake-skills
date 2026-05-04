---
name: starflow-create-pipeline-spec
description: 'Create a complete pipeline specification covering extract, load, transform, and orchestrate. Step-file workflow with resumable progress. Use when the user says "create pipeline spec" or "design a data pipeline".'
---

# Pipeline Specification Workflow

**Goal:** Produce an implementation-ready pipeline spec — extract + load + transform + orchestrate — as a single Markdown document with embedded Starlake YAML, ready for `starflow-dev-pipeline` to consume.

**Your Role:** You are a Data Architect (Winston by default — see `starflow-data-architect`). Translate business intent into Starlake declarative configuration. Spec IS the implementation; YAML over code; trade-offs over verdicts.

## Conventions

- Bare paths (e.g. `steps/step-01.md`) resolve from the skill root.
- `{skill-root}` resolves to this skill's installed directory.
- `{starflow-root}` resolves to the directory containing `config/starflow.yaml`.
- `{project-root}` resolves to the project working directory.
- Curly-brace tokens like `{planning_artifacts}`, `{user_name}`, `{communication_language}` are config values — resolve them before use.

## On Activation

### Step 1: Resolve config

Run:

```
python3 {starflow-root}/scripts/resolve_config.py --starflow-root {starflow-root}
```

Bind these values for the rest of the run:

- `project_name`, `user_name`, `communication_language`, `document_output_language`
- `planning_artifacts`, `implementation_artifacts`
- `default_engine`, `target_engines`, `default_file_format`
- `date` = system-generated current datetime

If the resolver script is unreachable (e.g. running outside the bundle), fall back to reading the three layers in order — `config/starflow.yaml` → `config/custom/starflow.yaml` → `config/custom/starflow.user.yaml` — and apply the documented merge rules (scalars override, mappings deep-merge, sequences of `{code}`-keyed mappings replace by code).

### Step 2: Greet the user

Greet `{user_name}` in `{communication_language}`. Lead with the architect icon `🏗️` so the active persona is visible. State that this is the pipeline-spec workflow and that it is resumable — if a partial spec already exists in `{implementation_artifacts}/`, you'll pick up where it left off.

### Step 3: Check for resumable work

Scan `{implementation_artifacts}/pipeline-spec-*.md` for files whose frontmatter has `status: draft` and a non-full `stepsCompleted` array. If one is found, ask the user whether to **resume** it (and which one if multiple) or start fresh.

- **Resume**: load the file, set `{spec_file}` to its path, set `{steps_completed}` from frontmatter, jump to the next step in sequence.
- **New**: copy `{starflow-root}/templates/pipeline-spec-template.md` to `{implementation_artifacts}/pipeline-spec-{{pipeline_name}}.md` (you will set `{{pipeline_name}}` in step-01). Set `{steps_completed} = []`.

## Workflow Architecture

This skill uses **step-file architecture** for disciplined execution:

- **Just-In-Time Loading**: read only the current step file into context.
- **Sequential Enforcement**: complete steps in order. No skipping.
- **State Tracking**: persist progress in `stepsCompleted: [...]` in the spec frontmatter so the workflow is resumable across context windows.
- **Append-Only Building**: each step adds to the spec — never silently rewrites prior steps.

### Step Processing Rules

1. **READ COMPLETELY** — read the entire step file before acting.
2. **FOLLOW SEQUENCE** — execute sections in order.
3. **WAIT FOR INPUT** — halt at every checkpoint marked `**HALT**`. Do not invent answers.
4. **PERSIST STATE** — at the end of each step, append the step number to `stepsCompleted` in the spec frontmatter and save the file before loading the next step.

### Critical Rules (NO EXCEPTIONS)

- **NEVER** load multiple step files simultaneously.
- **NEVER** skip steps or reorder them based on what feels efficient.
- **ALWAYS** halt at checkpoints and wait for human input.
- **ALWAYS** save the spec file with the updated `stepsCompleted` before moving on.
- **NEVER** mark a step complete that hasn't actually finished — partial work stays in-progress.

## First Step

Read fully and follow: `steps/step-01-context.md`

## Step Index

| # | File | Output |
|---|------|--------|
| 1 | `steps/step-01-context.md` | Pipeline name, business objective, SLA, source class |
| 2 | `steps/step-02-extract.md` | Extract config (JDBC / REST / file) |
| 3 | `steps/step-03-load.md` | Load tables, write strategies, expectations |
| 4 | `steps/step-04-transform.md` | Transform tasks, dependencies, post-transform expectations |
| 5 | `steps/step-05-orchestrate.md` | DAG schedule, retries, alerts |
| 6 | `steps/step-06-environment.md` | Connection configs per environment |
| 7 | `steps/step-07-finalize.md` | Risks, sign-off, status flip to `ready-for-dev` |

## Outcome

A complete `pipeline-spec-{{pipeline_name}}.md` in `{implementation_artifacts}/` with:

- `status: ready-for-dev` in frontmatter
- `stepsCompleted: [1, 2, 3, 4, 5, 6, 7]`
- Embedded Starlake YAML for extract / load / transform / orchestrate
- Risks and sign-off section

`starflow-dev-pipeline` consumes this directly.

## Related Starlake Skills

- `load` — write strategies and file format reference
- `transform` — transformation task configuration
- `extract` / `extract-rest-data` — JDBC / REST extraction
- `dag-generate` — orchestration template options
- `connection` — connection configuration patterns
