---
next_epic_risks: []
---

# Step 6 — Seed the Next Epic

## Rules

- This is *prep*, not planning. The goal is a short risks list the next epic's `starflow-create-pipeline-spec` and `starflow-sprint-planning` should treat as known-priority.
- Compounding-debt patterns from step 4 land here automatically.
- Don't speculate beyond what the retro evidenced.

## Instructions

### 1. Auto-seed from compounding patterns

For each pattern in `{patterns}` with `compounding: true`, add to `{next_epic_risks}`:

```yaml
- title: <pattern name>
  source: compounding-debt from {epic_id} retro
  why_now: <one sentence — why this is more urgent now than last time>
  recommended_mitigation: <link to the action item from step 5 that addresses it>
```

### 2. Surface negative surprises with implications

For each surprise in `{surprises}` with `polarity: negative` and `implication` non-empty, ask:

> Surprise `{title}` had implication: `{implication}`. Should this be a risk for the next epic? (y/n)

For each `y`, append:

```yaml
- title: <surprise title>
  source: surprise from {epic_id} retro
  why_now: <implication>
  recommended_mitigation: <one-sentence recommendation>
```

### 3. Ask for additional risks

**HALT.** Ask:

> Anything else the next epic should know about that didn't fit a pattern? Common candidates:
> - Source systems with planned changes (DB upgrades, API deprecations).
> - Capacity ceilings approaching (warehouse storage, compute slots).
> - Team-context shifts (people leaving, joining, on-call rotation changes).
> - Vendor / cost pressures.

For each:

```yaml
- title: <one line>
  source: forward-looking
  why_now: <why this matters for the next epic specifically>
  recommended_mitigation: <one-sentence recommendation, or "investigate during planning">
```

Cap at ~5 risks total — the goal is a useful prep memo, not a fear list.

### 4. Save

Update `{next_epic_risks}`. Append `6` to `stepsCompleted`. Save.

## Checkpoint

> **Next-epic risks seeded:** `{next_epic_risks.length}`. These will surface in the next epic's `starflow-create-pipeline-spec` and `starflow-sprint-planning`.
>
> Ready to finalize? (y/n)

**HALT.**

## Next

Read fully and follow: `step-07-finalize.md`
