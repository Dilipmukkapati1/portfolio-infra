# GitHub Actions wiring after Terraform apply

Run `make outputs` from `portfolio-infra` after deploy. Values below match the initial `centralus` apply (suffix `x32hrp`); re-run `terraform output` if you recreate the stack.

## Branching and deployment

| Branch | Role | CI/CD deploy target |
|--------|------|-------------------|
| **`develop`** | Integration / pre-prod | Azure **dev** (`deploy-dev.yml`) |
| **`main`** | Production (default branch) | Azure **prod** (`deploy-prod.yml`) |

**Workflow:** open PRs into `develop` → merge to `develop` deploys dev → open PR `develop` → `main` → merge to `main` deploys prod.

Set **`main`** as the default branch in each GitHub repo (Settings → General, or `gh repo edit --default-branch main`). Create `develop` from `main` if it does not exist:

```bash
git checkout main && git pull
git checkout -b develop && git push -u origin develop
```

## Workflows

Each deployable repo has:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | push + PR to `main` and `develop` | Build, lint, test (no deploy) |
| `deploy-dev.yml` | push to **`develop`**, `workflow_dispatch`, `repository_dispatch` (`deploy-dev`) | Deploy to Azure **dev** |
| `deploy-prod.yml` | push to **`main`**, `workflow_dispatch`, `repository_dispatch` (`deploy-prod`) | Deploy to Azure **prod** |

On push to **`develop`**, repos run dev deploy. Library repos (`portfolio-contracts`, `portfolio-tax-engine`) also dispatch `deploy-dev` to downstream repos with the same git ref so API/web/batch deploy matching branch code.

On push to **`main`** (typically after merging an approved PR from `develop`), repos run prod deploy. Library repos dispatch `deploy-prod` downstream the same way.

## Shared secrets (all deployable repos)

Create GitHub **Environments** named `dev` and `prod` in each repo.

| Secret | Environments | Used by |
|--------|--------------|---------|
| `AZURE_CREDENTIALS` | dev, prod | portfolio-infra, portfolio-api, portfolio-batch |
| `AZURE_SUBSCRIPTION_ID` | dev, prod | portfolio-infra |
| `REPO_DISPATCH_PAT` | dev, prod | portfolio-contracts, portfolio-tax-engine |

`REPO_DISPATCH_PAT` is a classic PAT with `repo` scope (or fine-grained access to downstream repos). It triggers `deploy-dev` / `deploy-prod` in portfolio-api, portfolio-web, and portfolio-batch when shared libraries change.

`AZURE_CREDENTIALS` is a service principal JSON with Contributor on `rg-portfolio` (and the Terraform state resource group for infra).

Environment-scoped secrets (same name, different values per environment) are used for database URLs, SWA tokens, and function app names.

## portfolio-infra

| Name | Value |
|------|--------|
| `vars.TF_STATE_STORAGE_ACCOUNT` | `ppmterraformrnw6` |
| `secrets.AZURE_SUBSCRIPTION_ID` | subscription GUID |
| `secrets.AZURE_CREDENTIALS` | Service principal JSON |
| `vars.OWNER_EMAIL` | Owner tag / budget alerts |

- **`develop`** → `deploy-dev.yml` applies `module.env_stack["dev"]`
- **`main`** → `deploy-prod.yml` applies `module.env_stack["prod"]`

## portfolio-api

Deploy workflows use resource group **`rg-portfolio`** and environment-scoped `vars.FUNCTION_APP_NAME`.

| Environment | Variable | Value |
|-------------|----------|--------|
| dev | `FUNCTION_APP_NAME` | `ppm-dev-func-x32hrp` |
| prod | `FUNCTION_APP_NAME` | `ppm-prod-func-x32hrp` |

### Liquibase CI secrets (optional, per environment)

| Secret | dev example | prod example |
|--------|-------------|--------------|
| `AZURE_SQL_LIQUIBASE_JDBC_URL` | `databaseName=sqldb-dev` | `databaseName=sqldb-prod` |
| `AZURE_SQL_LIQUIBASE_USERNAME` | SQL admin login | same |
| `AZURE_SQL_LIQUIBASE_PASSWORD` | SQL admin password | same |

## portfolio-web

| Environment | Secret / variable | Value |
|-------------|-------------------|--------|
| dev | `AZURE_STATIC_WEB_APPS_API_TOKEN` | SWA deployment token (dev SWA) |
| dev | `vars.FUNCTION_APP_BASE_URL` | `https://ppm-dev-func-x32hrp.azurewebsites.net` |
| prod | `AZURE_STATIC_WEB_APPS_API_TOKEN` | SWA deployment token (prod SWA) |
| prod | `vars.FUNCTION_APP_BASE_URL` | `https://ppm-prod-func-x32hrp.azurewebsites.net` |

```bash
# Dev SWA token
az staticwebapp secrets list \
  --name ppm-dev-web-x32hrp \
  -g rg-portfolio \
  --query properties.apiKey -o tsv

# Prod SWA token
az staticwebapp secrets list \
  --name ppm-prod-web-x32hrp \
  -g rg-portfolio \
  --query properties.apiKey -o tsv
```

## portfolio-batch

Uploads job packages to environment-specific blob containers in the shared storage account.

| Environment | Container | Variable |
|-------------|-----------|----------|
| dev | `batch-packages-dev` | `vars.STORAGE_ACCOUNT_NAME` |
| prod | `batch-packages-prod` | `vars.STORAGE_ACCOUNT_NAME` |

Blob paths:

- `latest/portfolio-batch.tar.gz` — current package
- `releases/<git-sha>/portfolio-batch.tar.gz` — immutable release history

## portfolio-contracts / portfolio-tax-engine

No direct Azure resources. On push to **`develop`** or **`main`**, the matching deploy workflow verifies the build and dispatches to downstream repos (requires `REPO_DISPATCH_PAT` in the `dev` or `prod` environment).

## Manual deploy

Azure dev:

```bash
gh workflow run deploy-dev.yml --ref develop
```

Azure prod:

```bash
gh workflow run deploy-prod.yml --ref main
```

Downstream only (after a library change on develop):

```bash
gh workflow run deploy-dev.yml --repo Dilipmukkapati1/portfolio-api --ref develop
```
