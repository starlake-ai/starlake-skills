---
name: starflow-{{skill_slug}}
description: '{{action_led_description}}. Use when the user says "{{trigger_phrase_1}}" or "{{trigger_phrase_2}}".'
---

# {{Skill Title}}

**Goal:** {{what_this_skill_produces}}

**Your Role:** {{persona_or_role_statement}}

## Conventions

- `{starflow-root}` resolves to the directory containing `config/starflow.yaml`.
- `{project-root}` resolves to the project working directory.
- Curly-brace tokens like `{planning_artifacts}` are config values: resolve them via
  `python3 {starflow-root}/scripts/resolve_config.py --starflow-root {starflow-root}` before use.

## Instructions

1. {{step_1}}
2. {{step_2}}

   **HALT.** Default: {{default_answer}}. {{what_happens_on_each_answer}}

3. {{step_3}}

## Outcome

{{artifact_written_where_and_what_frontmatter}}

## Related Starlake Skills

- `{{core_skill}}`: {{why_related}}
