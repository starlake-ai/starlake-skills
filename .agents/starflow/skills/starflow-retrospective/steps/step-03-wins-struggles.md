---
wins: []
struggles: []
surprises: []
---

# Step 3: Wins, Struggles, Surprises

## Rules

- One topic at a time. Don't batch.
- No blame. Phrase struggles in terms of systems, conditions, and processes — not people.
- Concrete examples beat generalities. "The DuckDB → BigQuery promotion took three retries" beats "Deployment was hard".

## Instructions

### 1. Wins

**HALT.** Ask:

> What went well in `{epic_id}`? Three to five concrete things. Examples to spark thinking:
> - A pipeline that hit its SLA on the first deploy.
> - An expectation that caught real bad data before it hit production.
> - A schema change that landed without breaking downstream.
> - A new pattern that worked and should be reused.

For each win, capture:

```yaml
- title: <one line>
  detail: <what specifically worked>
  reusable: true | false   # is there a pattern others should adopt?
  evidence: <commit / spec / pipeline name>
```

Bind to `{wins}`.

### 2. Struggles

**HALT.** Ask:

> What was hard? Be concrete. Examples:
> - A pipeline that needed three rewrites to get the partition strategy right.
> - An orchestration step that flaked intermittently.
> - A data-quality issue that wasn't caught until production.
> - A spec that turned out ambiguous mid-implementation.

For each struggle, capture:

```yaml
- title: <one line>
  detail: <what happened, in systems terms>
  cost: <hours / pipelines blocked / incidents — keep it factual>
  prior_signal: <was this in a previous retro? — cross-check {followup_status}>
```

If `prior_signal` is non-empty, this is **compounding debt**: flag it for step 4.

Bind to `{struggles}`.

### 3. Surprises

**HALT.** Ask:

> What surprised you? Both kinds count:
> - Positive: a tool that turned out faster than expected, a query that ran in seconds when you feared minutes.
> - Negative: a source schema that changed silently, a write strategy that performed worse than predicted, a partition that grew faster than modeled.

For each surprise:

```yaml
- title: <one line>
  detail: <what was expected, what happened>
  polarity: positive | negative
  implication: <what this changes about future planning>
```

Bind to `{surprises}`.

### 4. Save

Update the output file with the three blocks. Append `3` to `stepsCompleted`. Save.

## Checkpoint

> Captured: `{wins.length}` wins, `{struggles.length}` struggles, `{surprises.length}` surprises.
> Compounding debt detected: `<n>` struggles match prior retros.
>
> Ready to look for cross-cutting patterns? (y/n)

**HALT.**

## Next

Read fully and follow: `step-04-patterns.md`
