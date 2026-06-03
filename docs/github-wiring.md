# GitHub Actions wiring after Terraform apply

Run `make outputs` from `portfolio-infra` after deploy. Values below match the initial `centralus` apply (suffix `x32hrp`); re-run `terraform output` if you recreate the stack.

## Workflows

Each repo has:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | push + PR to `main` | Build, lint, test (no deploy) |
| `deploy-dev.yml` | push to `main`, `workflow_dispatch`, `repository_dispatch` | Deploy to Azure **dev** |

On push to `main`, **all repos** run their dev deploy workflow. Library repos (`portfolio-contracts`, `portfolio-tax-engine`) also trigger downstream deploys so the API, web, and batch packages pick up the latest shared code.

## Shared secrets (all deployable repos)

Create a GitHub **Environment** named `dev` in each repo and set:

| Secret | Used by |
|--------|---------|
| `AZURE_CREDENTIALS` | portfolio-infra, portfolio-api, portfolio-batch |
| `AZURE_SUBSCRIPTION_ID` | portfolio-infra |
| `REPO_DISPATCH_PAT` | portfolio-contracts, portfolio-tax-engine |

`REPO_DISPATCH_PAT` is a classic PAT with `repo` scope (or fine-grained access to the downstream repos). It triggers `deploy-dev` in portfolio-api, portfolio-web, and portfolio-batch when shared libraries change.

`AZURE_CREDENTIALS` is a service principal JSON with Contributor on `rg-portfolio` (and the Terraform state resource group for infra).

## portfolio-infra

| Name | Value |
|------|--------|
| `vars.TF_STATE_STORAGE_ACCOUNT` | `ppmterraformrnw6` |
| `secrets.AZURE_SUBSCRIPTION_ID` | `eb4d9da3-b4e5-4197-b5e7-7e35ef8ed445` |
| `secrets.AZURE_CREDENTIALS` | Service principal JSON |
| `vars.OWNER_EMAIL` | Owner tag / budget alerts |

## portfolio-api

Deploy workflow uses resource group **`rg-portfolio`** and environment-scoped `vars.FUNCTION_APP_NAME`.

| Environment | Variable | Value |
|-------------|----------|--------|
| dev | `FUNCTION_APP_NAME` | `ppm-dev-func-x32hrp` |
| prod | `FUNCTION_APP_NAME` | `ppm-prod-func-x32hrp` |

Add a `prod` GitHub Environment with the prod function app name when you enable prod deploys.

### Liquibase CI secrets (optional)

| Secret | Description |
|--------|-------------|
| `AZURE_SQL_LIQUIBASE_JDBC_URL` | JDBC URL for `sqldb-dev` |
| `AZURE_SQL_LIQUIBASE_USERNAME` | SQL admin login |
| `AZURE_SQL_LIQUIBASE_PASSWORD` | SQL admin password |

Build `AZURE_SQL_LIQUIBASE_JDBC_URL`:

```
jdbc:sqlserver://<sql_server_fqdn>:1433;databaseName=sqldb-dev;encrypt=true;trustServerCertificate=false
```

Username/password: `terraform output -raw sql_admin_login` / `sql_admin_password` (after `make apply-dev`).

## portfolio-web

| Environment | Secret / variable | Value |
|-------------|-------------------|--------|
| dev | `AZURE_STATIC_WEB_APPS_API_TOKEN` | SWA deployment token |
| dev | `vars.DEV_FUNCTION_APP_URL` | `https://ppm-dev-func-x32hrp.azurewebsites.net` |

```bash
az staticwebapp secrets list \
  --name ppm-dev-web-x32hrp \
  -g rg-portfolio \
  --query properties.apiKey -o tsv
```

## portfolio-batch

Uploads job packages to blob container **`batch-packages-dev`** in the shared storage account.

| Environment | Variable | Source |
|-------------|----------|--------|
| dev | `STORAGE_ACCOUNT_NAME` | `terraform output -raw storage_account_name` |

Blob paths:

- `latest/portfolio-batch.tar.gz` — current dev package
- `releases/<git-sha>/portfolio-batch.tar.gz` — immutable release history

## portfolio-contracts / portfolio-tax-engine

No direct Azure resources. On push to `main`, `deploy-dev.yml` verifies the build and dispatches `deploy-dev` to downstream repos (requires `REPO_DISPATCH_PAT` in the `dev` environment).

## Manual deploy

Any repo:

```bash
gh workflow run deploy-dev.yml --ref main
```

Downstream only (after a library change):

```bash
gh workflow run deploy-dev.yml --repo Dilipmukkapati1/portfolio-api --ref main
```
