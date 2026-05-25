.PHONY: bootstrap init fmt validate plan plan-dev apply-dev plan-prod apply-prod apply outputs seed-dev-sql

TF_DIR := terraform
BACKEND_CONFIG ?= backend.hcl

# Shared + env_stack targets for dev-first workflow
SHARED_TARGETS := \
	-target=azurerm_resource_group.portfolio \
	-target=module.cosmos_shared \
	-target=module.sql_shared \
	-target=module.storage_shared \
	-target=module.keyvault_shared \
	-target=module.monitoring_shared

DEV_TARGETS := $(SHARED_TARGETS) -target='module.env_stack["dev"]'
PROD_TARGETS := -target='module.env_stack["prod"]'

bootstrap:
	cd $(TF_DIR)/bootstrap && terraform init && terraform apply

init:
	cd $(TF_DIR) && terraform init -backend-config=$(BACKEND_CONFIG)

fmt:
	cd $(TF_DIR) && terraform fmt -recursive

validate: init
	cd $(TF_DIR) && terraform validate

plan: init
	cd $(TF_DIR) && terraform plan

plan-dev: init
	cd $(TF_DIR) && terraform plan $(DEV_TARGETS)

apply-dev: init
	cd $(TF_DIR) && terraform apply -auto-approve $(DEV_TARGETS)

plan-prod: init
	cd $(TF_DIR) && terraform plan $(SHARED_TARGETS) $(PROD_TARGETS)

apply-prod: init
	@if [ "$$CONFIRM_PROD" != "1" ]; then \
		echo "Set CONFIRM_PROD=1 to apply prod stack"; \
		exit 1; \
	fi
	cd $(TF_DIR) && terraform apply -auto-approve $(SHARED_TARGETS) $(PROD_TARGETS)

apply: init
	cd $(TF_DIR) && terraform apply -auto-approve

outputs:
	cd $(TF_DIR) && terraform output

seed-dev-sql:
	@bash scripts/seed-sql-secret.sh
