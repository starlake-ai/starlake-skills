---
findings_unified: []  # set in this step
---

# Step 3 — Triage

## Rules

- Be precise. When uncertain between categories, prefer the more conservative classification (BLOCKER over WARNING, WARNING over SUGGESTION).
- A finding from two reviewers is stronger evidence — note it in the merged source field.

## Instructions

### 1. Normalize

Convert each reviewer's output to a unified shape:

```yaml
- id: <int>
  source: winston | amelia | quinn | <merged, e.g. winston+quinn>
  title: <one-line summary>
  detail: <full description with rationale>
  location: <file:line, or empty>
  category: <to be set in step 3>
```

Expected input shapes:
- **Winston**: Markdown list with title, file:line, concern, recommendation.
- **Amelia**: JSON array of `{location, trigger_condition, current_code, suggested_fix, severity}`.
- **Quinn**: Markdown list with title, file:line, quality gap, severity, example SQL.

If a reviewer's output doesn't match its expected shape, attempt best-effort parsing and note the parse issue for the user in step 4.

### 2. Deduplicate

If two findings describe the same issue:

- Use the most specific finding as the base (Amelia's JSON with `location` typically wins over Winston/Quinn's prose).
- Append unique detail from the other(s) into the surviving `detail` field.
- Set `source` to the merged sources (e.g. `amelia+quinn`).

### 3. Classify

Each finding goes into exactly one of:

| Category | Meaning |
|----------|---------|
| **BLOCKER** | Must fix before deployment. Wrong write strategy, missing PK uniqueness on a UPSERT table, PII without privacy annotation, secret inlined in YAML, broken SQL. |
| **WARNING** | Should fix; high risk of future incident. Missing expectations on a load table, no row-count check, missing freshness for SLA-critical, schema change that's technically additive but risky. |
| **SUGGESTION** | Improvement, not required. Style nits, naming inconsistencies, suboptimal but correct SQL. |
| **APPROVED** | Aspect that was explicitly checked and passes. Use sparingly — a clean review doesn't need a list of approvals. |
| **DISMISS** | Noise, false positive, or already handled elsewhere. Drops out of the report. |

### Hard rules

These ALWAYS classify as BLOCKER, regardless of severity the reviewer suggested:

- PII-suspicious column (name matches `/email|phone|ssn|name|dob|address|birth/i`) without a privacy annotation.
- Secret value (looks like a password / token / key) inlined in any `*.sl.yml` or `*.sql`.
- Missing PK uniqueness check on `UPSERT_BY_KEY` or `SCD2` table.
- DAG schedule that demonstrably can't satisfy the SLA in the spec.
- Connection ref to a connection name not defined anywhere in the diff or known config.

### 4. Drop dismissed

Drop all `DISMISS` findings. Record the count for the summary.

### 5. Sanity check

If `{failed_layers}` is non-empty AND zero findings remain after dropping dismissed: **warn** the user that the review may be incomplete (one or more reviewers failed), don't announce a clean review.

### 6. Bind

Set `{findings_unified}` = the deduplicated, classified list.

## Next

Read fully and follow: `step-04-present.md`
