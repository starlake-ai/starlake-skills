---
report_file: '{implementation_artifacts}/review-{date}-{spec_basename}.md'
---

# Step 4: Present and Act

## Rules

- BLOCKERs are presented first, in their entirety. Don't summarize them.
- WARNINGs are listed concisely. SUGGESTIONs collapsed into a count + expandable list.
- APPROVED items only mentioned in a summary line, not as a list.

## Instructions

### 1. Clean review shortcut

If `{findings_unified}` is empty AND `{failed_layers}` is empty:

> **✅ Clean review.** Three reviewers ran in parallel; none raised concerns.
> Diff: `<n>` files, `<+>`/`<->` lines.

Skip to section 5.

If `{findings_unified}` is empty BUT `{failed_layers}` is non-empty:

> ⚠️ **Review incomplete.** `{failed_layers}` reviewer(s) failed; the others raised no findings. This is **not** a clean review — re-run code review or address the failure before deploying.

Skip to section 5.

### 2. Build the report

Compose a Markdown report and write it to `{report_file}` (set `spec_basename` from the spec frontmatter, or `<diff-source>` if no spec was provided):

```markdown
---
date: {date}
spec_file: {spec_file}
review_mode: {review_mode}
reviewers: winston, amelia, quinn
failed_reviewers: {failed_layers}
counts:
  blocker: <B>
  warning: <W>
  suggestion: <S>
  approved: <A>
  dismissed: <D>
---

# Pipeline Code Review: {date}

## BLOCKERS (<B>)

For each BLOCKER, full detail:
- **Title**: `<file:line>` — sources: `<source>`
- Detail
- Suggested fix

## WARNINGS (<W>)

Compact list:
- `<file:line>` — title — source

## SUGGESTIONS (<S>)

Compact list (collapsible if rendering supports it):
- `<file:line>` — title

## What was checked

- Architecture (Winston): write strategy, schema evolution, partition design, layer separation, portability.
- Engineering (Amelia): SQL correctness, idempotence, conventions, performance.
- Data Quality (Quinn): expectations coverage, severity, PII annotations, freshness checks, NOT NULL.
```

### 3. If a spec file is set, write findings back to it

Append a `### Review Findings — {date}` subsection to the spec file's "Risks & Mitigations" or "Review" section. Use checkbox format so the implementation skill can track resolution:

```markdown
### Review Findings: {date}

**Blockers** (must fix before status flips to `done`):
- [ ] [Blocker] <title> — `<file:line>`

**Warnings**:
- [ ] [Warning] <title> — `<file:line>`

**Suggestions**:
- [ ] [Suggestion] <title> — `<file:line>`

**Deferred** (pre-existing, not from this change):
- [x] [Defer] <title> — `<file:line>`
```

### 4. Present the summary to the user

> **Code review complete.**
>
> | Reviewer | Findings raised | Status |
> |----------|-----------------|--------|
> | Winston (Architect) | <wA> | <ok / failed> |
> | Amelia (Engineer)   | <wM> | <ok / failed> |
> | Quinn (Data Quality)| <wQ> | <ok / failed> |
>
> **After triage:** `<B>` blockers, `<W>` warnings, `<S>` suggestions, `<D>` dismissed.
>
> Report written to `{report_file}`.
> {if spec_file}: Findings appended to `{spec_file}` under `### Review Findings`.
>
> **Next options:**
> 1. Walk through each blocker now.
> 2. Apply patch suggestions where reviewers proposed concrete fixes (prompts you per finding).
> 3. Defer all and update sprint status.
> 4. Done — close out.

**HALT** for choice.

### 5. Sprint status sync (only if `{spec_file}` set and contains a story key)

If the spec frontmatter has a `story_key` and the sprint status file exists:

- If the review has **0 blockers and 0 warnings** AND the user chose option 4: set the story to `done`.
- If the review has blockers OR warnings AND the user chose anything other than option 1+resolve: set the story to `review-blocked` with a note pointing to `{report_file}`.
- Otherwise: leave the story status alone (user is mid-review).

Always update `last_updated` to `{date}` and preserve all other entries / comments in the YAML.

### 6. Wrap

> **Done.**
> - Report: `{report_file}`
> - Story status: `<status>` (synced) | unchanged
>
> Run `starflow-code-review` again after fixes, or `starflow-retrospective` if this was the last review of the epic.

## Outcome

A persisted review report, optional spec/story write-back, and clear next-step routing.
