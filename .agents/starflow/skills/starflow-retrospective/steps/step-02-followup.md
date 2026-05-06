---
followup_status: []  # set in this step: list of {action, status, evidence, blockers, carry_forward}
---

# Step 2: Follow-Through on Previous Retro's Actions

## Rules

- This is the most important step in the workflow. Skipping it lets debt compound.
- For each prior action item, evidence beats memory. Cite the artifact.
- "Dropped" is a legitimate status: but it must come with a reason, not a shrug.

## Preconditions

- `{previous_retro}` is set.

## Instructions

### 1. Load the prior retro's action items

Read `{previous_retro}`. Extract the `action_items` array from the frontmatter, or parse the "## Action Items" section in the body. Each prior action should have:
- `id` (or sequential number)
- `description`
- `owner`
- `target_epic` (which epic it was meant to land in)

If the retro is unparseable in either form, fall back: read the whole "## Action Items" section as prose, ask the user to confirm what was committed.

### 2. Walk each item

For each prior action item, **HALT** and ask the user:

> Action `{prior_id}`: **{description}** (owner: {owner}, target: {target_epic})
>
> What's its status?
> 1. **Done**: paste evidence (commit, PR, file path, deployed pipeline name).
> 2. **Partial**: what got done, what didn't, and why.
> 3. **Dropped**: why it was de-prioritized.
> 4. **Carry-forward**: still relevant but didn't land; should re-up as a new action item with the same or updated wording.

Capture per item:

```yaml
- id: {prior_id}
  description: {description}
  prior_owner: {owner}
  status: done | partial | dropped | carry-forward
  evidence: <link or path or "self-reported">
  blockers: <if partial/dropped, what got in the way>
  carry_forward: true | false
```

### 3. Detect compounding debt

Cross-check this list against `epic_artifacts`. Flag any of these patterns:

- An action item marked `dropped` whose problem the user *also* lists in this epic's struggles (will be captured in step 3): that's compounding debt; call it out by name in step 4.
- Two consecutive retros where the same theme appears in struggles: root-cause investigation needed.
- Prior actions where `target_epic` is `{epic_id}` (this epic) and status is anything other than `done`: follow-through is breaking down for this current cycle.

Save these observations into a memo for step 4: don't surface them yet.

### 4. Surface to the user

Summarize:

> **Previous retro (`{previous_retro}`) follow-up:**
> - Done: `<n>`
> - Partial: `<n>`
> - Dropped: `<n>` (reasons: `<short list>`)
> - Carry-forward: `<n>` (will become new action items in step 5)

Bind `{followup_status}` to the captured list. Append `2` to `stepsCompleted`. Save the output file with the followup_status block.

## Next

Read fully and follow: `step-03-wins-struggles.md`
