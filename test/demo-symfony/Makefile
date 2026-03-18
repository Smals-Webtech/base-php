#!/usr/bin/make -f

.DEFAULT_GOAL := help
.PHONY: help build configure start stop test

help: ## Show help for each of the Makefile recipes.
	@grep -E '(^\S*:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

# —— Environment ——————————————————————————————————————————————————————————————————————————————————————————————————————

DOCKER_COMPOSE		           = docker compose --project-directory=. --env-file=../.env

CURRENT_UID                   := $(shell id -u)
CURRENT_GID                   := $(shell id -g)

CURRENT_USERNAME              := $(shell id -u -n)
CURRENT_HOMEDIR               := $${HOME}
CURRENT_DIR                   := $(shell pwd)

DEMO_DIR                       = ${CURRENT_DIR}/src/demo
DEMO_REPO                      = git@github.com:symfony/demo.git
DEMO_REF                       = v3.0.1

BUILDER_WORKING_DIR            = /app
BUILDER_DOCKER_IMAGE_NAME     ?= docker.io/smalswebtech/base-php:8.5-cli-dev

COMPOSER_INSTALL_CMDLINE       = "composer -vvv install --no-interaction --no-suggest --no-scripts -o"
COMPOSER_UPDATE_CMDLINE        = "composer -vvv update --no-interaction --no-suggest --no-scripts -o"
COMPOSER_DIAGNOSE_CMDLINE      = "composer -vvv diagnose --no-interaction --no-scripts"
COMPOSER_SELF_UPDATE_CMDLINE   = "composer -vvv self-update --no-interaction"

NPM_CONFIG_CMDLINE             = "npm config set cafile=/etc/ssl/certs/ca-certificates.crt && npm config set strict-ssl=false"
NPM_INSTALL_CMDLINE            = "npm install --prefix /app/src/elasticms/vendor/elasticms/admin-ui-bundle/assets"
NPM_RUN_BUILD_CMDLINE          = "npm --prefix /app/src/elasticms/vendor/elasticms/admin-ui-bundle/assets run build"

DEMO_SASS_BUILD_CMDLINE        = "php bin/console sass:build"
DEMO_IMPORTMAP_INSTALL_CMDLINE = "php bin/console importmap:install"

EXEC_DEMO		               = docker compose --env-file=../.env exec symfony

BATS                           = bats -t -j 1

# —— Demo —————————————————————————————————————————————————————————————————————————————————————————————————————————————

build:
	@$(MAKE) reset
	@$(MAKE) info
	@$(MAKE) composer-diagnose
	@$(MAKE) composer-update
	@$(MAKE) composer-install

configure:
	@$(EXEC_DEMO) sh -c ${DEMO_SASS_BUILD_CMDLINE}
	@$(EXEC_DEMO) sh -c ${DEMO_IMPORTMAP_INSTALL_CMDLINE}

# —— Docker ———————————————————————————————————————————————————————————————————————————————————————————————————————————

start:
	@$(DOCKER_COMPOSE) --profile=symfony up -d

stop:
	@$(DOCKER_COMPOSE) --profile=symfony down

# —— Git ——————————————————————————————————————————————————————————————————————————————————————————————————————————————

clone:
	@if [ -d "$(DEMO_DIR)/.git" ]; then \
		echo "Demo repo already exists"; \
	else \
		echo "Cloning demo repo..."; \
		git clone $(DEMO_REPO) $(DEMO_DIR); \
	fi

update: 
	@$(MAKE) clone
	@echo "Fetching $(DEMO_REF)..."
	cd $(DEMO_DIR) && git fetch origin $(DEMO_REF) --depth 1

reset: 
	@$(MAKE) update
	@echo "Resetting demo repo to $(DEMO_REF)"
	cd $(DEMO_DIR) && \
	git checkout FETCH_HEAD && \
	git reset --hard FETCH_HEAD

clean:
	rm -rf $(DEMO_DIR)

info:
	@if [ -d "$(DEMO_DIR)/.git" ]; then \
		cd $(DEMO_DIR) && \
		echo "Repository:" && git remote get-url origin && \
		echo "" && \
		echo "Commit:" && git rev-parse HEAD && \
		echo "" && \
		BRANCH=$$(git branch --show-current); \
		if [ -n "$$BRANCH" ]; then \
			echo "Branch: $$BRANCH"; \
		else \
			echo "Branch: (detached HEAD)"; \
		fi && \
		echo "" && \
		echo "Tag (if any):" && git describe --tags --exact-match 2>/dev/null || echo "none" && \
		echo "" && \
		echo "Nearest tag:" && git describe --tags --always && \
		echo "" && \
		echo "Status:" && git status -sb; \
	else \
		echo "Demo repo not cloned"; \
	fi

# —— Composer —————————————————————————————————————————————————————————————————————————————————————————————————————————

composer-diagnose:
	@echo "\n-- Running Composer diagnose --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--env COMPOSER_HOME=${CURRENT_HOMEDIR}/.composer \
		--env COMPOSER_ALLOW_SUPERUSER=1 \
		--env COMPOSER_PROCESS_TIMEOUT=900 \
		--env COMPOSER_MEMORY_LIMIT=-1 \
		--user root \
		--volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${COMPOSER_DIAGNOSE_CMDLINE}

composer-update:
	@echo "\n-- Running Composer update --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env PHP_OPENTELEMETRY_ENABLED=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--env COMPOSER_ALLOW_SUPERUSER=1 \
		--env COMPOSER_PROCESS_TIMEOUT=900 \
		--env COMPOSER_MEMORY_LIMIT=-1 \
		--user ${CURRENT_UID}:${CURRENT_GID} \
		--volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--volume ${DEMO_DIR}:${BUILDER_WORKING_DIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--workdir ${BUILDER_WORKING_DIR} \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${COMPOSER_UPDATE_CMDLINE}

composer-install:
	@echo "\n-- Running Composer install --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env PHP_OPENTELEMETRY_ENABLED=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--env COMPOSER_ALLOW_SUPERUSER=1 \
		--env COMPOSER_PROCESS_TIMEOUT=900 \
		--env COMPOSER_MEMORY_LIMIT=-1 \
		--user ${CURRENT_UID}:${CURRENT_GID} \
		--volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--volume ${DEMO_DIR}:${BUILDER_WORKING_DIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--workdir ${BUILDER_WORKING_DIR} \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${COMPOSER_INSTALL_CMDLINE}

composer-selfupdate:
	@echo "\n-- Running Composer Self-Update --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--env COMPOSER_HOME=${CURRENT_HOMEDIR}/.composer \
		--env COMPOSER_ALLOW_SUPERUSER=1 \
		--env COMPOSER_PROCESS_TIMEOUT=900 \
		--env COMPOSER_MEMORY_LIMIT=-1 \
		--user ${CURRENT_UID}:0 \
		--volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${COMPOSER_SELF_UPDATE_CMDLINE}

# —— NPM ——————————————————————————————————————————————————————————————————————————————————————————————————————————————

npm-configure:
	@echo "\n-- Running NPM config --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--user ${CURRENT_UID}:${CURRENT_GID} \
		--volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--volume ${DEMO_DIR}:${BUILDER_WORKING_DIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--workdir ${BUILDER_WORKING_DIR} \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${NPM_CONFIG_CMDLINE}

npm-install:
	@echo "\n-- Running NPM install --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--user ${CURRENT_UID}:${CURRENT_GID} \
		--volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--volume ${DEMO_DIR}:${BUILDER_WORKING_DIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--workdir ${BUILDER_WORKING_DIR} \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${NPM_INSTALL_CMDLINE}

npm-build:
	@echo "\n-- Running NPM run build --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--user ${CURRENT_UID}:${CURRENT_GID} \
		--volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--volume ${DEMO_DIR}:${BUILDER_WORKING_DIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--workdir ${BUILDER_WORKING_DIR} \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${NPM_RUN_BUILD_CMDLINE}

# —— Bats —————————————————————————————————————————————————————————————————————————————————————————————————————————————

test:
	@$(BATS) tests.bats
