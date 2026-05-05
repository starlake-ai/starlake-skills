---
risks: []
sign_off: false
---

# Step 7: Risks, Sign-off, Finalize

## Rules

- Do not skip risks. A pipeline spec without a risks section is half a spec.
- Sign-off flips `status` from `draft` to `ready-for-dev`. Do not flip without an explicit user confirmation.

## Preconditions

- Steps 1–6 complete (or steps 4 explicitly skipped with `load only` note).

## Instructions

1. **Risks & Mitigations.** Walk through this checklist and ask the user about any that aren't already obvious from the spec:
   - **Source instability**: schema drift in `jdbc`/`rest`, file naming changes, API rate-limit changes.
   - **Volume surprises**: what happens at 10× current row count? What's the `dagrun_timeout` headroom?
   - **Late data**: does the write strategy + partition column tolerate records arriving after the partition window?
   - **PII exposure**: every `HIDE`/`SHA256`/`MD5`/`AES`-annotated column reviewed?
   - **Cost**: full-scan transforms on big tables, expensive cross-region reads, cold-storage rehydration.
   - **Recovery**: if the pipeline fails halfway through, what's the rollback? Is it idempotent?

   For each real risk, write into `## Risks & Mitigations`:

   | Risk | Impact | Mitigation |
   |------|--------|------------|
   | <risk> | <H/M/L> | <action> |

   Append each risk title to `risks` frontmatter.

2. **Implementation checklist.** Append a `## Ready-for-Dev Checklist` section:
   - [ ] All connection refs resolve to a defined connection
   - [ ] Every load table has at least one expectation
   - [ ] Every transform task has at least one expectation
   - [ ] DAG schedule satisfies the SLA
   - [ ] No secrets inlined anywhere in the spec
   - [ ] Risks reviewed with owner

3. **Sign-off prompt.**

   > **Spec complete.** `<n>` load tables, `<m>` transforms, `<k>` connections, `<r>` risks documented.
   >
   > Confirm sign-off and flip status to `ready-for-dev`? (y/n)

   **HALT.**

   - On `y`: set frontmatter `status: ready-for-dev`, set `sign_off: true`, append `7` to `stepsCompleted`, save.
   - On `n`: ask what to revise. Stay on this step (or jump back to a prior step explicitly).

4. **Hand-off.**

   Once signed off, present:

   > **Done.** Spec written to `{{spec_file}}`.
   >
   > **Next steps:**
   > 1. Run `starflow-sprint-planning` to break implementation into tasks.
   > 2. Or run `starflow-dev-pipeline` to start implementation immediately if the team prefers single-pipeline flow.
   > 3. Run `starflow-code-review` once implementation is up.

## Save

The spec frontmatter at the end should look like:

```yaml
---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7]
inputDocuments: [...]
date: <date>
author: <user_name>
pipeline_name: <name>
domain: <domain>
status: ready-for-dev
risks: [...]
sign_off: true
---
```

## Outcome

A `ready-for-dev` pipeline spec, ready to be consumed by `starflow-dev-pipeline` or broken down by `starflow-sprint-planning`.
