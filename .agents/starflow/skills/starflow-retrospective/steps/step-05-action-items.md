---
action_items: []
---

# Step 5: Action Items

## Rules

- Every action item has an **owner** (a name, not a team) and a **target epic**.
- Every action item has a **success criterion**: how we'll know in the next retro whether it landed.
- "Do better at X" is not an action item. "Add a partition-strategy review checklist to step-03 of `starflow-create-pipeline-spec` by epic-N+1" is.
- Cap at 5 new items. If more are tempting, the team is over-committing — pick the top 5 and explicitly note the rest as deferred.

## Instructions

### 1. Carry-forwards become drafts

For every item in `{followup_status}` with `carry_forward: true`, pre-fill an action-item draft:

```yaml
- id: <new sequential>
  description: <updated wording — make it more specific based on what we learned>
  source: carry-forward from {previous_retro}
  prior_id: <previous_id>
  draft: true
```

These are starting points; the user will refine them below.

### 2. Generate new candidates from patterns

For each pattern in `{patterns}`, propose at least one action item:

```yaml
- id: <new sequential>
  description: <concrete deliverable that addresses the root cause>
  source: pattern: {pattern.name}
  draft: true
```

Compounding patterns get an explicit "elevated priority" tag.

### 3. Walk through the candidates with the user

Present the draft list. **HALT.** For each:

> Action `<id>`: **{description}** (source: {source})
>
> 1. Accept as-is.
> 2. Refine the description (paste new wording).
> 3. Drop (with reason).

For accepted items, prompt for:

- **Owner**: a single name. "The team" is not an owner.
- **Target epic**: which epic should this land in?
- **Success criterion**: one sentence — what artifact or measurement proves this got done?
- **Follow-up date**: explicit calendar date for next-retro check.

Capture each as:

```yaml
- id: <id>
  description: <final wording>
  owner: <name>
  target_epic: <id>
  success_criterion: <one sentence>
  follow_up_date: <YYYY-MM-DD>
  source: <pattern: name | carry-forward from {previous_retro} | new>
  prior_id: <previous_id or empty>
  priority: normal | elevated   # elevated for compounding-debt items
```

### 4. Cap at 5

If more than 5 items survived, **HALT** and ask the user to pick the top 5. Note the deferred ones in the output file under a "## Deferred from this retro" section — they should be re-considered at next retro.

### 5. Save

Update `{action_items}`. Append `5` to `stepsCompleted`. Save.

## Checkpoint

> **Action items committed:** `{action_items.length}` (cap is 5).
> - Carry-forwards: `<c>`
> - From patterns: `<p>`
> - Elevated (compounding): `<e>`
>
> Ready to seed the next epic's risks? (y/n)

**HALT.**

## Next

Read fully and follow: `step-06-next-epic-prep.md`
