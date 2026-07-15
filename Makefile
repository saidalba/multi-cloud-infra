SHELL := /usr/bin/env bash
PROVIDERS := oci aws azure

LIVE_DIR := terraform/live/$(PROVIDER)
INVENTORY := ansible/inventory/$(PROVIDER).ini

.PHONY: up down plan validate fmt lint check-provider

check-provider:
	@if [ -z "$(PROVIDER)" ]; then \
		echo "error: PROVIDER is required, e.g. make up PROVIDER=oci"; \
		echo "valid providers: $(PROVIDERS)"; \
		exit 1; \
	fi
	@if ! echo "$(PROVIDERS)" | grep -qw "$(PROVIDER)"; then \
		echo "error: unknown PROVIDER '$(PROVIDER)'"; \
		echo "valid providers: $(PROVIDERS)"; \
		exit 1; \
	fi

## Provision the instance, generate its inventory, and run the base playbook.
up: check-provider
	terraform -chdir=$(LIVE_DIR) init
	terraform -chdir=$(LIVE_DIR) apply
	./scripts/generate-inventory.sh $(PROVIDER)
	ansible-playbook -i $(INVENTORY) ansible/playbook.yml

## Destroy the instance and its supporting resources.
down: check-provider
	terraform -chdir=$(LIVE_DIR) destroy

## Show the terraform plan for a provider.
plan: check-provider
	terraform -chdir=$(LIVE_DIR) init
	terraform -chdir=$(LIVE_DIR) plan

## Validate a single provider's terraform configuration.
validate: check-provider
	terraform -chdir=$(LIVE_DIR) init -backend=false
	terraform -chdir=$(LIVE_DIR) validate

## Format all terraform configuration in the repo.
fmt:
	terraform fmt -recursive terraform/

## Validate every provider plus the ansible playbook. No PROVIDER needed.
lint:
	@for p in $(PROVIDERS); do \
		echo "== validating $$p =="; \
		terraform -chdir=terraform/live/$$p init -backend=false >/dev/null; \
		terraform -chdir=terraform/live/$$p validate; \
	done
	terraform fmt -check -recursive terraform/
	ansible-lint ansible/playbook.yml
