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

## Legacy

Bicep under `infra/azure/serverless/` was removed in favor of Terraform.
