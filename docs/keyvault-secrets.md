# Key Vault secrets

One shared Key Vault in `rg-portfolio`. Secrets are **prefixed by environment** (`dev-` / `prod-`) because dev and prod share the vault.

Terraform grants each Function App managed identity **Key Vault Secrets Officer** on the vault (read and set secrets; RBAC is in code; no manual `az role assignment`).

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
| `dev-azure-sql-connection-string` | dev | Function App `AZURE_SQL_CONNECTION_STRING` | Azure SQL `sqldb-dev` (run `make seed-dev-sql` after apply) |
| `prod-azure-sql-connection-string` | prod | Function App `AZURE_SQL_CONNECTION_STRING` | Azure SQL `sqldb-prod` |
| `dev-auth-password` | dev | Privacy unlock | Same password users enter for the dev web login |
| `prod-auth-password` | prod | Privacy unlock | Same password users enter for the prod web login |
| `dev-auth-secret` | dev | Web/API local fallback | Shared auth secret when dev uses the fallback |
| `prod-auth-secret` | prod | Web/API local fallback | Shared auth secret when prod uses the fallback |
| `dev-privacy-jwt-secret` | dev | Privacy unlock | Strong signing secret for `x-privacy-token` JWTs |
| `prod-privacy-jwt-secret` | prod | Privacy unlock | Strong signing secret for `x-privacy-token` JWTs |
| `dev-fmp-api-key` | dev | Market data | Financial Modeling Prep API key (`FMP_API_KEY`) |
| `prod-fmp-api-key` | prod | Market data | Same for prod |

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

## Seed privacy secrets for dev

Use values from your web auth configuration for `dev-auth-password` and
`dev-auth-secret`; generate a separate high-entropy `dev-privacy-jwt-secret`.

```bash
VAULT=$(cd terraform && terraform output -raw key_vault_name)

az keyvault secret set --vault-name "$VAULT" --name dev-auth-password --value "<dev login password>"
az keyvault secret set --vault-name "$VAULT" --name dev-auth-secret --value "<dev auth secret>"
az keyvault secret set --vault-name "$VAULT" --name dev-privacy-jwt-secret --value "$(openssl rand -base64 48)"
```

After updating secrets, apply the dev stack so the Function App settings include
the Key Vault references, then deploy `portfolio-api` from the shared privacy
branch.

## Local development

Use `portfolio-api` local settings and `.local-secrets.json` — see `portfolio-api/README.md`. Do not commit secret values.
