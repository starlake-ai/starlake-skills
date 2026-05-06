---
patterns: []
---

# Step 4: Cross-Cutting Patterns and Root Causes

## Rules

- Look for patterns *across* wins, struggles, and surprises: not within one bucket.
- Name root causes carefully. "Schema drift surprised us twice" is a pattern; "the data team is bad at communication" is a person attribution and is wrong on its face.
- The compounding-debt list from step 2 is your strongest signal: surface it explicitly here.

## Instructions

### 1. Synthesize candidate patterns

Walk through `{wins} ∪ {struggles} ∪ {surprises}` plus the compounding-debt flags from step 2. Look for:

- **Repeated themes**: "three different pipelines hit partition issues" → partition design pattern is wrong or unclear.
- **Polarity flips**: a pattern that worked in earlier sprints stops working at this scale → context outgrew the pattern.
- **Tooling friction**: same workflow tool friction reported in multiple struggles → process problem, not skill problem.
- **Quality timing**: data-quality issues that landed in prod despite expectations existing → severity choice or coverage gap, not absence.
- **Spec-vs-implementation gap**: struggles that trace back to spec ambiguity → upstream process needs tightening.
- **Compounding debt**: struggles that appeared in a prior retro's `dropped` or `partial` follow-ups → systemic prioritization issue.

### 2. Propose patterns to the user

Present 2–5 candidate patterns. For each:

> **Pattern:** `<name>`
> **Evidence:** `<bullet list of items from wins/struggles/surprises that fit>`
> **Root-cause hypothesis:** `<one sentence, systems-level>`
> **Compounding?** yes / no: `<reference to prior retro if yes>`

**HALT.** Walk through each:

> Pattern `<n>`: does this resonate? Refine the wording, accept it, or strike it.

For each accepted pattern, capture:

```yaml
- name: <name>
  evidence: [<ids from wins/struggles/surprises>]
  root_cause: <one sentence>
  compounding: true | false
  prior_retro_ref: <path or empty>
```

Bind to `{patterns}`.

### 3. Surface the "you should know this" memo

If `{patterns}` includes any compounding ones, present a short standalone callout for the next epic's planning:

> **⚠️ Compounding debt detected:** `<pattern names>`. The next epic's risks list (step 6) should treat these as known-priority risks, not novel discoveries.

Note this for step 6.

### 4. Save

Update the output file. Append `4` to `stepsCompleted`. Save.

## Checkpoint

> Captured `{patterns.length}` patterns, `<m>` of which are compounding from prior retros.
>
> Ready to commit to action items? (y/n)

**HALT.**

## Next

Read fully and follow: `step-05-action-items.md`
