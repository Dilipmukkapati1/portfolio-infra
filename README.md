# portfolio-infra

Azure Bicep for the personal portfolio platform (serverless stack).

## Structure

```
infra/azure/serverless/
  main.bicep          # Orchestration
  keyvault.bicep
  cosmos.bicep
  storage.bicep
  functionapp.bicep
  staticwebapp.bicep
  appinsights.bicep
  batch.bicep         # Phase 2+ pool autoscale 0
scripts/
  seed-simplefin-secret.sh
docs/
  keyvault-secrets.md
```

## Deploy (dev)

```bash
az group create -n rg-portfolio-dev -l eastus2
az deployment group create \
  -g rg-portfolio-dev \
  -f infra/azure/serverless/main.bicep \
  -p environmentName=dev ownerEmail=you@example.com
```

## Seed SimpleFIN Access URL

See [docs/keyvault-secrets.md](./docs/keyvault-secrets.md) and `scripts/seed-simplefin-secret.sh`.
