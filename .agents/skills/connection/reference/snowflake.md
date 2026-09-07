# Snowflake Connection Reference

Advanced Snowflake connection templates for `metadata/application.sl.yml`. The basic JDBC template is in [../SKILL.md](../SKILL.md). Starlake automatically adds `allowUnderscoresInHost: true` for all Snowflake connections.

#### Snowflake with OAuth Authentication

Starlake supports Snowflake OAuth in two modes:

**Web App OAuth**: set `authenticator` to `oauth` and provide `sl_access_token` in the format `account°user°token`:

```yaml
connections:
  snowflake:
    type: "jdbc"
    options:
      url: "jdbc:snowflake://{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com/"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      authenticator: "oauth"
      sl_access_token: "{{SNOWFLAKE_OAUTH_TOKEN}}"
      warehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      db: "{{SNOWFLAKE_DB}}"
      schema: "{{SNOWFLAKE_SCHEMA}}"
      keep_column_case: "off"
```

**Snowflake Native App**: additionally set `SL_APP_TYPE` to `snowflake_native_app`:

```yaml
connections:
  snowflake:
    type: "jdbc"
    options:
      url: "jdbc:snowflake://{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com/"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      authenticator: "oauth"
      sl_access_token: "{{SNOWFLAKE_OAUTH_TOKEN}}"
      SL_APP_TYPE: "snowflake_native_app"
      warehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      db: "{{SNOWFLAKE_DB}}"
      schema: "{{SNOWFLAKE_SCHEMA}}"
```

**Programmatic Access Token**: set `authenticator` to `programmatic_access_token` (Starlake handles this internally and does not pass it to the JDBC driver):

```yaml
connections:
  snowflake:
    type: "jdbc"
    options:
      url: "jdbc:snowflake://{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com/"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      authenticator: "programmatic_access_token"
      user: "{{SNOWFLAKE_USER}}"
      password: "{{SNOWFLAKE_PAT}}"
      warehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      db: "{{SNOWFLAKE_DB}}"
      schema: "{{SNOWFLAKE_SCHEMA}}"
```


#### Snowflake with Spark Connector

When using Spark to load data into Snowflake, a separate connection with `sparkFormat: snowflake` and `sf`-prefixed option keys is required:

```yaml
connections:
  spark-snowflake:
    type: "jdbc"
    sparkFormat: "snowflake"
    options:
      sfUrl: "{{SNOWFLAKE_ACCOUNT}}.snowflakecomputing.com"
      driver: "net.snowflake.client.jdbc.SnowflakeDriver"
      sfAccount: "{{SNOWFLAKE_ACCOUNT}}"
      sfUser: "{{SNOWFLAKE_USER}}"
      sfPassword: "{{SNOWFLAKE_PASSWORD}}"
      sfWarehouse: "{{SNOWFLAKE_WAREHOUSE}}"
      sfDatabase: "{{SNOWFLAKE_DB}}"
      sfSchema: "{{SNOWFLAKE_SCHEMA}}"
      keep_column_case: "off"
      autopushdown: "on"
      preActions: "ALTER SESSION SET QUERY_TAG = 'starlake';ALTER SESSION SET TIMESTAMP_TYPE_MAPPING = 'TIMESTAMP_LTZ';ALTER SESSION SET QUOTED_IDENTIFIERS_IGNORE_CASE = true"
```
