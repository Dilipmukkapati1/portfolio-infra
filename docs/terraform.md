# Terraform — portfolio infrastructure

Single resource group `rg-portfolio` in subscription **personal-portfolio-management**, region **centralus**.

Logical environments **dev** and **prod** share the RG and are isolated by naming (`portfolio-dev` / `portfolio-prod` Cosmos DBs, `sqldb-dev` / `sqldb-prod` Azure SQL, `ppm-dev-*` / `ppm-prod-*` compute).

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- Contributor on the subscription (or on `rg-portfolio` + `rg-portfolio-tfstate`)

```bash
az login
az account set --subscription "personal-portfolio-management"
az account show --query "{name:name, id:id}" -o table
```

## One-time bootstrap (remote state)

```bash
cp terraform/bootstrap/terraform.tfvars.example terraform/bootstrap/terraform.tfvars
# Set subscription_id in terraform/bootstrap/terraform.tfvars

make bootstrap
```

Copy backend config for the root module:

```bash
STORAGE=$(cd terraform/bootstrap && terraform output -raw storage_account_name)
cat > terraform/backend.hcl <<EOF
resource_group_name  = "rg-portfolio-tfstate"
storage_account_name = "${STORAGE}"
container_name       = "tfstate"
key                  = "portfolio.tfstate"
EOF
```

## Root module setup

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Set subscription_id, owner_email in terraform/terraform.tfvars

make init
make validate
```

## Dev-first workflow

```bash
make plan-dev
make apply-dev
```

Smoke-test dev Function App and Cosmos database `portfolio-dev`.

## Promote prod (manual gate)

```bash
make plan-prod
CONFIRM_PROD=1 make apply-prod
```

## Full stack

```bash
make plan
make apply
```

## Outputs

```bash
make outputs
```

Use `dev_function_app_name`, `prod_function_app_name`, SWA hostnames for GitHub Actions vars.

## Free tier notes

| Service | Config |
|---------|--------|
| Cosmos DB | One account, `free_tier_enabled`, 400 RU/s per shared-throughput database |
| Azure SQL | `GP_S_Gen5_2`, `use_free_limit`, `AutoPause` on exhaustion (2 of 10 free DBs) |
| Functions | Flex Consumption FC1, on-demand (no Always Ready) |
| Static Web Apps | Free SKU |

## Post-deploy secrets (Key Vault)

Seed env-prefixed secrets manually or via scripts:

- `dev-simplefin-access-url`, `prod-simplefin-access-url`
- `dev-azure-sql-connection-string`, `prod-azure-sql-connection-string` (for future SQL features)

See [keyvault-secrets.md](./keyvault-secrets.md).

## Application code

**Do not change** `portfolio-api/src/cosmos/**`. Cosmos connectivity is configured only via Function App settings from Terraform.
