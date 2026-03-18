#!/usr/bin/make -f

.DEFAULT_GOAL := help
.PHONY: help start stop test

help: ## Show help for each of the Makefile recipes.
	@grep -E '(^\S*:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

# —— Environment ——————————————————————————————————————————————————————————————————————————————————————————————————————

DOCKER_COMPOSE		           = docker compose --project-directory=. --env-file=../.env

CURRENT_UID                   := $(shell id -u)
CURRENT_GID                   := $(shell id -g)

CURRENT_USERNAME              := $(shell id -u -n)
CURRENT_HOMEDIR               := $${HOME}
CURRENT_DIR                   := $(shell pwd)

BATS                           = bats -t -j 1

# —— Docker ———————————————————————————————————————————————————————————————————————————————————————————————————————————

start:
	@$(DOCKER_COMPOSE) --profile=prime up -d

stop:
	@$(DOCKER_COMPOSE) --profile=prime down

# —— Bats —————————————————————————————————————————————————————————————————————————————————————————————————————————————

test:
	@$(BATS) tests.bats
