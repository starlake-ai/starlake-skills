---
name: migrate
description: 'Migrate a Starlake project to the latest version format with `starlake migrate`: upgrade YAML config files after a Starlake upgrade, renaming deprecated keys and handling breaking schema changes between releases'
---

# Migrate Skill

Migrates your Starlake project configuration files to the latest version format. This handles breaking changes in YAML schema across Starlake releases, updating deprecated fields and adding new required ones.

## Usage

```bash
starlake migrate
```

## Options

- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`

## When to Use

Run this command after upgrading Starlake to a new version, especially when:
- YAML schema format changes between versions
- Deprecated configuration keys need to be renamed
- New required fields are introduced

## Examples

### Migrate Project

```bash
starlake migrate
```

## Related Skills

- [validate](../validate/SKILL.md) - Validate project after migration
- [compare](../compare/SKILL.md) - Compare project versions