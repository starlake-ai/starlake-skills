---
name: acl-dependencies
description: Visualize access control with `starlake acl-dependencies` — graph which users and groups can access which tables, from the ACL and RLS (row-level security) definitions in your YAML, output as SVG, PNG, or JSON
---

# ACL Dependencies Skill

Generates a visual graph showing the relationships between users/groups and the tables they have access to, based on ACL (Access Control List) definitions in your YAML configurations.

## Usage

```bash
starlake acl-dependencies [options]
```

## Options

- `--output <value>`: Output file path (default: console output)
- `--grantees <value>`: Comma-separated list of users/groups to include (default: all)
- `--reload`: Reload YAML files from disk before computing
- `--json`: Generate JSON output
- `--tables <value>`: Comma-separated list of tables to include (default: all)
- `--all`: Include all ACLs in the output
- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`

## Configuration Context

ACL dependencies are derived from `acl` and `rls` definitions in table/task YAML files:

```yaml
# In table.sl.yml or task.sl.yml
table:
  acl:
    - role: "roles/bigquery.dataViewer"
      grants:
        - "user:analyst@domain.com"
        - "group:analytics_team@domain.com"
  rls:
    - name: "USA only"
      predicate: "country = 'USA'"
      grants:
        - "group:usa_team@domain.com"
```

## Examples

### Generate Full ACL Graph as JSON

```bash
starlake acl-dependencies --json --output acl.json --all
```

### Filter by Specific Users

```bash
starlake acl-dependencies --grantees "user:analyst@domain.com,group:analytics_team" --json --output acl.json
```

### Filter by Specific Tables

```bash
starlake acl-dependencies --tables starbake.orders,starbake.customers --json --output acl.json
```

### Render an Image

Starflow outputs DOT and JSON only (the UI draws the diagrams from the JSON). To get an image, render the DOT output with GraphViz:

```bash
starlake acl-dependencies --output acl-dependencies.dot --all && dot -Tsvg acl-dependencies.dot -o acl-dependencies.svg
```

## Related Skills

- [secure](../secure/SKILL.md) - Apply RLS/CLS security policies
- [iam-policies](../iam-policies/SKILL.md) - Apply IAM policies
- [lineage](../lineage/SKILL.md) - Task dependency lineage
- [table-dependencies](../table-dependencies/SKILL.md) - Table relationship graph