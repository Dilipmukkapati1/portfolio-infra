#!/usr/bin/env bash
# Seed dev Azure SQL connection string into Key Vault (post-apply).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$(cd "$SCRIPT_DIR/../terraform" && pwd)"
ENV_PREFIX="dev"
DATABASE=""
VAULT_NAME=""
SECRET_NAME=""

usage() {
  echo "Usage: $0 [--vault-name NAME] [--database NAME] [--env dev|prod] [--secret-name NAME]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault-name) VAULT_NAME="$2"; shift 2 ;;
    --database) DATABASE="$2"; shift 2 ;;
    --env) ENV_PREFIX="$2"; shift 2 ;;
    --secret-name) SECRET_NAME="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) is required. Run: az login" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install with: brew install jq" >&2
  exit 1
fi

cd "$TF_DIR"
if ! terraform output -raw sql_server_fqdn >/dev/null 2>&1; then
  echo "Terraform outputs not found. Apply dev stack first:" >&2
  echo "  cd portfolio-infra && make apply-dev" >&2
  exit 1
fi

FQDN="$(terraform output -raw sql_server_fqdn)"
PASSWORD="$(terraform output -raw sql_admin_password)"
LOGIN="$(terraform output -raw sql_admin_login 2>/dev/null || true)"
if [[ -z "$LOGIN" ]]; then
  LOGIN="ppmadmin"
fi

if [[ -z "$VAULT_NAME" ]]; then
  VAULT_NAME="$(terraform output -raw key_vault_name)"
fi

if [[ -z "$DATABASE" ]]; then
  if [[ "$ENV_PREFIX" == "dev" ]]; then
    DATABASE="$(terraform output -raw sql_database_dev 2>/dev/null || true)"
    if [[ -z "$DATABASE" ]]; then
      DATABASE="$(terraform output -json sql_database_names | jq -r '.[] | select(endswith("-dev"))' | head -1)"
    fi
    DATABASE="${DATABASE:-sqldb-dev}"
  else
    DATABASE="$(terraform output -json sql_database_names | jq -r '.[] | select(endswith("-prod"))' | head -1)"
  fi
fi

if [[ -z "$SECRET_NAME" ]]; then
  SECRET_NAME="${ENV_PREFIX}-azure-sql-connection-string"
fi

CONN="Server=tcp:${FQDN},1433;Database=${DATABASE};User ID=${LOGIN};Password=${PASSWORD};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

echo "Setting secret '${SECRET_NAME}' in vault '${VAULT_NAME}' (database ${DATABASE})..."
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "$SECRET_NAME" \
  --value "$CONN" \
  --output none

echo "Done. Verify with:"
echo "  az keyvault secret show --vault-name $VAULT_NAME --name $SECRET_NAME --query id -o tsv"
