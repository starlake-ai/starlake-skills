---
epic_id: ''            # set in this step (e.g. "epic-3" or "2026-q2-onboarding")
epic_artifacts: []     # set in this step: pipeline specs, sprint plans, code reviews tied to this epic
previous_retro: ''     # path to most recent prior retrospective, or empty
sprint_status_file: '{implementation_artifacts}/sprint-status.yaml'
output_file: ''        # set in this step
---

# Step 1 — Discover the Epic

## Rules

- Speak in `{communication_language}`.
- Do not invent an epic ID. If you can't find one, ask.

## Instructions

### 1. Find the completed epic

Walk this cascade in order, stop on first hit:

**Tier 1 — Sprint status.** Load `{sprint_status_file}` if it exists. Find the highest-numbered epic where every story is `done` (or all but a few minor ones). Set `{epic_id}` to that epic's identifier.

**Tier 2 — Pipeline specs.** Scan `{implementation_artifacts}/pipeline-spec-*.md` for files with `status: done` and group by epic frontmatter (or by date range if no epic field). Pick the most recent group.

**Tier 3 — Recent reviews.** Scan `{implementation_artifacts}/review-*.md` from the last 6 weeks; group by referenced spec.

**Tier 4 — Ask.** **HALT.**

> Which epic should we retro? Options I detected:
> 1. `{candidate1}` — N stories, last activity {date}
> 2. `{candidate2}` — …
> 3. Something else (paste the epic id or pipeline names)

Set `{epic_id}` from the user's choice.

### 2. Verify completion (no blame, just facts)

Pull all stories / pipelines tied to `{epic_id}`:
- Total count
- Done count
- In-progress / blocked count

If not all are done:

> Heads up — `{epic_id}` has `<n>` items still open: `{list}`. Retros work best after completion. Options:
> 1. Run a partial retro — useful but limited.
> 2. Postpone until those close.
> 3. Treat the open items as themselves a struggle and proceed (this is a real signal).

**HALT** for the user's choice. Note the choice in the output file's frontmatter (`completion_state: full | partial | proceed-with-incomplete`).

### 3. Locate the previous retrospective

Glob `{implementation_artifacts}/retrospectives/retrospective-epic-*.md` (excluding any in-progress one for the current epic). Pick the most recent by frontmatter date.

- If found: bind to `{previous_retro}`. Tell the user: "I'll pull `{prev_epic}`'s action items in step 2 and check follow-through."
- If none: tell the user: "This is the first retrospective in `{project_name}` — no prior action items to check. We'll skip step 2."

### 4. Gather artifacts

Bind `{epic_artifacts}` to the list of:
- All pipeline specs in this epic
- Sprint plans referencing them
- Code-review reports referencing them
- Quality reviews
- Any incident notes or post-mortem docs (look in `{project_knowledge}` if configured)

Read enough of each to be conversant — don't paste them into context wholesale.

### 5. Initialize the output file

Set `{output_file} = {implementation_artifacts}/retrospectives/retrospective-epic-{epic_id}.md`.

Create it (or copy from a template) with this frontmatter shape:

```yaml
---
stepsCompleted: [1]
epic_id: {epic_id}
date: {date}
author: {user_name}
project_name: {project_name}
status: in-progress
completion_state: full | partial | proceed-with-incomplete
previous_retro: {previous_retro}        # empty if none
epic_artifacts: [{epic_artifacts}]
followup_status: []                     # filled in step 2
wins: []                                # filled in step 3
struggles: []                           # filled in step 3
surprises: []                           # filled in step 3
patterns: []                            # filled in step 4
action_items: []                        # filled in step 5
next_epic_risks: []                     # filled in step 6
---

# Retrospective — {epic_id}

(body filled progressively by each step)
```

Save.

## Checkpoint

> **Epic:** `{epic_id}` — `<n>` artifacts found, completion state `<state>`.
> **Previous retro:** `{previous_retro}` (or "none — first retro").
>
> Ready to check follow-through? (y/n)

**HALT.** On `y`, proceed.

## Next

If `{previous_retro}` is set: read fully and follow `step-02-followup.md`.
Otherwise: skip to `step-03-wins-struggles.md` and add `2` to `stepsCompleted` (with note "skipped — no prior retro").
