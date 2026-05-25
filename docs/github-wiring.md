# GitHub Actions wiring after Terraform apply

Run `make outputs` from `portfolio-infra` after deploy. Values below match the initial `centralus` apply (suffix `x32hrp`); re-run `terraform output` if you recreate the stack.

## portfolio-infra

| Name | Value |
|------|--------|
| `vars.TF_STATE_STORAGE_ACCOUNT` | `ppmterraformrnw6` |
| `secrets.AZURE_SUBSCRIPTION_ID` | `eb4d9da3-b4e5-4197-b5e7-7e35ef8ed445` |
| `secrets.AZURE_CREDENTIALS` | Service principal JSON (Contributor on subscription or `rg-portfolio` + state RG) |
| `vars.OWNER_EMAIL` | Owner tag / budget alerts |

## portfolio-api

Deploy workflow uses resource group **`rg-portfolio`** and environment-scoped `vars.FUNCTION_APP_NAME`.

| Environment | Variable | Value |
|-------------|----------|--------|
| dev | `FUNCTION_APP_NAME` | `ppm-dev-func-x32hrp` |
| prod | `FUNCTION_APP_NAME` | `ppm-prod-func-x32hrp` |

Add a `prod` GitHub Environment with the prod function app name when you enable prod deploys.

## portfolio-web

| Environment | Secret | SWA name |
|-------------|--------|----------|
| dev | `AZURE_STATIC_WEB_APPS_API_TOKEN` | `ppm-dev-web-x32hrp` |
| prod | `AZURE_STATIC_WEB_APPS_API_TOKEN` | `ppm-prod-web-x32hrp` |

```bash
az staticwebapp secrets list \
  --name ppm-dev-web-x32hrp \
  -g rg-portfolio \
  --query properties.apiKey -o tsv
```

Set per-environment secrets in GitHub when using environment-scoped deploys (`environment: dev` / `environment: prod` in the workflow).

## portfolio-api — Liquibase CI secret

Build `AZURE_SQL_LIQUIBASE_JDBC_URL` for GitHub Actions deploy:

```
jdbc:sqlserver://<sql_server_fqdn>:1433;databaseName=sqldb-dev;encrypt=true;trustServerCertificate=false
```

Username/password: `terraform output -raw sql_admin_login` / `sql_admin_password` (after `make apply-dev`).
