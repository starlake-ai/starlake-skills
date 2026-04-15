---
date: {{system-date}}
author: {{user_name}}
---

# Data Project Context: {{project_name}}

## Project Overview
<!-- What this data project is about -->

## Technology Stack
- **Pipeline Framework:** Starlake
- **Development Engine:** DuckDB
- **Production Engine:**
- **Orchestration:** Airflow / Dagster
- **Storage:**
- **Version Control:** Git

## Data Domains
<!-- List of data domains with brief descriptions -->

## Architecture Decisions
<!-- Key architectural decisions and rationale -->

| Decision | Choice | Rationale |
|----------|--------|-----------|

## Conventions
- **File naming:** `.sl.yml` for all Starlake configs
- **Domain naming:** kebab-case (maps to database schemas)
- **Table naming:** snake_case
- **SQL style:** Standard SQL, no engine-specific syntax
- **Write strategies:** Document rationale for each choice

## Environment Setup
<!-- How to set up local development environment -->

```bash
# Install Starlake
# Configure connections
# Bootstrap project
starlake bootstrap
```
