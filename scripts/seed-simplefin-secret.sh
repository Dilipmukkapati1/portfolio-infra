#!/usr/bin/env bash
set -euo pipefail

VAULT_NAME=""
SECRET_NAME="simplefin-access-url"
VALUE=""

usage() {
  echo "Usage: $0 --vault-name <name> --value <access-url> [--secret-name <name>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault-name) VAULT_NAME="$2"; shift 2 ;;
    --value) VALUE="$2"; shift 2 ;;
    --secret-name) SECRET_NAME="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$VAULT_NAME" || -z "$VALUE" ]] && usage

echo "Setting secret '$SECRET_NAME' in vault '$VAULT_NAME'..."
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "$SECRET_NAME" \
  --value "$VALUE" \
  --output none

echo "Done. Verify with: az keyvault secret show --vault-name $VAULT_NAME --name $SECRET_NAME --query id -o tsv"
