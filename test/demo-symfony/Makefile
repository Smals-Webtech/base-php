#!/usr/bin/make -f

.DEFAULT_GOAL := help
.PHONY: help build configure start stop test scrape load load-ui test-load

help: ## Show help for each of the Makefile recipes.
	@grep -E '(^\S*:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

# —— Environment ——————————————————————————————————————————————————————————————————————————————————————————————————————

DOCKER_COMPOSE		           = docker compose --project-directory=. --env-file=../.env

CURRENT_UID                   := $(shell id -u)
CURRENT_GID                   := $(shell id -g)

# The uid the symfony service runs under: the caller's, the same the console
# commands (EXEC_DEMO) and composer use. With two identities -- the image's 1001
# for the web, the caller's for the console -- whichever wrote a file in /app/var
# first kept it: the runtime directories are sticky (1777), and the kernel's
# protected_regular refuses to open another user's file there with O_CREAT, as
# Monolog does. A `make configure` before the first web request left the log to
# the caller, and every page answered 500. gid 0, as the image expects.
export DEMO_UID               := $(CURRENT_UID)

CURRENT_USERNAME              := $(shell id -u -n)
CURRENT_HOMEDIR               := $${HOME}
CURRENT_DIR                   := $(shell pwd)

DEMO_DIR                       = ${CURRENT_DIR}/src/demo
DEMO_REPO                      = https://github.com/symfony/demo.git
DEMO_REF                       = v3.1.0

BUILDER_WORKING_DIR            = /app
BUILDER_DOCKER_IMAGE_NAME     ?= docker.io/smalswebtech/base-php:cli-dev

COMPOSER_INSTALL_CMDLINE       = "composer -vvv install --no-interaction --no-suggest --no-scripts -o"
COMPOSER_UPDATE_CMDLINE        = "composer -vvv update --no-interaction --no-suggest --no-scripts -o"
COMPOSER_DIAGNOSE_CMDLINE      = "composer -vvv diagnose --no-interaction --no-scripts"
COMPOSER_SELF_UPDATE_CMDLINE   = "composer -vvv self-update --no-interaction"

DEMO_SASS_BUILD_CMDLINE        = "php bin/console sass:build"
DEMO_IMPORTMAP_INSTALL_CMDLINE = "php bin/console importmap:install"

EXEC_DEMO		               = $(DOCKER_COMPOSE) exec --user $(CURRENT_UID) symfony

BATS                           = bats -t -j 1

# —— Corporate proxy / custom CA ——————————————————————————————————————————————————————————————————————————————————————
#
# Nothing here takes effect unless the calling environment asks for it, so a run
# with direct internet access (CI, a plain workstation) is unchanged.
#
# Proxy: HTTP(S)_PROXY / NO_PROXY are passed through to the one-shot builder
# containers (DOCKER_PROXY_ARGS) and, through compose.proxy.yaml, to the symfony
# service, whose `configure` step downloads dart-sass and the importmap packages.
#
# CA: CUSTOM_CA_BUNDLE (an absolute path) is ADDED to the image's own trust store,
# never substituted for it -- the semantics of the ca-bundle stage of the image
# build. The combined bundle is written to .cache/ and mounted over the system
# bundle of the builder containers (DOCKER_CA_ARGS) and, through compose.ca.yaml,
# of the symfony service.
#
# COMPOSE_FILE is exported so that every compose call -- start, stop, exec, the
# load profile and the bats helpers -- sees the same set of files.

DOCKER_PROXY_ARGS := \
	--env HTTP_PROXY --env HTTPS_PROXY --env NO_PROXY \
	--env http_proxy --env https_proxy --env no_proxy

COMPOSE_FILE                  := compose.yaml:compose.override.yaml

ifneq ($(strip $(HTTP_PROXY)$(HTTPS_PROXY)$(http_proxy)$(https_proxy)),)
COMPOSE_FILE                  := $(COMPOSE_FILE):compose.proxy.yaml
endif

ifneq ($(strip $(CUSTOM_CA_BUNDLE)),)
CA_RUNTIME_BUNDLE             := $(CURRENT_DIR)/.cache/ca-bundle.pem
CA_PREREQ                     := $(CA_RUNTIME_BUNDLE)
DOCKER_CA_ARGS                := --volume $(CA_RUNTIME_BUNDLE):/etc/ssl/certs/ca-certificates.crt:ro
COMPOSE_FILE                  := $(COMPOSE_FILE):compose.ca.yaml
export CA_RUNTIME_BUNDLE

# Rebuilt whenever the custom CA changes, since it is the prerequisite.
$(CA_RUNTIME_BUNDLE): $(CUSTOM_CA_BUNDLE)
	@mkdir -p $(@D)
	@docker run --rm --entrypoint cat $(BUILDER_DOCKER_IMAGE_NAME) /etc/ssl/certs/ca-certificates.crt > $@.tmp
	@cat $(CUSTOM_CA_BUNDLE) >> $@.tmp
	@mv $@.tmp $@
	@echo "CA bundle: $(CUSTOM_CA_BUNDLE) added to the image trust store -> $@"
endif

export COMPOSE_FILE

# —— Load generation ——————————————————————————————————————————————————————————————————————————————————————————————————

LOCUST_USERS                  ?= 10
LOCUST_SPAWN_RATE             ?= 2
LOCUST_RUN_TIME               ?= 30s
export LOCUST_UID             := $(CURRENT_UID):$(CURRENT_GID)

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

start: $(CA_PREREQ)
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

# The demo used to be cloned over SSH, which an HTTP(S) proxy cannot carry, and a
# clone keeps the URL it was made with. Re-pointing origin every time moves an
# existing clone to HTTPS too, so the fetch below goes through the proxy.
update:
	@$(MAKE) clone
	@git -C $(DEMO_DIR) remote set-url origin $(DEMO_REPO)
	@echo "Fetching $(DEMO_REF)..."
	cd $(DEMO_DIR) && git fetch origin $(DEMO_REF) --depth 1

# The build leaves the clone dirty -- composer update rewrites composer.lock, and
# Symfony generates config/reference.php, which some demo releases track and
# others do not -- and a plain checkout refused to move over either, so changing
# DEMO_REF failed halfway. --force discards those changes, and clean removes the
# untracked files the next build regenerates; ignored ones (vendor/) stay.
reset: 
	@$(MAKE) update
	@echo "Resetting demo repo to $(DEMO_REF)"
	cd $(DEMO_DIR) && \
	git checkout --force --detach FETCH_HEAD && \
	git clean -fd

clean:
	rm -rf $(DEMO_DIR) $(CURRENT_DIR)/.cache

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

composer-diagnose: $(CA_PREREQ)
	@echo "\n-- Running Composer diagnose --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--env COMPOSER_HOME=${CURRENT_HOMEDIR}/.composer \
		--env COMPOSER_ALLOW_SUPERUSER=1 \
		--env COMPOSER_PROCESS_TIMEOUT=900 \
		--env COMPOSER_MEMORY_LIMIT=-1 \
		$(DOCKER_PROXY_ARGS) \
		--user root \
		$(DOCKER_CA_ARGS) \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${COMPOSER_DIAGNOSE_CMDLINE}

composer-update: $(CA_PREREQ)
	@echo "\n-- Running Composer update --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env PHP_OPENTELEMETRY_ENABLED=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--env COMPOSER_ALLOW_SUPERUSER=1 \
		--env COMPOSER_PROCESS_TIMEOUT=900 \
		--env COMPOSER_MEMORY_LIMIT=-1 \
		$(DOCKER_PROXY_ARGS) \
		--user ${CURRENT_UID}:${CURRENT_GID} \
		$(DOCKER_CA_ARGS) \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--volume ${DEMO_DIR}:${BUILDER_WORKING_DIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--workdir ${BUILDER_WORKING_DIR} \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${COMPOSER_UPDATE_CMDLINE}

composer-install: $(CA_PREREQ)
	@echo "\n-- Running Composer install --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env PHP_OPENTELEMETRY_ENABLED=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--env COMPOSER_ALLOW_SUPERUSER=1 \
		--env COMPOSER_PROCESS_TIMEOUT=900 \
		--env COMPOSER_MEMORY_LIMIT=-1 \
		$(DOCKER_PROXY_ARGS) \
		--user ${CURRENT_UID}:${CURRENT_GID} \
		$(DOCKER_CA_ARGS) \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--volume ${DEMO_DIR}:${BUILDER_WORKING_DIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--workdir ${BUILDER_WORKING_DIR} \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${COMPOSER_INSTALL_CMDLINE}

composer-selfupdate: $(CA_PREREQ)
	@echo "\n-- Running Composer Self-Update --\n"
	@docker run \
		--env PHP_BYPASS_INI_DEFAULT_VALUES=true \
		--env HOME=${CURRENT_HOMEDIR} \
		--env USER=${CURRENT_USERNAME} \
		--env COMPOSER_HOME=${CURRENT_HOMEDIR}/.composer \
		--env COMPOSER_ALLOW_SUPERUSER=1 \
		--env COMPOSER_PROCESS_TIMEOUT=900 \
		--env COMPOSER_MEMORY_LIMIT=-1 \
		$(DOCKER_PROXY_ARGS) \
		--user ${CURRENT_UID}:0 \
		$(DOCKER_CA_ARGS) \
		--volume ${CURRENT_HOMEDIR}:${CURRENT_HOMEDIR}:rw \
		--tmpfs /app/tmp:size=100m,mode=1777 \
		--rm \
		${BUILDER_DOCKER_IMAGE_NAME} \
		bash -c ${COMPOSER_SELF_UPDATE_CMDLINE}

# —— Load —————————————————————————————————————————————————————————————————————————————————————————————————————————————
# These need the demo stack up: demo-infra (traefik, profile all) + symfony started.

scrape: ## Discover site URLs → config/locust/urls.json (via Traefik)
	@$(DOCKER_COMPOSE) --profile load run --rm scraper

load: ## Headless load run; vars: LOCUST_USERS / LOCUST_SPAWN_RATE / LOCUST_RUN_TIME
	@$(MAKE) scrape
	@$(DOCKER_COMPOSE) --profile load run --rm \
		-e LOCUST_HEADLESS=true \
		-e LOCUST_USERS=$(LOCUST_USERS) \
		-e LOCUST_SPAWN_RATE=$(LOCUST_SPAWN_RATE) \
		-e LOCUST_RUN_TIME=$(LOCUST_RUN_TIME) \
		-e LOCUST_EXIT_CODE_ON_ERROR=1 \
		locust --only-summary

load-ui: ## Interactive Locust web UI on http://localhost:8089
	@$(DOCKER_COMPOSE) --profile load up locust

# —— Bats —————————————————————————————————————————————————————————————————————————————————————————————————————————————

test:
	@$(BATS) tests.bats

test-load: ## Opt-in load test (bats): short headless run, asserts 0 failures
	@$(BATS) load.bats
