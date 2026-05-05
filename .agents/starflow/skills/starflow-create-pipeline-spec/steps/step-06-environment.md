---
connections: []  # set in this step: list of named connections
---

# Step 6: Environment Configuration

## Rules

- Environment parity: the only thing that should change between dev / staging / prod is the **value** of a connection setting, never the **shape** of the config.
- Secrets live in env vars or a secret manager — never inline in the spec, never in `env.PROD.sl.yml`.

## Preconditions

- Step 5 complete. All connection names referenced in extract/load/transform/orchestrate are known.

## Instructions

1. **Enumerate connections** referenced anywhere in the spec (`connectionRef`, sink connections, source DBs). For each, capture:
   - Name
   - Type: `jdbc` / `bigquery` / `snowflake` / `duckdb` / `redshift` / `kafka` / `s3` / etc.
   - Per-environment values (URL / project / dataset / path), with secrets as env-var **references** (e.g. `${SNOWFLAKE_PASSWORD}`).

2. **Write three blocks** under `## Environment Configuration`:

   ```yaml
   # env.sl.yml — base / dev defaults
   connections:
     <conn>:
       type: "<type>"
       options:
         url: "<dev value>"
   ```

   ```yaml
   # env.STAGING.sl.yml — only the keys that differ from base
   connections:
     <conn>:
       options:
         url: "<staging value>"
   ```

   ```yaml
   # env.PROD.sl.yml — only the keys that differ from base
   connections:
     <conn>:
       options:
         url: "<prod value>"
         password: "${SECRET_REF}"
   ```

3. **Document required env vars** in a small table at the bottom of the section:

   | Env var | Used by | Where to source |
   |---------|---------|-----------------|
   | `SNOWFLAKE_PASSWORD` | warehouse connection | secret manager / CI |

4. Append every connection name to `connections` in this step's frontmatter.

## Save

1. Append `6` to `stepsCompleted`.
2. Save the spec file.

## Checkpoint

> **Environments defined:** `<n>` connections across dev/staging/prod. `<m>` secrets referenced (none inlined).
>
> Ready to finalize? (y/n / revise)

**HALT.**

## Next

Read fully and follow: `step-07-finalize.md`
