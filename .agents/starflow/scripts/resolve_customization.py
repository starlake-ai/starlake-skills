#!/usr/bin/env python3
"""
Resolve customization for a single Starflow skill using three-layer YAML merge.

Reads from three layers (highest priority last):
  1. {skill-root}/customize.yaml                         (skill defaults)
  2. {starflow-root}/config/custom/{skill-name}.yaml      (team, committed)
  3. {starflow-root}/config/custom/{skill-name}.user.yaml (personal, gitignored)

Skill name is the basename of the skill directory.

Outputs merged JSON to stdout. Errors go to stderr.

Requires Python 3.7+ and PyYAML.

Usage:
  python3 resolve_customization.py --skill /abs/path/to/skill-dir
  python3 resolve_customization.py --skill ... --key workflow
  python3 resolve_customization.py --skill ... --key agent.menu

Merge rules: see resolve_config.py — same semantics.
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
    )
    sys.exit(3)

# Reuse the merge core from resolve_config.py by importing it. Fall back
# to inline implementations if the sibling script isn't on sys.path so this
# file remains usable when shipped standalone.
_HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE))
from resolve_config import deep_merge, extract_key, load_yaml, _MISSING  # noqa: E402


def find_starflow_root(start: Path):
    """Walk up from the skill directory looking for the Starflow root.

    The Starflow root is the directory containing `config/starflow.yaml`.
    Symlinked skill directories (the install model) are followed.
    """
    current = start.resolve()
    while True:
        if (current / "config" / "starflow.yaml").exists():
            return current
        parent = current.parent
        if parent == current:
            return None
        current = parent


def main():
    parser = argparse.ArgumentParser(
        description="Resolve customization for a Starflow skill using layered YAML merge.",
    )
    parser.add_argument(
        "--skill", "-s", required=True,
        help="Absolute path to the skill directory (must contain customize.yaml)",
    )
    parser.add_argument(
        "--key", "-k", action="append", default=[],
        help="Dotted field path to resolve (repeatable). Omit for full dump.",
    )
    args = parser.parse_args()

    skill_dir = Path(args.skill).resolve()
    skill_name = skill_dir.name
    defaults_path = skill_dir / "customize.yaml"
    defaults = load_yaml(defaults_path, required=True)

    starflow_root = find_starflow_root(skill_dir) or find_starflow_root(Path.cwd())
    team = {}
    user = {}
    if starflow_root:
        custom_dir = starflow_root / "config" / "custom"
        team = load_yaml(custom_dir / f"{skill_name}.yaml")
        user = load_yaml(custom_dir / f"{skill_name}.user.yaml")

    merged = deep_merge(defaults, team)
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
