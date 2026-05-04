---
pipeline_name: ''       # set in this step
domain_name: ''         # set in this step
business_objective: ''  # set in this step
sla: ''                 # set in this step
source_class: ''        # set in this step: jdbc | rest | file | stream | mixed
---

# Step 1 — Context

## Rules

- Speak in `{communication_language}`. Lead each turn with `🏗️`.
- Do not write any YAML in this step. Output is plain text and the spec file frontmatter only.

## Preconditions

- `{spec_file}` is set (resumed) OR the user has not yet provided a pipeline name (new run).

## Instructions

1. **Load grounding artifacts.** Try to read these so the conversation is grounded in prior decisions:
   - `{planning_artifacts}/domain-discovery-*.md` — known domains and owners
   - `{planning_artifacts}/data-architecture-*.md` — layer / engine / governance choices
   - `{planning_artifacts}/source-analysis-*.md` — per-source detail
   If none exist, note that out loud — the spec will be less grounded but still valid.

2. **Ask the four context questions** (one at a time if the user wants to chat, batched if they want to move fast):

   - **Q1.** Which domain and pipeline name should we work on? (Suggest based on artifacts when possible.)
   - **Q2.** What business question does this pipeline answer? (One sentence. If the user gives more, summarize back to one sentence and confirm.)
   - **Q3.** What is the freshness SLA? (e.g. daily by 6 AM UTC, hourly within 15 min of source, real-time / event-driven.)
   - **Q4.** What kind of sources? Pick one or list multiple: `jdbc`, `rest`, `file`, `stream`, `mixed`.

   **HALT** at each question until the user answers. Do not infer.

3. **Set frontmatter values** in the spec file:
   - `pipeline_name: <kebab-case from Q1>`
   - `domain_name: <from Q1>`
   - `business_objective: <Q2 single sentence>`
   - `sla: <Q3>`
   - `source_class: <Q4>`

4. **Fill the spec's Overview section** with these values plus `default_engine` (dev) and `target_engines[0]` (prod) from config.

5. **Save the spec file.** Add `1` to `stepsCompleted` in the frontmatter.

## Checkpoint

Present a one-paragraph recap to the user:

> **Pipeline:** `{{pipeline_name}}` in domain `{{domain_name}}`.
> **Goal:** {{business_objective}}
> **SLA:** {{sla}}
> **Sources:** {{source_class}}
> **Engines:** {{default_engine}} (dev) → {{target_engines[0]}} (prod)
>
> Ready to define the extract spec? (y/n)

**HALT.** If the user says `n`, ask what to revise and stay on this step. If `y`, proceed to next.

## Next

Read fully and follow: `step-02-extract.md`
