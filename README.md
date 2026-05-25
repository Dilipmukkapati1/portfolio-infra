# portfolio-infra

Terraform for the personal portfolio platform on Azure.

## Subscription and region

- Subscription: **personal-portfolio-management**
- Region: **centralus**
- Resource group: **rg-portfolio** (dev + prod logical environments by naming)

## Structure

```
terraform/
  bootstrap/           # one-time remote state backend
  modules/             # cosmos, sql, storage, keyvault, monitoring, env_stack
  main.tf              # root module
docs/
  terraform.md         # local workflow (bootstrap, plan, apply)
  keyvault-secrets.md  # secret naming and seeding
Makefile
```

## Quick start

```bash
az account set --subscription "personal-portfolio-management"

cp terraform/bootstrap/terraform.tfvars.example terraform/bootstrap/terraform.tfvars
# Set subscription_id, then:
make bootstrap

# Configure backend.hcl from bootstrap output (see docs/terraform.md)

cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Set subscription_id and owner_email

make init
make plan-dev
make apply-dev
```

Prod promotion: `CONFIRM_PROD=1 make apply-prod` (see [docs/terraform.md](./docs/terraform.md)).

## Downstream repos

After apply, set GitHub vars from `make outputs`:

| Repo | Variable | Source output |
|------|----------|---------------|
| portfolio-api | `FUNCTION_APP_NAME` (dev env) | `dev_function_app_name` |
| portfolio-api | `FUNCTION_APP_NAME` (prod env) | `prod_function_app_name` |
| portfolio-web | SWA deploy token | Azure portal / `az staticwebapp secrets list` |

**No changes** to `portfolio-api/src/cosmos/**` — Cosmos is configured via Function App settings only.

## Local API dev (Cosmos)

Terraform creates account `ppmcosmos*` with databases `portfolio-dev` / `portfolio-prod` and all SQL API containers (partition key `/householdId`).

From `portfolio-api` after `make apply-dev`:

```bash
npm run cosmos:azure   # COSMOS_ENDPOINT, COSMOS_KEY, COSMOS_DATABASE=portfolio-dev → local.settings.json
```

The API verifies containers exist in Azure (no emulator or Docker required for local dev).

## Legacy

Bicep under `infra/azure/serverless/` was removed in favor of Terraform.

## Local API dev (Azure SQL)

Terraform provisions shared server `ppm-sql-*` with database **`sqldb-dev`** (auto-pause enabled on free tier).

In `terraform/terraform.tfvars`:

```hcl
sql_allow_current_client_ip = true
```

Re-apply when your public IP changes.

```bash
make apply-dev
make seed-dev-sql    # Key Vault: dev-azure-sql-connection-string

cd ../portfolio-api
npm run azure:local  # or: npm run sql:azure
npm run db:migrate
```

Local SQL credentials are written by `npm run sql:azure` from `terraform output` (including sensitive `sql_admin_password`). Key Vault seed is optional for deployed apps.

**Shared database:** `sqldb-dev` is used by all local developers on this stack — coordinate schema migrations.
