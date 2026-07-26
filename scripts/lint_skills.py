#!/usr/bin/env python3
"""Structural linter for the starlake-skills bundle (stdlib only).

Checks:
  1. every skill directory ships a SKILL.md
  2. frontmatter: name (or legacy skill_name) matches the directory; description non-empty
  3. relative ../<skill>/SKILL.md links resolve
  4. README Skills Catalog lists every core skill; if the README advertises a
     numeric core-skill count ("N core AI skills"), it must match the directory count
  5. '# - ' header-option lines inside ```jinja / ```jinja2 fences contain exactly one ':'
     (zero colons crashes the Starlake template parser; two make the option invisible)

Exit 0 = clean; exit 1 = violations printed one per line.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE = ROOT / ".agents" / "skills"
STARFLOW = ROOT / ".agents" / "starflow" / "skills"
README = ROOT / "README.md"

errors = []


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    return m.group(1) if m else None


def check_skill(skill_dir):
    md = skill_dir / "SKILL.md"
    rel = md.relative_to(ROOT)
    if not md.is_file():
        errors.append(f"{skill_dir.relative_to(ROOT)}: missing SKILL.md")
        return
    text = md.read_text(encoding="utf-8")
    fm = frontmatter(text)
    if fm is None:
        errors.append(f"{rel}: missing YAML frontmatter")
        return
    name = re.search(r"^(?:skill_)?name:\s*(\S+)\s*$", fm, re.M)
    desc = re.search(r"^description:\s*(.+)$", fm, re.M)
    if not name or name.group(1).strip("'\"") != skill_dir.name:
        errors.append(f"{rel}: frontmatter name must be '{skill_dir.name}'")
    if not desc or not desc.group(1).strip().strip("'\""):
        errors.append(f"{rel}: frontmatter description missing or empty")
    for target in re.findall(r"\]\((\.\./[^)]+/SKILL\.md)\)", text):
        if not (skill_dir / target).resolve().is_file():
            errors.append(f"{rel}: broken relative link {target}")
    fence_lang = None
    for lineno, line in enumerate(text.splitlines(), 1):
        f = re.match(r"^\s*(`{3,4})(\w*)\s*$", line)
        if f:
            fence_lang = None if fence_lang is not None else f.group(2).lower()
            continue
        if fence_lang in ("jinja", "jinja2") and line.lstrip().startswith("# - ") and line.count(":") != 1:
            errors.append(f"{rel}:{lineno}: '# - ' template-header line must contain exactly one ':'")


core_dirs = sorted(p for p in CORE.iterdir() if p.is_dir())
starflow_dirs = sorted(p for p in STARFLOW.iterdir() if p.is_dir())
for d in core_dirs + starflow_dirs:
    check_skill(d)

readme = README.read_text(encoding="utf-8")
for d in core_dirs:
    if not re.search(rf"\*\*{re.escape(d.name)}\*\*", readme):
        errors.append(f"README.md: Skills Catalog missing '{d.name}'")
m = re.search(r"(\d+) core AI skills", readme)
if m and int(m.group(1)) != len(core_dirs):
    errors.append(f"README.md: claims {m.group(1)} core AI skills but {len(core_dirs)} directories exist")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"OK: {len(core_dirs)} core + {len(starflow_dirs)} starflow skills lint clean")
