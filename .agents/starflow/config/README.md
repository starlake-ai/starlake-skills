# Starflow Config: Layered Customization

Starflow uses a three-layer config model. Higher layers override lower ones.

| # | File | Scope | Tracked? |
|---|------|-------|----------|
| 1 | `config/starflow.yaml` | Installer base: defaults shipped with the bundle | committed (read-only) |
| 2 | `config/custom/starflow.yaml` | Team policies (engines, governance, persona pinning) | committed |
| 3 | `config/custom/starflow.user.yaml` | Personal tweaks (user name, language, preferences) | **gitignored** |

Skills can also have their own customization. For a skill at `skills/<name>/`, the resolver merges:

1. `skills/<name>/customize.yaml` (skill defaults)
2. `config/custom/<name>.yaml` (team override for this skill)
3. `config/custom/<name>.user.yaml` (personal override, gitignored)

## Resolving config at runtime

```bash
# Full merged config:
python3 .agents/starflow/scripts/resolve_config.py \
  --starflow-root .agents/starflow

# A specific dotted key:
python3 .agents/starflow/scripts/resolve_config.py \
  --starflow-root .agents/starflow --key default_engine

# Skill-level customization:
python3 .agents/starflow/scripts/resolve_customization.py \
  --skill .agents/starflow/skills/starflow-code-review --key workflow
```

Output is JSON to stdout; errors to stderr. Requires Python 3.7+ and PyYAML
(`pip install pyyaml`: most data-engineering environments already have it).

## Merge semantics

Pure structural rules: no field-name special-casing:

- **Scalars** (string, number, bool, null): override wins.
- **Mappings**: deep merge (recurse).
- **Sequences of mappings** where every item carries the same identifier
  field (every item has `code`, or every item has `id`): merge by that key —
  matching keys deep-merge, new keys append. This is what lets you tweak one
  agent's `description` without re-listing all five.
- **All other sequences** (mixed, scalars, etc.): append (base then override).

There is **no removal mechanism**. To suppress a default, override the item
by `code` with a no-op value, or fork the base file.

## Examples

### Team policy: pin a stricter QA tone

`config/custom/starflow.yaml`:

```yaml
agents:
  - code: data-quality-engineer
    description: "Strict severity bias: when in doubt, FAIL not WARN."
```

Only the `description` of that agent is replaced; the rest of the entry
(`name`, `title`, `icon`) carries through from base.

### Personal: change name and engine

`config/custom/starflow.user.yaml` (copy from `.example`):

```yaml
user_name: Hayssam
communication_language: french
default_engine: duckdb
```

### Why YAML, not TOML?

The base `starflow.yaml` was already YAML. The merge logic is identical to
BMAD's TOML-based resolver (`scalars override, mappings deep-merge, keyed
arrays merge by code/id`); only the file format differs.
