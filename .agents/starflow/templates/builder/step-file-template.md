---
{{runtime_variable}}: ''  # set in this step
---

# Step {{N}}: {{Step Title}}

## Rules

- {{rule_1}}
- {{rule_2}}

### Scale

- **light**: {{what_collapses_at_light_scale}}
- **deep**: {{what_extra_rigor_at_deep_scale}}

## Preconditions

- Step {{N-1}} complete ({{what_must_exist}}).

## Instructions

1. {{instruction_1}}
2. {{instruction_2}}

## Save

1. Append `{{N}}` to `stepsCompleted`.
2. Save the artifact file.

## Checkpoint

> **{{Recap_label}}:** {{recap_values}}.
>
> {{confirmation_question}} (y/n / revise)

**HALT.** Default: `y`. {{loop_or_proceed_behavior}}

## Next

Read fully and follow: `step-{{N+1}}-{{next_slug}}.md`
