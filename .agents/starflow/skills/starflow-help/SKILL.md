---
name: starflow-help
description: 'Reads the Starflow manifest and scans existing artifacts to tell the user where they are and what to do next. Use when the user asks "what should I do next", "starflow help", "where am I in starflow", or just "/help" inside Starflow.'
---

# Starflow Help & Navigation

## Purpose

Help the user understand where they are in their Starflow workflow and what to run next. **Do not dump the catalog.** Surface only what's relevant to their current position.

## Desired Outcomes

When this skill completes, the user should:

1. **Know where they are** — which phase, what's already complete, what's blocked.
2. **Know what to do next** — the next required skill, with clear reasoning.
3. **Know how to invoke it** — skill name, menu code, action context.
4. **Get offered a quick start** — when one skill is the obvious next step, offer to run it now rather than just listing it.
5. **Feel oriented, not overwhelmed** — only what fits their current position.

## Data Sources

- **Catalog**: `.agents/starflow/_config/starflow-help.csv` — manifest of all Starflow skills with phases, dependencies, and output patterns. Resolve relative to the Starflow root (the directory containing `config/starflow.yaml`).
- **Config**: resolve via the layered resolver:
  ```
  python3 .agents/starflow/scripts/resolve_config.py --starflow-root .agents/starflow
  ```
  Use the resolved values to expand `{planning_artifacts}` / `{implementation_artifacts}` / `{user_name}` / `{communication_language}`.
- **Artifacts**: scan resolved `output-location` directories for files matching the row's `outputs` glob pattern. Their presence is the strongest "this step is done" signal.
- **Project knowledge**: if the resolved `project_knowledge` path exists, read it for grounding context — never fabricate project-specific details.

## CSV Schema

```
module, skill, display-name, menu-code, description, action, args, phase, after, before, required, output-location, outputs
```

- **phase** — `1-discovery`, `2-architecture`, `3-pipeline-design`, `4-implementation`, or `anytime`.
- **after** — comma-separated skill names that should ideally complete first.
- **before** — comma-separated skill names that should run after this one.
- **required** — `true` items must complete before later phases can meaningfully proceed. Phases with no required items are entirely optional.
- **output-location** — config key (`planning_artifacts`, `implementation_artifacts`, `project_knowledge`, `output_folder`) whose resolved path is where outputs land.
- **outputs** — glob pattern relative to `output-location` to detect completion.

## Procedure

### 1. Resolve config and load the manifest

Run the resolver. Read the CSV. Skip rows where `skill` is `_meta` (those are documentation pointers, not skills).

### 2. Detect what's already done

For each row with `output-location` set:

- Resolve the location key against config (e.g. `planning_artifacts` → `/path/to/starflow-output/planning-artifacts`).
- Glob for `outputs` patterns under that path.
- If any match exists, mark the skill as **done** (probabilistically — flag uncertainty if filenames are ambiguous).

### 3. Determine the current phase

The current phase is the lowest-numbered phase that still has at least one `required=true` skill marked **not done**. If every required skill is done, the user is in `4-implementation` continuous mode (review / retro / quality cycles).

### 4. Compute the next recommendation

- The next required skill in the current phase whose `after` dependencies are all done.
- If multiple are eligible, prefer the one earliest in CSV order.
- If the current phase has no required skills, recommend the first optional skill in that phase whose dependencies are met.

### 5. Present

Use this shape (compact, in `{communication_language}`):

> **Where you are:** Phase 2 — Architecture. Discovery is complete (3 artifacts found). Schema design is the next required step.
>
> **Recommended next:**
> - `[SD]` **Schema Design** — `starflow-schema-design` — Define `.sl.yml` for tables identified in the architecture doc.
>
> **Optional in this phase:** _(none currently — all optional Discovery items already done)_
>
> **Want me to start `starflow-schema-design` now? (y/n)**

If the user has a specific question that doesn't map cleanly to a skill (e.g. "what write strategy should I use?"), answer it directly using the relevant agent persona's knowledge — `starflow-data-architect` for design questions, `starflow-data-engineer` for implementation, etc. — and offer to invoke that agent.

## Constraints

- **Recommend running each skill in a fresh context window** when the workflow is heavy (Discovery, Pipeline Spec, Dev Pipeline, Retrospective). For lightweight skills (Help, Sprint Status), continuing in the current context is fine.
- **Match the user's tone** — conversational when they're casual, structured when they want specifics.
- **Never fabricate completion** — if you can't read the artifacts directory, say so and ask.
- **Prefer the recommendation over the list** — list every option only when explicitly asked.

## Outcome

The user has a clear next step, knows why it's the next step, and can either run it directly or pivot to a related question.
