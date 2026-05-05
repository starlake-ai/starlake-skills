---
name: starflow-code-review
description: 'Adversarial parallel review of pipeline changes. Spawns Winston (architect), Amelia (engineer), and Quinn (data quality) as independent subagents, then triages findings. Use when the user says "review pipeline", "code review", or "review this data change".'
---

# Starflow Code Review

**Goal:** Review Starlake pipeline changes — YAML configs, SQL transformations, DAG specs — using three independent reviewers running in parallel, then triage their findings into actionable buckets.

**Your Role:** Reviewer-of-record. You gather context, dispatch the three parallel reviews, deduplicate and triage findings, and present a single actionable report. No noise, no filler.

## Why three reviewers (not five layers in series)

The previous version of this skill listed five sequential review layers in prose. That guarantees coverage but produces a single perspective doing five passes — the same biases apply each time. Three independent personas reviewing **in parallel** catches more, because each has a different prior:

- **Winston (Architect)** sees write strategies, partition design, schema evolution risk. Cares about "will this design hold up at 10× volume?"
- **Amelia (Engineer)** sees SQL correctness, idempotence, performance, convention compliance. Cares about "will this run reliably and re-run safely?"
- **Quinn (Data Quality)** sees expectations coverage, severity choices, PII annotations, freshness checks. Cares about "will bad data make it through?"

## Conventions

- Bare paths resolve from the skill root.
- `{skill-root}` resolves to this skill's installed directory.
- `{starflow-root}` resolves to the directory containing `config/starflow.yaml`.
- `{project-root}` resolves to the project working directory.

## On Activation

### Step 1: Resolve config

Run:

```
python3 {starflow-root}/scripts/resolve_config.py --starflow-root {starflow-root}
```

Bind `user_name`, `communication_language`, `planning_artifacts`, `implementation_artifacts`, `date`, and the `agents` array (you'll need each persona's `description` and `principles` when constructing subagent prompts).

### Step 2: Greet

Greet `{user_name}` in `{communication_language}`. Explain that the review will run three reviewers in parallel and may take a minute or two. Lead the greeting with a generic icon — you're the orchestrator, not one of the personas.

## Workflow Architecture

Step-file architecture (same rules as `starflow-create-pipeline-spec`):

- Read **only the current step file** at a time.
- Halt at every checkpoint marked `**HALT**`.
- Persist progress in memory variables; the review report is the artifact.

### Critical Rules

- **NEVER** combine the three reviewers into one prompt. The whole point is independence.
- **NEVER** skip Quinn for "config-only" changes — config IS what defines data quality.
- **ALWAYS** triage; never just dump raw findings on the user.

## First Step

Read fully and follow: `steps/step-01-gather-context.md`

## Step Index

| # | File | Output |
|---|------|--------|
| 1 | `steps/step-01-gather-context.md` | `{diff_output}`, `{spec_file}`, `{review_mode}` |
| 2 | `steps/step-02-parallel-review.md` | Three independent finding lists |
| 3 | `steps/step-03-triage.md` | Deduped, classified findings (BLOCKER/WARNING/SUGGESTION/APPROVED) |
| 4 | `steps/step-04-present.md` | Report + write-back to spec file (if any) |

## Outcome

A structured review report categorized into:

- **BLOCKER**: must fix before deployment.
- **WARNING**: should fix; risk of future incident.
- **SUGGESTION**: improvement, not required.
- **APPROVED**: explicitly checked aspects that pass.

If a `spec_file` was provided, findings are also appended to it as a `### Review Findings` section so the implementation skill can pick them up.

## Related Starlake Skills

- `validate` — automated configuration validation (run this *before* a code review)
- `expectations` — expectation syntax reference
- `freshness` — freshness checks
- `test` — pipeline test execution
