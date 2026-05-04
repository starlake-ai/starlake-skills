#!/usr/bin/env python3
"""
Resolve Starflow's central config using layered YAML merge.

Reads from three layers (highest priority last — overrides win):
  1. {starflow-root}/config/starflow.yaml              (installer base, read-only)
  2. {starflow-root}/config/custom/starflow.yaml       (team, committed)
  3. {starflow-root}/config/custom/starflow.user.yaml  (personal, gitignored)

Outputs merged JSON to stdout. Errors go to stderr.

Requires Python 3.7+ and PyYAML (`pip install pyyaml`). Most data-engineering
environments already have it (pandas, dbt, airflow, dagster all depend on it).

Usage:
  python3 resolve_config.py --starflow-root /abs/path/to/.agents/starflow
  python3 resolve_config.py --starflow-root ... --key default_engine
  python3 resolve_config.py --starflow-root ... --key agents

Merge rules (purely structural — no field-name special-casing):
  - Scalars (str, int, bool, float, None): override wins
  - Mappings: deep merge (recursively apply these rules)
  - Sequences of mappings where every item shares the *same* identifier
    field (every item has `code`, or every item has `id`):
    merge by that key (matching keys replace, new keys append)
  - All other sequences — including sequences where only some items have
    `code` or `id`, or where items mix the two keys:
    append (base items followed by override items)

No removal mechanism — overrides cannot delete base items. To suppress
a default, override the item by code with a no-op value.
"""

import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write(
        "error: PyYAML is required. Install with: pip install pyyaml\n"
        "(Most data-engineering environments already have it via pandas, dbt, etc.)\n"
    )
    sys.exit(3)


_MISSING = object()
_KEYED_MERGE_FIELDS = ("code", "id")


def load_yaml(file_path: Path, required: bool = False) -> dict:
    if not file_path.exists():
        if required:
            sys.stderr.write(f"error: required config file not found: {file_path}\n")
            sys.exit(1)
        return {}
    try:
        with file_path.open("r", encoding="utf-8") as f:
            parsed = yaml.safe_load(f)
        if parsed is None:
            return {}
        if not isinstance(parsed, dict):
            level = "error" if required else "warning"
            sys.stderr.write(f"{level}: {file_path} did not parse to a mapping\n")
            if required:
                sys.exit(1)
            return {}
        return parsed
    except yaml.YAMLError as error:
        level = "error" if required else "warning"
        sys.stderr.write(f"{level}: failed to parse {file_path}: {error}\n")
        if required:
            sys.exit(1)
        return {}
    except OSError as error:
        level = "error" if required else "warning"
        sys.stderr.write(f"{level}: failed to read {file_path}: {error}\n")
        if required:
            sys.exit(1)
        return {}


def _detect_keyed_merge_field(items):
    """Return 'code' or 'id' if every mapping item carries that *same* field.

    Mixed arrays — where some items use `code` and others use `id` —
    return None and fall through to append semantics. Mixing identifier
    keys within one array is a schema smell; append-fallback is safer
    than guessing which key should merge.
    """
    if not items or not all(isinstance(item, dict) for item in items):
        return None
    for candidate in _KEYED_MERGE_FIELDS:
        if all(item.get(candidate) is not None for item in items):
            return candidate
    return None


def _merge_by_key(base, override, key_name):
    result = []
    index_by_key = {}
    for item in base:
        if not isinstance(item, dict):
            continue
        if item.get(key_name) is not None:
            index_by_key[item[key_name]] = len(result)
        result.append(dict(item))
    for item in override:
        if not isinstance(item, dict):
            result.append(item)
            continue
        key = item.get(key_name)
        if key is not None and key in index_by_key:
            # Deep-merge per-item so partial overrides (e.g. just changing
            # an icon) don't have to repeat every field.
            existing = result[index_by_key[key]]
            result[index_by_key[key]] = deep_merge(existing, item)
        else:
            if key is not None:
                index_by_key[key] = len(result)
            result.append(dict(item))
    return result


def _merge_arrays(base, override):
    base_arr = base if isinstance(base, list) else []
    override_arr = override if isinstance(override, list) else []
    keyed_field = _detect_keyed_merge_field(base_arr + override_arr)
    if keyed_field:
        return _merge_by_key(base_arr, override_arr, keyed_field)
    return base_arr + override_arr


def deep_merge(base, override):
    if isinstance(base, dict) and isinstance(override, dict):
        result = dict(base)
        for key, over_val in override.items():
            if key in result:
                result[key] = deep_merge(result[key], over_val)
            else:
                result[key] = over_val
        return result
    if isinstance(base, list) and isinstance(override, list):
        return _merge_arrays(base, override)
    return override


def extract_key(data, dotted_key: str):
    parts = dotted_key.split(".")
    current = data
    for part in parts:
        if isinstance(current, dict) and part in current:
            current = current[part]
        else:
            return _MISSING
    return current


def main():
    parser = argparse.ArgumentParser(
        description="Resolve Starflow central config using layered YAML merge.",
    )
    parser.add_argument(
        "--starflow-root", "-s", required=True,
        help="Absolute path to the Starflow root (contains config/starflow.yaml)",
    )
    parser.add_argument(
        "--key", "-k", action="append", default=[],
        help="Dotted field path to resolve (repeatable). Omit for full dump.",
    )
    args = parser.parse_args()

    starflow_root = Path(args.starflow_root).resolve()
    config_dir = starflow_root / "config"
    custom_dir = config_dir / "custom"

    base = load_yaml(config_dir / "starflow.yaml", required=True)
    team = load_yaml(custom_dir / "starflow.yaml")
    user = load_yaml(custom_dir / "starflow.user.yaml")

    merged = deep_merge(base, team)
    merged = deep_merge(merged, user)

    if args.key:
        output = {}
        for key in args.key:
            value = extract_key(merged, key)
            if value is not _MISSING:
                output[key] = value
    else:
        output = merged

    sys.stdout.write(json.dumps(output, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
