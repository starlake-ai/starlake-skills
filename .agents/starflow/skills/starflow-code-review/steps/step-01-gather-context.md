---
diff_output: ''     # set at runtime
spec_file: ''       # set at runtime (path or empty)
review_mode: ''     # set at runtime: "full" | "no-spec"
sprint_status_file: '{implementation_artifacts}/sprint-status.yaml'
---

# Step 1: Gather Context

## Rules

- The prompt that triggered this skill IS your starting point: not a blank slate.
- Do not modify any files in this step. Read-only.
- Speak in `{communication_language}`.

## Find the review target

Walk this cascade in order. **Stop as soon as the target is identified.**

### Tier 1: Explicit argument

Did the user pass a PR, commit SHA, branch, spec file, or diff source in this message?

- **PR reference** → resolve to branch/commit via `gh pr view`. If `gh` fails, ask for SHA or branch.
- **Commit / branch** → use directly.
- **Spec file path** → set `{spec_file}`. Check its frontmatter for `baseline_commit`. If found, use as diff baseline. If not, continue the cascade (a spec alone doesn't identify a diff source).

Also scan for diff-mode keywords:
- "staged" / "staged changes" → staged only
- "uncommitted" / "working tree" / "all changes" → uncommitted (staged + unstaged)
- "branch diff" / "vs main" / "against main" / "compared to <branch>" → branch diff
- "commit range" / "last N commits" / "<sha>..<sha>" → commit range
- "this diff" / "provided diff" / "paste" → user-provided diff

### Tier 2: Recent conversation

Do the last few messages reveal what the user wants reviewed? Spec paths, commit refs, branches, PRs, descriptions of a change. Apply same keyword scan.

### Tier 3: Sprint tracking

Look for `*sprint-status*` in `{implementation_artifacts}` or `{planning_artifacts}`. Scan for stories with status `review`:

- **Exactly one `review` story**: suggest it: "Found story `<id>` in `review`. Review its changes? [Y/n]". On yes, derive the diff source from the story (branch name from slug, or uncommitted).
- **Multiple `review` stories**: present numbered options + manual choice. **HALT** for selection.
- **None**: fall through.

### Tier 4: Current git state

If git is available and HEAD is not on `main` (or default), confirm: "HEAD is `<sha>` on `<branch>`: review this branch's changes vs main?" On yes, use as branch diff.

### Tier 5: Ask

Fall through to the explicit ask below.

## Explicit ask (only if Tiers 1–4 didn't resolve)

**HALT.** Ask:

> What do you want to review?
> 1. **Uncommitted changes** (staged + unstaged)
> 2. **Staged changes only**
> 3. **Branch diff** vs a base branch (which?)
> 4. **Specific commit range**
> 5. **Provided diff or file list** (paste path or content)

## Construct `{diff_output}`

- staged only → `git diff --cached`
- uncommitted → `git diff HEAD`
- branch diff → verify base branch exists, then `git diff <base>...HEAD`
- commit range → verify range resolves, then `git diff <range>`
- provided diff → validate non-empty and parseable as unified diff
- file list → `git diff HEAD -- <paths>`. For untracked files: `git diff --no-index /dev/null <path>`. If diff is empty (files have no changes and aren't untracked), ask whether to review full file contents or specify a baseline.

After construction, verify `{diff_output}` is non-empty. If empty, **HALT** and tell the user there's nothing to review.

## Set the spec context

- If `{spec_file}` is set: verify it exists and is readable, then `{review_mode} = "full"`.
- Otherwise ask: "Is there a pipeline spec or story file that provides context? (paste path or 'no')"
  - If yes: set `{spec_file}`, verify, `{review_mode} = "full"`.
  - If no: `{review_mode} = "no-spec"`.

If `{review_mode} = "full"` and the spec frontmatter has a `context` field listing additional docs, load each. Warn about any docs that can't be found.

## Sanity-check size

If `{diff_output}` exceeds ~3000 lines, warn and offer to chunk by file group. **HALT** for choice.

## Filter to data-pipeline files

For Starlake reviews, focus the diff on:

- `**/*.sl.yml` (load, transform, domain config)
- `**/*.sql` (transform queries)
- `metadata/**` (Starlake metadata tree)
- `dags/**` and `*dag*template*` (orchestration)
- `env*.sl.yml` (environment configs)

Mention any non-pipeline files in the diff but exclude them from the parallel reviews unless the user objects. They're typically tests, docs, or unrelated code that the data reviewers shouldn't grade.

## Checkpoint

Present a summary:

> **Review scope:** `<n>` files changed (`<+adds>` / `<-dels>`), mode `{review_mode}`, spec `{spec_file}` (if set).
> **In scope:** `<file list, capped at 10>`
> **Excluded:** `<non-pipeline file count>` non-pipeline files.
>
> Proceed with parallel review? (y/n)

**HALT.** On `y`, proceed. On `n`, ask what to adjust.

## Next

Read fully and follow: `step-02-parallel-review.md`
