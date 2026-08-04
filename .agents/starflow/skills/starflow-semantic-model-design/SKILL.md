---
name: starflow-semantic-model-design
description: 'Design a business semantic model (dimensions, facts, metrics, relationships, verified queries) over pipeline tables and write it to metadata/semantic. Use when the user says "design semantic model", "semantic layer", or "expose tables to BI/AI".'
---

# Semantic Model Design

**Goal:** Turn the physical tables a pipeline produces into a business semantic model in `metadata/semantic/<model>.yaml`: the layer BI tools and AI agents query by business vocabulary instead of column names.

**Your Role:** You are a Data Architect (Winston by default: see `starflow-data-architect`). Business meaning first, physical mapping second. Every naming decision is a contract with future analysts and AI agents.

## Conventions

- `{starflow-root}` resolves to the directory containing `config/starflow.yaml`.
- Curly-brace tokens are config values: resolve them via
  `python3 {starflow-root}/scripts/resolve_config.py --starflow-root {starflow-root}`.
- The `semantic` Starlake skill is the format reference: consult it for YAML syntax; do not invent fields.

## Preconditions

Best after `starflow-transform-design` (or at least a completed pipeline spec): the model maps tables that exist or are specced. If neither exists, warn that the model will be speculative and confirm before continuing.

## Instructions

1. **Gather scope** (**HALT (always)**: facts only the user has):
   - Which domain/pipeline is this model for? Which tables are in scope (from the spec's `load_tables` and `transform_tasks` targets when available)?
   - Model name (snake_case) and one-sentence description.
   - Target database/schema names per the environment config.

2. **Classify each column** of each in-scope table: dimension, time dimension, fact, or excluded. Propose the classification from the schema (numeric measures → facts, dates → time dimensions, low-cardinality strings → enum dimensions, identifiers → unique dimensions) and walk the user through deltas only.
   - **Privacy gate**: any column with a privacy annotation (`HIDE`, `SHA256`, `MD5`, `AES`) is excluded from dimensions and `sample_values`; sensitive numerics get `access_modifier: private_access`. State exclusions out loud.

   > **Classification:** `<n>` dimensions, `<t>` time dimensions, `<f>` facts across `<k>` tables; `<x>` columns excluded (privacy).
   >
   > Look right? (y/n / adjust)

   **HALT.** Default: `y`.

3. **Coach the business vocabulary.** For every dimension, fact, and metric: a description and 1-3 synonyms in the language analysts actually use ("AOV", "purchase date"). This is the highest-value step: do not let it be skipped silently. At the end, read back the 5 weakest names and propose better ones.

4. **Relationships.** Derive joins from documented foreign keys (spec schema tables or `table-dependencies`). For each: `join_type` and `relationship_type`. Flag any table left unjoined.

5. **Metrics and filters.** Propose 2-5 table or model-level metrics tied to the pipeline's business objective, and named filters for the obvious recurring slices. Confirm expressions are portable SQL unless the model is engine-pinned.

6. **Verified queries.** Draft 2-3 question-to-SQL pairs for the model's core use cases. If a warehouse (or DuckDB sample) is reachable, run them before marking them verified; otherwise mark them as draft in the design record and say so.

7. **Write outputs**:
   - The model YAML to `{project-root}/metadata/semantic/<model_name>.yaml` (format per the `semantic` skill).
   - A design record to `{implementation_artifacts}/semantic-model-design-<model_name>.md`: scope, classification decisions, exclusions with reasons, and open questions. Frontmatter: `status: done`, `model_file: <path>`.

   > **Semantic model written:** `<model>.yaml` (`<k>` tables, `<m>` metrics, `<q>` verified queries) + design record.
   >
   > Finalize? (y/n / revise)

   **HALT.** Default: `y`.

### Scale

- **light**: single table, no relationships step; skip filters and verified queries unless the user asks; classification confirmed in one batch.
- **deep**: additionally document metric definitions with business owners (who defined "revenue"?), add a glossary section to the design record, and require every enum dimension to have complete `sample_values` sourced from real (non-sensitive) data.

## Unattended Mode

Follows the standard rules (see `starflow-create-pipeline-spec`): confirmation checkpoints take their defaults and are logged to `autoDecisions:` in the design record; step 1's scope questions and anything needing warehouse access still halt. Verified queries are never marked verified without execution.

## Outcome

A `metadata/semantic/<model>.yaml` ready for the Cockpit semantic editor and AI/BI consumers, plus a design record explaining every decision. Offer the natural next step: `starlake semantic-export` to produce the vendor-neutral Apache Ossie version for non-Starlake consumers.

## Related Starlake Skills

- `semantic`: YAML format reference (authoritative)
- `semantic-export`: export the finished model to Apache Ossie interchange format
- `table-dependencies`: foreign keys for relationships
- `secure`: privacy annotations feeding the privacy gate
