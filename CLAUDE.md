# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repository is a **skills bundle**: not application code. It ships markdown-based "Agent Skills" covering the [Starlake](https://starlake.ai) data pipeline CLI, plus the optional **Starflow** guided methodology. The skills are consumed by AI coding assistants (Claude Code, GitHub Copilot, Gemini CLI) by symlinking the skill folders into each tool's `skills/` directory.

There is no build and no runtime code. The only automation is a structural docs linter (`python3 scripts/lint_skills.py`, run in CI) that checks frontmatter, relative links, README-catalog sync, and template-header grammar in fenced examples — it does not (and cannot) test skill *behavior*, which is LLM-executed prose. Changes are almost always edits to `SKILL.md` files (skill content) or to `scripts/install.sh` / `scripts/install.ps1` (the installer).

## Repository layout

```
.agents/
  skills/                 # Core Starlake CLI skills (one folder per skill, each with SKILL.md)
  starflow/
    skills/               # Starflow methodology skills (data-analyst, data-architect, ...)
    config/
      starflow.yaml       # Base config (installer-managed: treat as read-only)
      custom/             # Layered overrides (team .yaml committed, .user.yaml gitignored)
      README.md           # Documents layered-config semantics and merge rules
    templates/            # Markdown templates referenced by Starflow workflow skills
    scripts/
      resolve_config.py        # Merges base → team → user YAML config layers
      resolve_customization.py # Same, but for per-skill customize.yaml
    _config/
      starflow-help.csv   # Skill manifest (phase, after, before, required, outputs) for starflow-help
.claude-plugin/plugin.json  # Plugin manifest; `skills` array points to both skill roots
scripts/install.sh|.ps1     # Symlink installer for claude/copilot/gemini, global or local
```

Every skill lives in its own directory. Two skill shapes are in use:

1. **Flat skills** (most): a single `SKILL.md` with YAML frontmatter (`name`, `description`) and prose body.
2. **Step-file skills** (`starflow-create-pipeline-spec`, `starflow-code-review`, `starflow-retrospective`): a `SKILL.md` orchestrator that points to numbered files under `steps/step-NN-*.md`. Progress persists in `stepsCompleted: [...]` frontmatter on the output document so multi-session runs resume cleanly.

The installer iterates immediate subdirectories of `.agents/skills/` and `.agents/starflow/skills/`: sub-files like `steps/` come along for the ride via the directory symlink.

## Installer model (important when changing scripts/)

`scripts/install.sh` and `scripts/install.ps1` are kept feature-parallel. Both:

- Create symlinks from `~/.<platform>/skills/<skill>` (global, default) or `./.<platform>/skills/<skill>` (`--local`) to each subdirectory under `.agents/skills/` and `.agents/starflow/skills/`.
- Also symlink `~/.<platform>/starflow` → `.agents/starflow` so config and templates are reachable.
- Default platforms: `claude,copilot,gemini`. Restrict with `--platforms`.
- Use `is_starlake_link` (resolves the symlink target and checks it points back into this repo) to decide what is safe to remove on `--update` / `--uninstall`. Never delete non-symlinks or symlinks pointing elsewhere.

When adding a new platform or changing path conventions, update **both** scripts and the README install section in lock-step.

Distribution has two channels sharing the same layout:

- **Git clone** (contributors): symlinks point into the clone; `--channel stable|latest` / `--pin` switch the checked-out ref (only when passed explicitly).
- **GitHub Releases** (end users): `.github/workflows/release.yml` packs `.tar.gz`/`.zip` assets on every `vX.Y.Z` tag push, with a `VERSION` file stamped in (the `--version` fallback when `.git` is absent). `scripts/install-remote.sh` / `.ps1` download and unpack a release to `~/.starlake-skills`, then run the inner installer. The remote pair is also kept feature-parallel, and refuses to overwrite a git clone.

## Common commands

```bash
# Install / update / uninstall the skills locally for development
./scripts/install.sh --update              # re-link after pulling new skills
./scripts/install.sh --local               # install into the current project rather than $HOME
./scripts/install.sh --platforms claude    # restrict to one assistant

# After editing a SKILL.md, no rebuild is needed: symlinks pick up changes immediately.

python3 scripts/lint_skills.py            # structural lint (frontmatter, links, catalog sync) — CI runs this on every PR
```

## Editing skills

- Keep the YAML frontmatter (`name`, `description`): assistants use it for skill discovery.
- The `description` is what makes a skill auto-trigger; lead with the user-visible action and the CLI command name.
- Keep the README's "Skills Catalog" section in sync when adding, removing, or renaming a skill folder (CI enforces this: the linter fails if a skill folder is missing from the catalog or the advertised count is stale).
- Keep `.agents/starflow/_config/starflow-help.csv` in sync when adding/removing/renaming any starflow skill (columns: `module, skill, display-name, menu-code, description, action, args, phase, after, before, required, output-location, outputs`). `starflow-help` depends on it for adaptive recommendations.
- The `extract-rest-*`, `extract-bq-schema`, and `extract-schema` skills are part of the same family: when adding cross-cutting features (retries, pagination, auth), check whether siblings need the same edit.

## Step-file skills

When editing a step-file workflow:

- The `SKILL.md` is the **orchestrator**: activation rules, conventions, critical rules, pointer to `steps/step-01-*.md`. It should not contain step content itself.
- Each step file: frontmatter declaring runtime variables it sets, a "Rules" block, "Preconditions" (what `stepsCompleted` must contain), step instructions with explicit `**HALT**` checkpoints, "Save" (append step number to `stepsCompleted`, persist output file), and a `## Next` pointer to the next step.
- Never inline step content into `SKILL.md` for "convenience": the just-in-time loading is the point. Reading all steps up front bloats context unnecessarily.
- When adding a new step, update the step index table in `SKILL.md`.
- **Checkpoints and modes**: every `**HALT**` confirmation checkpoint carries a `Default:` line (consumed by unattended mode, which logs auto-taken defaults to `autoDecisions:` frontmatter and caps the final status at `ready-for-review`). Information-gathering questions and `**HALT (always)**` checkpoints halt in every mode. Steps whose depth varies by pipeline size declare it in a `### Scale` block (light/deep deltas over the standard baseline, driven by the `scale` frontmatter field set in step-01).
- Templates for scaffolding new personas and workflow skills live in `.agents/starflow/templates/builder/` and are consumed by `starflow-builder`; keep them in sync when step-file conventions change.

## Starflow vs. core skills

- **Core skills** under `.agents/skills/` are thin wrappers around Starlake CLI commands (`load`, `transform`, `extract`, ...). Edits should mirror real CLI flags and behavior.
- **Starflow skills** under `.agents/starflow/skills/` are workflow/persona skills (Lea, Winston, Amelia, Quinn, Max) that orchestrate the core skills across the four phases: Discovery → Architecture → Pipeline Design → Implementation. They reference core skills by name; if you rename a core skill, grep Starflow for the old name.
- Starflow defaults live in the **layered config** described in `.agents/starflow/config/README.md`. Skills should resolve config via `python3 .agents/starflow/scripts/resolve_config.py --starflow-root <path>` rather than reading `starflow.yaml` directly: the resolver merges base → team → user. The installer symlinks the whole `starflow/` directory into each assistant's home, so scripts and resolved configs both work post-install.

## Layered config: merge semantics

Pure structural rules (no field-name special-casing):

- **Scalars**: override wins.
- **Mappings**: deep merge (recurse).
- **Sequences of mappings** where every item carries the same identifier (`code` or `id`): merge by that key: matching keys deep-merge, new keys append. This is what lets a team override a single agent's `description` without re-listing all five.
- **All other sequences**: append.

There is no removal mechanism: overrides cannot delete base items. To suppress a default, override by key with a no-op value, or fork the base file.

## Persona conventions

The five Starflow personas (Lea, Winston, Amelia, Quinn, Max) are defined in two places:

1. **Voice and identity**: the `agents:` array in `.agents/starflow/config/starflow.yaml`, with `code`, `name`, `title`, `icon`, and a `description` styled after BMAD (philosophy + metaphor + voice, not a job posting).
2. **Activation behavior**: each persona's `SKILL.md` activation block: greet with the icon, render a numbered command menu, halt for input, persona stays active across nested skill calls.

When editing a persona, update both. The `description` field is consumed by `starflow-code-review` step-02 to anchor each subagent's voice: drift between the YAML and the SKILL.md will produce inconsistent reviewer behavior.
