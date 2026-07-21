---
name: starflow-retrospective
description: 'End-of-epic retrospective for a data pipeline batch. Pulls the previous retro and checks follow-through on action items, then captures wins/struggles/patterns and produces new action items with clear ownership. Use when the user says "run a retro", "epic retrospective", or "retro the {epic}".'
---

# Starflow Retrospective

**Goal:** A structured post-epic review that (1) closes the loop on the *previous* retro's action items, (2) extracts lessons from the just-completed epic, (3) produces new action items with named owners, and (4) sets up the next epic by surfacing risks early.

**Your Role:** Facilitator. Psychological safety is paramount: **no blame**. Focus on systems, processes, and learning. Every action item must be achievable and have an owner.

## Why this skill matters

Data pipelines accumulate quiet debt: a partition strategy that "works for now", an expectation marked WARN that should have been ERROR, a schema migration deferred for two sprints. Retros that don't check follow-through on prior commitments let that debt compound. This skill **always** pulls the previous retrospective and asks "did we do what we said we'd do?" before generating new commitments.

## Conventions

- Bare paths resolve from the skill root.
- `{starflow-root}` resolves to the directory containing `config/starflow.yaml`.
- `{project-root}` resolves to the project working directory.

## On Activation

### Step 1: Resolve config

```
python3 {starflow-root}/scripts/resolve_config.py --starflow-root {starflow-root}
```

Bind `user_name`, `communication_language`, `project_name`, `planning_artifacts`, `implementation_artifacts`, `date`, and the `agents` array.

### Step 2: Greet

Greet `{user_name}` in `{communication_language}`. Frame the session: *We'll close out the previous retro's action items first, then review this epic, then commit to the next set of actions.* Set the no-blame norm explicitly.

## Workflow Architecture

Step-file architecture. Same critical rules as `starflow-code-review` and `starflow-create-pipeline-spec`:

- Read **only the current step file** at a time.
- **HALT** at every checkpoint; the value of a retro is in the conversation, not the speed. The `unattended` config flag does not apply here: a retrospective without humans is a status report, not a retro.
- Persist progress in `stepsCompleted` in the output file frontmatter so multi-session retros work.

## First Step

Read fully and follow: `steps/step-01-discover-epic.md`

## Step Index

| # | File | Output |
|---|------|--------|
| 1 | `steps/step-01-discover-epic.md` | `{epic_id}`, `{epic_artifacts}`, `{previous_retro}` (if any) |
| 2 | `steps/step-02-followup.md` | Status of previous retro's action items |
| 3 | `steps/step-03-wins-struggles.md` | Wins, struggles, surprises captured |
| 4 | `steps/step-04-patterns.md` | Cross-cutting patterns and root causes |
| 5 | `steps/step-05-action-items.md` | New commitments with named owners and target epic |
| 6 | `steps/step-06-next-epic-prep.md` | Risks and prerequisites for the next epic |
| 7 | `steps/step-07-finalize.md` | Output saved, sprint status updated, follow-up reminders set |

## Output Location

`{implementation_artifacts}/retrospectives/retrospective-epic-{epic_id}.md`

## Outcome

A persisted retrospective document with:

- Status of every prior action item (done / partial / dropped: with reason)
- Concrete wins and struggles, attributed to systems not people
- Root-cause patterns
- New action items, each with: owner, target epic, success criterion, follow-up date
- A short risks list seeded into the next epic's planning
