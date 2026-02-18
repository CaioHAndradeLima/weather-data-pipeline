SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: \
	help help-setup help-infra \
	setup.check-dev-deps setup.create-env setup.configure-dbt-profile setup.provision-snowflake \
	setup.from-scratch \
	infra.start-airbyte infra.start-postgres infra.configure-airbyte infra.start-airflow \
	infra.up infra.up-all infra.from-scratch infra.down \
	create-env provision-snowflake start-airbyte start-postgres configure-airbyte start-airflow \
	start-local-infra start-all-infra run-local-environment stop-local-infra stop-local-containers

help: ## Show available target groups
	@echo "Setup Commands"
	@$(MAKE) --no-print-directory help-setup
	@echo ""
	@echo "Infra Commands"
	@$(MAKE) --no-print-directory help-infra

help-setup:
	@awk 'BEGIN {FS = ":.*##"} /^setup\.[a-zA-Z0-9._-]+:.*##/ {printf "  \033[36m%-34s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

help-infra:
	@awk 'BEGIN {FS = ":.*##"} /^infra\.[a-zA-Z0-9._-]+:.*##/ {printf "  \033[36m%-34s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# -----------------------------
# Setup
# -----------------------------

setup.check-dev-deps: ## Verify/install local developer dependencies (Python3, Docker, Terraform, SnowSQL)
	bash ./scripts/setup/check_dev_dependencies.sh

setup.create-env: ## Create .env with Snowflake and local settings
	bash ./scripts/setup/create_env.sh

setup.configure-dbt-profile: ## Generate dbt profile from .env
	bash ./scripts/setup/configure_dbt_profile.sh

setup.provision-snowflake: ## Provision Snowflake resources (roles, database, schemas, warehouse)
	bash ./scripts/setup/create_snowflake_role.sh
	bash ./scripts/setup/provision_snowflake_remote.sh

setup.from-scratch: ## Full setup from zero for a new machine/account
	$(MAKE) setup.check-dev-deps
	$(MAKE) setup.create-env
	$(MAKE) setup.provision-snowflake
	$(MAKE) setup.configure-dbt-profile

# -----------------------------
# Infra Run
# -----------------------------

infra.start-airbyte: ## Start local Airbyte stack
	bash ./scripts/infra/start_airbyte.sh

infra.start-postgres: ## Start local Postgres CDC source
	bash ./scripts/infra/start_postgres.sh

infra.configure-airbyte: ## Configure Airbyte credentials, source, destination, and connections
	bash ./scripts/infra/configure_airbyte.sh

infra.start-airflow: ## Start local Airflow stack
	bash ./scripts/infra/start_airflow.sh

infra.up: ## Start full local infra (airbyte + postgres + airflow)
	bash ./scripts/infra/start_local_infra.sh

infra.up-all: ## Alias for infra.up
	bash ./scripts/infra/start_all_infra.sh

infra.from-scratch: ## Full infra run from zero for a new machine/account
	$(MAKE) infra.down
	$(MAKE) infra.up

infra.down: ## Stop local containers and remove local volumes
	bash ./scripts/infra/stop_local_infra.sh

infra.restart: ## Restart infra calling infra.down, infra.up-all
	$(MAKE) infra.down
	$(MAKE) infra.up-all

# -----------------------------
# Backward-compatible aliases
# -----------------------------

create-env: setup.create-env
provision-snowflake: setup.provision-snowflake
start-airbyte: infra.start-airbyte
start-postgres: infra.start-postgres
configure-airbyte: infra.configure-airbyte
start-airflow: infra.start-airflow
start-local-infra: infra.up
run-local-environment: infra.up
start-all-infra: infra.up-all
stop-local-infra: infra.down
stop-local-containers: infra.down
