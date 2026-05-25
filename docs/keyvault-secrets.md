# Key Vault secrets

One shared Key Vault in `rg-portfolio`. Secrets are **prefixed by environment** (`dev-` / `prod-`) because dev and prod share the vault.

Terraform grants each Function App managed identity **Key Vault Secrets User** on the vault (RBAC is in code; no manual `az role assignment`).

## Secret names

| Secret name | Environment | Used by | Description |
| ----------- | ----------- | ------- | ----------- |
| `dev-simplefin-access-url` | dev | SimpleFIN sync | SimpleFIN Bridge Access URL |
| `prod-simplefin-access-url` | prod | SimpleFIN sync | Same for prod |
| `dev-simplefin-access-url-{householdId}` | dev | connectSimplefin | Per-household URL |
| `dev-snaptrade-client-id` | dev | SnapTrade | App ID |
| `dev-snaptrade-consumer-key` | dev | SnapTrade | Consumer key |
| `dev-snaptrade-webhook-secret` | dev | SnapTrade webhook | Signature verification |
| `prod-snaptrade-*` | prod | (mirror dev names with `prod-` prefix) | |
| `dev-azure-sql-connection-string` | dev | Future SQL features | Azure SQL `sqldb-dev` |
| `prod-azure-sql-connection-string` | prod | Future SQL features | Azure SQL `sqldb-prod` |

Cosmos uses **RBAC + app settings** (`COSMOS_ENDPOINT`, `COSMOS_DATABASE`); no Cosmos connection string required in Key Vault for the current API.

## Seed SimpleFIN (dev example)

```bash
VAULT=$(cd terraform && terraform output -raw key_vault_name)

./scripts/seed-simplefin-secret.sh \
  --vault-name "$VAULT" \
  --secret-name dev-simplefin-access-url \
  --value "https://user:pass@beta-bridge.simplefin.org/simplefin"
```

## Seed Azure SQL connection string

```bash
make seed-dev-sql
# or: ./scripts/seed-sql-secret.sh
```

Uses `terraform output` for FQDN, `sql_admin_login`, `sql_admin_password`, and `sql_database_dev`.

**Local API dev** uses `npm run sql:azure` in `portfolio-api` (writes `AZURE_SQL_*` to `local.settings.json`), not Key Vault.

## Local development

Use `portfolio-api` local settings and `.local-secrets.json` — see `portfolio-api/README.md`. Do not commit secret values.
