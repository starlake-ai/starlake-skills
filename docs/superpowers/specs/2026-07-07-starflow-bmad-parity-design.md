# Starflow BMAD-parity design

Date: 2026-07-07
Status: approved

Closes four gaps identified against BMAD v6.10: versioned distribution, scale-adaptive
workflow depth, unattended execution, and a builder for custom personas/workflows.

## A. Versioned installer

`scripts/install.sh` and `scripts/install.ps1` (feature-parallel) gain:

- `--channel stable|latest`: `stable` fetches tags and checks out the newest semver
  tag (`vX.Y.Z`); `latest` checks out `main` and pulls.
- `--pin <tag>`: checkout an exact tag.
- `--version`: print the installed version (`git describe --tags --always`) and exit.
- Git state is only touched when `--channel` or `--pin` is passed explicitly.
  Default behavior is unchanged. After a checkout, symlinks are re-created
  (equivalent of `--update`) since skill folders may have changed.
- README documents channels and the release process (pushing a `vX.Y.Z` tag publishes
  a stable release). Tagging remains a human act.

## B. Scale-adaptive depth

- New output frontmatter field: `scale: light | standard | deep` (default `standard`).
- `starflow-create-pipeline-spec` step-01 classifies scale via heuristics
  (sources, tables, transforms, environments) and confirms it at the existing
  step-01 checkpoint. Standard = exact current behavior.
- Each step file gets a `### Scale` block under Rules:
  - `light`: collapse optional depth, merge checkpoints (steps 5+6 confirm together).
  - `deep`: extra rigor prompts (failure modes, backfill strategy, cost, SLA math).
- `starflow-code-review` step-01: if the diff is small (< ~200 changed lines across
  < ~5 files), offer a light single-reviewer pass instead of three subagents.

## C. Unattended mode

- Config key `unattended: false` in base `starflow.yaml`; enabled per-run by the
  user asking, or via user config layer.
- Every `**HALT**` checkpoint documents a `Default:` answer. In unattended mode the
  workflow takes the default, appends `{step, question, decision}` to `autoDecisions:`
  in the output frontmatter, and continues.
- `**HALT (always)**` checkpoints stop even in unattended mode: initial business
  context, credentials/connection details, BLOCKER findings, anything destructive.
- Safety valve: when `autoDecisions` is non-empty, finalize sets
  `status: ready-for-review` (never `ready-for-dev`). A human reviews the decision
  log and flips the status; `starflow-dev-pipeline` only consumes `ready-for-dev`.

## D. Builder skill

- New flat skill `.agents/starflow/skills/starflow-builder/` with three guided flows:
  1. **New persona**: coach a BMAD-style description (philosophy + metaphor + voice),
     append to the team layer `config/custom/starflow.yaml` `agents:` list, scaffold a
     persona skill folder from `templates/builder/persona-skill-template.md`.
  2. **New workflow skill**: flat or step-file, scaffolded from
     `templates/builder/flat-skill-template.md` /
     `step-orchestrator-template.md` + `step-file-template.md`;
     register in `_config/starflow-help.csv`; update README catalog.
  3. **Customize existing**: guide through layered config and `customize.yaml`.
- Registered in `starflow-help.csv` (phase `anytime`, required `false`).

## Order and verification

A → B → C → D. Installer verified in a sandboxed `$HOME`; skills verified by CSV
consistency checks and cross-file greps (checkpoint defaults, README catalog).
