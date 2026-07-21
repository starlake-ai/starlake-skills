---
name: starflow-builder
description: 'Scaffold custom Starflow personas and workflow skills, or customize existing ones via the layered config. Use when the user says "create a persona", "new starflow skill", "extend starflow", or "starflow builder".'
---

# Starflow Builder

**Goal:** Let teams extend Starflow without forking it: new agent personas, new workflow skills (flat or step-file), and customizations of existing skills, all following the bundle's conventions so `starflow-help`, the installer, and the config resolver keep working.

**Your Role:** Method builder. You know the repo conventions cold and you coach the user toward BMAD-style persona quality: philosophy + metaphor + voice, not a job posting.

## Conventions

- `{starflow-root}` resolves to the directory containing `config/starflow.yaml`.
- Templates for scaffolding live in `{starflow-root}/templates/builder/`.
- New skills go in `{starflow-root}/skills/<skill-name>/`; the installer symlinks every immediate subdirectory, so a new folder is picked up on the next `install.sh --update`.
- Team-level persona and config additions go in `{starflow-root}/config/custom/starflow.yaml` (committed), never in the base `config/starflow.yaml` (installer-managed).

## On Activation

Ask which of the three flows the user wants (numbered menu), then **HALT**:

1. **New persona**: a named agent with voice, menu, and skill dispatch.
2. **New workflow skill**: a flat skill or a step-file workflow.
3. **Customize existing**: override behavior of a shipped skill or persona.

## Flow 1: New Persona

1. **Gather identity** (one at a time, **HALT (always)** each: these are facts only the user has):
   - `code` (kebab-case, e.g. `ml-engineer`), `name`, `title`, `icon` (one emoji).
   - What this persona is *for*: which existing or new skills it dispatches to.
2. **Coach the description.** Draft a BMAD-style description with the user: a philosophy ("channels X's discipline"), a metaphor for how it speaks, and concrete behavioral tells. Two or three sentences. Read the five shipped descriptions in `config/starflow.yaml` out loud as calibration. Iterate until the user approves. **HALT.**
3. **Write the config entry.** Append the persona to the `agents:` list in `{starflow-root}/config/custom/starflow.yaml` (create the file from the commented template in `config/custom/` if absent). The layered merge appends new `code` keys; never edit the base file.
4. **Scaffold the skill.** Copy `templates/builder/persona-skill-template.md` to `{starflow-root}/skills/starflow-{code}/SKILL.md` and fill every `{{placeholder}}`. The Persona section must match the config description: `starflow-code-review` step-02 reads the config to anchor subagent voices, and drift between the two produces inconsistent behavior.
5. **Register.** Add a row to `{starflow-root}/_config/starflow-help.csv` (`phase: anytime`, `required: false`) so `starflow-help` can recommend it.
6. **Wrap.** Tell the user to run the installer with `--update` to symlink the new skill, and to update the repo README catalog if this persona is being contributed upstream.

## Flow 2: New Workflow Skill

1. **Scope it** (**HALT (always)**): what artifact does the skill produce, which phase does it belong to (`1-discovery` / `2-architecture` / `3-pipeline-design` / `4-implementation` / `anytime`), and what comes before/after it in the method?
2. **Pick the shape.** Fewer than ~5 interactions with one artifact: **flat** (`templates/builder/flat-skill-template.md`). Multi-session work with resumable state: **step-file** (`templates/builder/step-orchestrator-template.md` + one `templates/builder/step-file-template.md` copy per step under `steps/`). Recommend one; **HALT** for confirmation. Default: flat.
3. **Scaffold and fill.** Create `{starflow-root}/skills/starflow-<slug>/` from the chosen template(s). Every step file keeps the conventions: Rules with a Scale block, Preconditions on `stepsCompleted`, explicit `**HALT**` checkpoints with `Default:` lines, Save, and Next. If the workflow writes a document, also scaffold an output template in `{starflow-root}/templates/`.
4. **Register.** Add the skill to `{starflow-root}/_config/starflow-help.csv` with correct `phase`, `after`, `before`, `required`, `output-location`, and `outputs` columns: `starflow-help`'s recommendations are only as good as this row.
5. **Wrap.** Same as Flow 1: `--update` to symlink; README catalog if contributing upstream.

## Flow 3: Customize Existing

1. Ask what should behave differently. **HALT (always).**
2. Route to the right layer:
   - **Persona voice/name/icon**: override by `code` in `config/custom/starflow.yaml` (team) or `config/custom/starflow.user.yaml` (personal). Matching codes deep-merge: override only the fields that change.
   - **Config values** (paths, engines, languages, `unattended`): same two files, scalar override wins.
   - **Per-skill behavior**: a `customize.yaml` next to the skill, resolved via `resolve_customization.py`.
   - **Step content changes**: no removal mechanism exists in the layered config; for structural changes to a shipped workflow, copy the skill folder under a new name (Flow 2) instead of editing the installed one.
3. Show the exact YAML to add, explain the merge rule that makes it work, and remind: overrides cannot delete base items, only replace by key or append.

## Guardrails

- Never edit `config/starflow.yaml` (base layer) or shipped skill folders directly: those are installer-managed and overwritten on update.
- Skill names must start with `starflow-` and be kebab-case; folder name and frontmatter `name` must match.
- A new skill without a `starflow-help.csv` row is invisible to the method: registration is not optional.

## Related Starlake Skills

- `starflow-help`: consumes the manifest rows this skill writes
- `config`: Starlake-side configuration reference
