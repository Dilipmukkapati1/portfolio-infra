# Post-deploy RBAC

After `main.bicep` deploy, grant the Function App managed identity access:

```bash
FUNC_PRINCIPAL_ID="<from deployment output functionAppPrincipalId>"
KV_NAME="<keyVaultName>"
COSMOS_NAME="<accountName>"
RG="rg-portfolio-dev"

az role assignment create \
  --assignee "$FUNC_PRINCIPAL_ID" \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/<sub>/resourceGroups/$RG/providers/Microsoft.KeyVault/vaults/$KV_NAME"

az cosmosdb sql role assignment create \
  --account-name "$COSMOS_NAME" \
  --resource-group "$RG" \
  --role-definition-id 00000000-0000-0000-0000-000000000002 \
  --principal-id "$FUNC_PRINCIPAL_ID" \
  --scope "/"
```
