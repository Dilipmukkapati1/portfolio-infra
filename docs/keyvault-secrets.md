# Key Vault secrets

All production secrets live in Azure Key Vault. The Function App uses **system-assigned managed identity** with the **Key Vault Secrets User** role.

## Secret names

| Secret name | Used by | Description |
| ----------- | ------- | ----------- |
| `simplefin-access-url` | `simplefinSync` | SimpleFIN Bridge Access URL (Basic Auth embedded) |
| `simplefin-access-url-{householdId}` | `connectSimplefin` | Per-household Access URL (multi-connection) |
| `snaptrade-client-id` | SnapTrade client | SnapTrade Dashboard app ID |
| `snaptrade-consumer-key` | SnapTrade client | SnapTrade consumer key |
| `snaptrade-webhook-secret` | `snaptradeWebhook` | Webhook signature verification |
| `cosmos-connection-string` | API, Batch (optional) | Cosmos connection; prefer RBAC + endpoint in prod |
| `storage-connection-string` | Functions, queues | Storage account connection |

## Seed SimpleFIN Access URL

After first infra deploy:

```bash
./scripts/seed-simplefin-secret.sh \
  --vault-name <kv-name> \
  --value "https://user:pass@beta-bridge.simplefin.org/simplefin"
```

Or:

```bash
az keyvault secret set \
  --vault-name kv-portfolio-dev-xxxx \
  --name simplefin-access-url \
  --value "<your-access-url>"
```

**Important:** Use an **Access URL** (from claiming a Setup Token), not a one-time Setup Token.

## Local development

Copy secret **names** (not values) to `.env` — see `portfolio-api/.env.example`.
