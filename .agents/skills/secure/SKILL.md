---
name: secure
description: Apply Row Level Security (RLS) and Column Level Security (CLS) policies
---

# Secure Skill

Applies Row Level Security (RLS) and Column Level Security (CLS) policies defined in your table configurations. Security policies control which users or groups can see which rows and columns.

## Usage

```bash
starlake secure [options]
```

## Options

- `--domains <value>`: Comma-separated list of domains to apply security (default: all)
- `--tables <value>`: Comma-separated list of tables to apply security (default: all)
- `--accessToken <value>`: Access token for authentication (e.g. GCP)
- `--options k1=v1,k2=v2`: Substitution arguments
- `--scheduledDate <value>`: Scheduled date for the job, format: `yyyy-MM-dd'T'HH:mm:ss.SSSZ`
- `--reportFormat <value>`: Report output format: `console`, `json`, or `html`

## Configuration Context

Security policies are defined in table configuration files:

### Row Level Security (RLS)

Filter rows based on user/group membership:

```yaml
# In table.sl.yml
table:
  rls:
    - name: "USA only"
      predicate: "country = 'USA'"
      grants:
        - "group:usa_team"
    - name: "Recent data"
      predicate: "order_date > CURRENT_DATE - INTERVAL 90 DAY"
      grants:
        - "user:analyst@domain.com"
```

### Column Level Security (CLS) / Access Policies

Restrict access to sensitive columns:

```yaml
# In table.sl.yml
table:
  attributes:
    - name: "email"
      type: "string"
      accessPolicy: "PII"
    - name: "credit_card"
      type: "string"
      accessPolicy: "SENSITIVE"
```

### Access Control List (ACL)

Grant table-level permissions:

```yaml
# In table.sl.yml
table:
  acl:
    - role: "roles/bigquery.dataViewer"
      grants:
        - "user:user@domain.com"
        - "group:analytics_team@domain.com"
        - "serviceAccount:sa@project.iam.gserviceaccount.com"
```

## Privacy Transformations

Privacy transformations are applied during data loading to protect sensitive fields. Configure per attribute:

```yaml
attributes:
  - name: "ssn"
    type: "string"
    privacy: "HIDE" # Never stored — column is dropped

  - name: "email"
    type: "string"
    privacy: "SHA256" # One-way hash

  - name: "ip_address"
    type: "string"
    privacy: "MD5" # Anonymize

  - name: "phone"
    type: "string"
    privacy: "AES" # Reversible encryption
```

### Available Privacy Types

| Type | Description | Reversible |
|---|---|---|
| `HIDE` | Column is completely removed from output | N/A |
| `MD5` | MD5 hash of the value | No |
| `SHA1` | SHA-1 hash of the value | No |
| `SHA256` | SHA-256 hash of the value | No |
| `SHA512` | SHA-512 hash of the value | No |
| `AES` | AES encryption (requires encryption key) | Yes |

## BigQuery Access Policies Configuration

Configure Column-Level Security policies at the application level for BigQuery:

```yaml
# metadata/application.sl.yml
application:
  accessPolicies:
    apply: true
    location: EU
    taxonomy: RGPD
```

This enables BigQuery Data Catalog policy tags. Attributes with `accessPolicy` will be tagged accordingly, restricting column access to authorized users.

## Examples

### Apply Security to All Tables

```bash
starlake secure
```

### Apply Security to Specific Domain

```bash
starlake secure --domains starbake
```

### Apply Security to Specific Tables

```bash
starlake secure --domains starbake --tables customers,orders
```

## Related Skills

- [iam-policies](../iam-policies/SKILL.md) - Apply IAM policies
- [load](../load/SKILL.md) - Load data (security and privacy applied during load)
- [config](../config/SKILL.md) - Configuration reference (application-level settings)
