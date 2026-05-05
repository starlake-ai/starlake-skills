---
sign_off: false
---

# Step 7: Finalize

## Rules

- The output file isn't real until it's saved with `status: done` and `stepsCompleted` includes `7`.
- Sprint status is updated last, after the user signs off — partial retros that update sprint status mid-flight produce confusing trails.

## Instructions

### 1. Compose the body

Render the body of `{output_file}` from the captured frontmatter blocks. Use this structure:

```markdown
# Retrospective: {epic_id}

**Date:** {date}
**Author:** {user_name}
**Project:** {project_name}
**Completion state:** {completion_state}
**Previous retro:** {previous_retro or "none"}

## Follow-up on previous retro

(table from `{followup_status}`: id, description, prior owner, status, evidence, blockers)

## Wins

(bulleted list from `{wins}`, with `reusable` items called out)

## Struggles

(bulleted list from `{struggles}`, with `prior_signal` items flagged as compounding)

## Surprises

(bulleted list from `{surprises}`, both polarities)

## Patterns

(numbered list from `{patterns}`, with root-cause hypothesis under each)

## Action Items

(table from `{action_items}`: id, description, owner, target_epic, success_criterion, follow_up_date, priority)

## Deferred from this retro

(if any items were dropped at the cap-of-5 step, list here with reason)

## Next-Epic Risks

(table from `{next_epic_risks}`: title, source, why_now, recommended_mitigation)

## Sign-off

- Facilitator: {user_name}
- Participants: <prompted below>
- Date: {date}
```

### 2. Capture participants

**HALT.** Ask:

> Who participated in this retrospective? (names, comma-separated)

Append to the Sign-off section.

### 3. Sign-off prompt

> **Retrospective complete.** Summary:
> - Wins: `{wins.length}`
> - Struggles: `{struggles.length}` (`<c>` compounding)
> - Patterns: `{patterns.length}`
> - Action items: `{action_items.length}` (`<e>` elevated)
> - Next-epic risks: `{next_epic_risks.length}`
>
> Sign off and flip status to `done`? (y/n)

**HALT.**

- On `y`: set `status: done`, `sign_off: true`, append `7` to `stepsCompleted`. Save.
- On `n`: ask which step to revise, jump back to that step, leave `status: in-progress`.

### 4. Sprint status sync

If `{sprint_status_file}` exists and contains an `epic-{epic_id}-retrospective` entry (or similar):

- Update its status to `done`.
- Set `last_updated` to `{date}`.
- Preserve all other entries and comments.

If no such entry exists, skip silently — the retro file itself is the artifact.

### 5. Action-item reminders (optional, best-effort)

For each action item with a `follow_up_date`, suggest the user create a calendar reminder or schedule entry. If a `schedule` skill is installed, offer to schedule a Claude Code reminder; otherwise just print:

> 📅 **Reminder candidates:**
> - `{owner}` — `{description}` — by `{follow_up_date}`
> - …

### 6. Hand-off

> **Done.** Retrospective saved to `{output_file}`.
>
> **Next steps:**
> 1. Send the action items to their owners (link the file).
> 2. Run `starflow-create-pipeline-spec` for the next epic — the seeded risks will be referenced.
> 3. Schedule the next retro now (target: end of next epic).

## Outcome

A persisted, signed-off retrospective. The next epic's planning will inherit its risks; the retro after that will check follow-through on its action items.
