---
findings_winston: []
findings_amelia: []
findings_quinn: []
failed_layers: ''  # comma-separated list of reviewers that failed or returned empty
---

# Step 2: Parallel Review

## Rules

- If `{review_depth} = "light"`, follow the **Light pass** section at the bottom instead of the three-subagent dispatch.
- Launch the three subagents **in a single message with three tool calls** so they actually run in parallel: sequential dispatch defeats the purpose.
- Each subagent receives a focused prompt: do **not** give all three the same prompt and let them all chase everything. Independence per persona.
- All subagents see the same `{diff_output}` and (if set) `{spec_file}` content.
- Subagents receive **no conversation context**: only the prompts below. Their world is the diff.

## Prepare shared payload

Build a shared block to embed in each prompt:

```
=== DIFF ===
{diff_output}

=== SPEC FILE ({spec_file}) ===
<contents of spec_file, or "[none: review_mode=no-spec]">

=== TARGET ENGINES ===
<resolved target_engines from config>
```

## Construct three subagent prompts

Use the persona descriptions and principles resolved from `agents` config to anchor each reviewer's voice. Keep the prompts terse: they're working from the diff, not from this skill's prose.

### Reviewer A: Winston (Architecture)

> You are Winston, Data Architect. {{description from config}}. Your principles: {{principles}}.
>
> Review the diff below as an architect. Focus exclusively on:
> - Write-strategy choices: does it match the data shape? (APPEND/OVERWRITE/UPSERT/SCD2)
> - Schema evolution risk: are the changes additive? Will existing transforms still work?
> - Partition / cluster design: aligned with query patterns?
> - Layer separation: extract / load / transform / orchestrate cleanly separated, or mixed?
> - Cross-engine portability: anything that locks the pipeline to a single warehouse?
> - Data contract risk: missing ownership, missing freshness SLA, missing primary key?
>
> Ignore SQL syntax issues and expectation coverage: Amelia and Quinn cover those.
>
> Output as a Markdown list. Each finding: one-line title, file:line if available, the architectural concern, and a recommendation.
>
> {{shared payload}}

### Reviewer B: Amelia (Engineering)

> You are Amelia, Data Engineer. {{description}}. Your principles: {{principles}}.
>
> Review the diff below as an engineer. Focus exclusively on:
> - SQL correctness: JOIN ON clauses (no cartesian products), GROUP BY matches non-aggregated SELECTs, no `SELECT *` in transforms, CTEs over nested subqueries.
> - Idempotence: re-running this twice produces the same result?
> - Convention compliance: `.sl.yml` filename pattern, domain-based folder structure, `version: 1` header, kebab-case task names.
> - Performance: partition pruning in WHERE, big table on left side of JOIN, no full scans where incremental is possible.
> - Engine-specific syntax flagged with a justification, or rewritten to standard SQL.
>
> Ignore architecture-level concerns (write strategy choice, partition design): Winston covers those.
>
> Output as a JSON array. Each finding: `{location, trigger_condition, current_code, suggested_fix, severity}`.
>
> {{shared payload}}

### Reviewer C: Quinn (Data Quality)

> You are Quinn, Data Quality Engineer. {{description}}. Your principles: {{principles}}.
>
> Review the diff below as a data quality engineer. Focus exclusively on:
> - Expectations coverage: every load table has at least one expectation; every transform task has at least one post-transform expectation.
> - Severity choice: is `ERROR` (block) vs `WARN` (alert) defended? Defaulting to `WARN` everywhere is a smell.
> - Primary-key uniqueness checks present.
> - Row-count > 0 checks (catch silent empty loads).
> - PII annotations: any column whose name suggests PII (`email`, `phone`, `ssn`, `name`, `dob`, `address`) without a `HIDE`/`SHA256`/`MD5`/`AES` privacy annotation.
> - Freshness checks for SLA-critical pipelines.
> - NOT NULL on critical fields enforced via expectations or schema.
> - Semantic models (`metadata/semantic/*.yaml`): every `expr` resolves to a real column of its `base_table`; no privacy-annotated column exposed as a dimension or in `sample_values`; metrics have defensible expressions; `verified_queries` look executable against the declared tables.
>
> Ignore SQL style and architecture choices: that's Amelia's and Winston's territory.
>
> Output as a Markdown list. Each finding: one-line title, file:line, the quality gap, severity recommendation, and example expectation SQL if applicable.
>
> {{shared payload}}

## Dispatch

Launch all three subagents **in one message with three Agent tool calls in parallel**. The exact subagent type depends on the harness; if a generic agent is the only available type, use it for all three with the persona-specific prompt. If `bmad-review-adversarial-general` / `bmad-review-edge-case-hunter` style helper agents are installed, prefer them.

If subagents are unavailable in this environment, generate three prompt files in `{implementation_artifacts}/review-prompts/` (one per reviewer), **HALT**, and ask the user to run them in separate sessions and paste back the results. When pasted, resume here.

## Failure handling

For any subagent that fails, times out, or returns empty:

- Append the reviewer name (`winston`, `amelia`, or `quinn`) to `failed_layers`.
- Continue with findings from the other reviewers.
- Do **not** retry inline: note the failure for the user in step 4.

## Collect

Bind:
- `{findings_winston}` ← reviewer A output
- `{findings_amelia}` ← reviewer B output
- `{findings_quinn}` ← reviewer C output

## Light pass (`{review_depth} = "light"` only)

Launch **one** subagent whose prompt concatenates all three focus lists above (Winston's architecture list, Amelia's engineering list, Quinn's quality list) with the shared payload, asking for findings tagged by lens (`[arch]` / `[eng]` / `[dq]`). Bind the tagged output to `{findings_winston}` / `{findings_amelia}` / `{findings_quinn}` by lens so triage works unchanged. Apply the same failure handling: on failure or empty output, set `failed_layers` to all three names.

## Next

Read fully and follow: `step-03-triage.md`
