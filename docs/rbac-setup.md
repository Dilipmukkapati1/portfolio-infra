# RBAC

Role assignments for the Function App managed identity are **managed by Terraform** in `terraform/modules/env_stack/`:

- **Key Vault Secrets User** on the shared vault
- **Cosmos DB Built-in Data Contributor** scoped to each env Cosmos database (`portfolio-dev` / `portfolio-prod`)
- **SQL DB Contributor** scoped to each env database (`sqldb-dev` / `sqldb-prod`)

No manual post-deploy steps are required after `terraform apply`.

To verify:

```bash
FUNC_ID=$(terraform -chdir=terraform output -raw dev_function_app_principal_id)
az role assignment list --assignee "$FUNC_ID" -o table
```
