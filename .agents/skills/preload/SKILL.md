---
name: preload
description: Check for files available for loading in the landing/pending area
---

# PreLoad Skill

Checks for files available for loading in the landing or pending area. This is useful for orchestration to determine whether files are ready before triggering the actual load process.

## Usage

```bash
starlake preload [options]
```

## Options

- `--domain <value>`: Domain to check (required)
- `--tables <value>`: Comma-separated tables to check. With `imported`, omitted = all tables in the domain; with `pending`, only the tables you pass are counted — omitting `--tables` yields an empty (never-ready) result, so always pass them
- `--strategy <value>`: Pre-load strategy: `imported`, `pending`, or `ack` (case-insensitive here, but use lowercase — the orchestration option `pre_load_strategy` accepts ONLY lowercase). Omitted/unknown value = no gating: the check always succeeds
- `--globalAckFilePath <value>`: Path to the global acknowledgment file (required in practice with `--strategy ack` — without it the ack check fails)
- `--notReadySentinel <uri>`: If set, a zero-byte marker is written at this URI when files are not ready, and the command exits 0 (the sentinel is the signal); real errors still exit non-zero. Lets orchestrators distinguish "retry later" from failure. Accepts any storage-handler URI (`gs://`, `s3://`, `file://`, `hdfs://`)
- `--options k1=v1,k2=v2`: Substitution arguments
- `--reportFormat <value>`: `console`, `json`, or `html`

## Strategies — what each one actually checks

| Strategy | Check performed | On success | Pairs with |
|---|---|---|---|
| `imported` | Scans the domain's **incoming directory** and counts stageable files per table | Report of per-table counts; empty = not ready | A following `starlake stage` (import) step, then load — chain `preload >> stage >> load` |
| `pending` | Lists the domain's **pending (staged) area** and counts files matching each table's `pattern` | Per-table counts; empty = not ready | Direct load — files are already staged |
| `ack` | Tests whether `--globalAckFilePath` exists; **if it exists, the file is DELETED** (each ack is consumed exactly once) | Proceed; missing ack = failure (or sentinel) | A producer that re-creates the ack for every delivery |

## Orchestration coupling

Generated and one-off DAGs drive this command through the `pre_load_strategy` job option (`imported`/`ack`/`pending`/`none` — strict lowercase; invalid values raise at DAG definition time). What the framework adds on top of the CLI:

- Strategy `none` creates NO pre-load task at all.
- Task naming: `check_{domain}_incoming_files` (imported), `check_{domain}_pending_files` (pending), `check_{domain}_ack_file` (ack).
- A `skip_or_start` gate follows the pre-load task and skips the downstream load when the check reported nothing to do.
- Canonical chains: `imported` → `pre_load >> skip_or_start >> import >> loads`; `ack`/`pending` → `pre_load >> skip_or_start >> loads`.
- ACK extras: option `global_ack_file_path` (default: `{datasets}/pending/{domain}/{YYYY-MM-DD}.ack` — date-coupled, prefer an explicit path) and `ack_wait_timeout` (seconds, default 3600) which becomes the retry delay of the ack-check task — the "wait" is implemented as task retries, not a sensor.
- Sensor mode: the load DAG options `pre_load_sensor` (default `false`), `pre_load_poke_interval` (default 300 s), `pre_load_timeout` (default 3600 s) and `pre_load_sensor_soft_fail` switch the pre-load task to a poke loop that re-runs this command until files arrive; in sensor mode `ack_wait_timeout` is ignored (`pre_load_timeout` governs the wait).
- Sentinel mode: the load DAG option `pre_load_not_ready_sentinel_path` plugs `--notReadySentinel` into the pre-load task (requires starlake CLI 1.5.15 or newer) so a "not ready" outcome is distinguished from a real failure instead of both reading as "nothing to load".

## Examples

### Check Incoming Files (imported)

```bash
starlake preload --domain starbake --strategy imported
```

### Check Staged Files for Specific Tables (pending — always pass --tables)

```bash
starlake preload --domain starbake --tables orders,products --strategy pending
```

### Check with ACK Strategy (consumes the ack file on success)

```bash
starlake preload --domain starbake --strategy ack --globalAckFilePath /data/pending/starbake/GO.ack
```

### Check with JSON Report

```bash
starlake preload --domain starbake --strategy imported --reportFormat json
```

## Related Skills

- [stage](../stage/SKILL.md) - Move files from landing to pending
- [load](../load/SKILL.md) - Load files into the data warehouse
- [dag-generate](../dag-generate/SKILL.md) - Generated DAGs that set `pre_load_strategy`
- [dag-create](../dag-create/SKILL.md) - One-off DAGs driven by `pre_load_strategy`
- [dag-template-generate](../dag-template-generate/SKILL.md) - Templates and DAG configs that set `pre_load_strategy`
