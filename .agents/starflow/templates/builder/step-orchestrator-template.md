---
name: starflow-{{skill_slug}}
description: '{{action_led_description}}. Step-file workflow with resumable progress. Use when the user says "{{trigger_phrase}}".'
---

# {{Workflow Title}}

**Goal:** {{end_artifact_description}}

**Your Role:** {{persona_reference}}

## Conventions

- Bare paths (e.g. `steps/step-01.md`) resolve from the skill root.
- `{starflow-root}` resolves to the directory containing `config/starflow.yaml`.
- Curly-brace tokens are config values: resolve them via
  `python3 {starflow-root}/scripts/resolve_config.py --starflow-root {starflow-root}`.

## On Activation

1. Resolve config and bind the values your steps need.
2. Greet `{user_name}` in `{communication_language}`; state that this workflow is resumable.
3. Scan `{{output_location}}/{{artifact_pattern}}` for files with `status: draft` and a
   non-full `stepsCompleted` array; offer to resume or start fresh (from
   `{starflow-root}/templates/{{output_template}}`).

## Workflow Architecture

Step-file architecture:

- **Just-In-Time Loading**: read only the current step file into context.
- **Sequential Enforcement**: complete steps in order. No skipping.
- **State Tracking**: persist progress in `stepsCompleted: [...]` in the output frontmatter.
- **Append-Only Building**: each step adds to the artifact, never silently rewrites prior steps.

### Critical Rules (NO EXCEPTIONS)

- **NEVER** load multiple step files simultaneously.
- **ALWAYS** halt at `**HALT**` checkpoints (unattended mode auto-answers confirmation
  checkpoints with their documented `Default:`; `HALT (always)` and information-gathering
  questions still halt).
- **ALWAYS** save the artifact with updated `stepsCompleted` before loading the next step.

## First Step

Read fully and follow: `steps/step-01-{{first_step_slug}}.md`

## Step Index

| # | File | Output |
|---|------|--------|
| 1 | `steps/step-01-{{first_step_slug}}.md` | {{step_1_output}} |

## Outcome

{{final_artifact_and_status_flip}}
