#!/usr/bin/make -f

.DEFAULT_GOAL := help
.PHONY: help build configure start stop

help: ## Show help for each of the Makefile recipes.
	@grep -E '(^\S*:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

# —— Environment ——————————————————————————————————————————————————————————————————————————————————————————————————————

DOCKER_COMPOSE		         = docker compose --project-directory=. --env-file=../.env

# —— Docker Compose Stack —————————————————————————————————————————————————————————————————————————————————————————————

start:
	@$(DOCKER_COMPOSE) --profile=all up -d

start/%: ## start/(mariadb|elasticsearch|grafana)
	@$(DOCKER_COMPOSE) --profile=${*} up -d --force-recreate

stop:
	@$(DOCKER_COMPOSE) --profile=all down

stop/%: ## stop/(mariadb|elasticsearch|grafana)
	@$(DOCKER_COMPOSE) --profile=${*} down

