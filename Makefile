#!/usr/bin/make -f

.DEFAULT_GOAL := help
.PHONY: help build test

help: # Show help for each of the Makefile recipes.
	@echo "Base PHP Build / Test"
	@echo "---------------------------"
	@echo "CURRENT_USERNAME: ${CURRENT_USERNAME}"
	@echo "CURRENT_HOMEDIR: ${CURRENT_HOMEDIR}"
	@echo "CURRENT_DIR: ${CURRENT_DIR}"
	@echo ""
	@echo "Image name: ${DOCKER_IMAGE_NAME}"
	@echo "Image platform: ${DOCKER_PLATFORM}"
	@echo "Image builder: ${DOCKER_BUILDER}"
	@echo "Image output: ${DOCKER_OUTPUT}"
	@echo ""
	@echo "KIBANA:        http://kibana.localhost"
	@echo "---------------------------"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo ""
	@grep -E '(^\S*:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

# —— Environment ——————————————————————————————————————————————————————————————————————————————————————————————————————

CURRENT_UID                 := $(shell id -u)
CURRENT_GID                 := $(shell id -g)

CURRENT_USERNAME            := $(shell id -u -n)
CURRENT_HOMEDIR             := $${HOME}
CURRENT_DIR                 := $(shell pwd)

DOCKER_IMAGE_NAME           ?= docker.io/smalswebtech/base-php

DOCKER_PLATFORM             ?= linux/amd64
DOCKER_BUILDER              ?= default
DOCKER_OUTPUT               ?= type=image

# —— Docker Compose Stack —————————————————————————————————————————————————————————————————————————————————————————————

build:
	@$(MAKE) bake-all

test:
	@$(MAKE) -C test demo-test

# —— Docker build —————————————————————————————————————————————————————————————————————————————————————————————————————

bake-all: ## bake-all [ options ]
	@$(MAKE) bake-fpm/prd
	@$(MAKE) bake-fpm/dev
	@$(MAKE) bake-apache/prd
	@$(MAKE) bake-apache/dev
	@$(MAKE) bake-nginx/prd
	@$(MAKE) bake-nginx/dev
	@$(MAKE) bake-cli/prd
	@$(MAKE) bake-cli/dev

bake-all/%: ## bake-all/(prd|dev) [ options ]
	@$(MAKE) bake-fpm/${*}
	@$(MAKE) bake-apache/${*}
	@$(MAKE) bake-nginx/${*}
	@$(MAKE) bake-cli/${*}

bake-fpm/%: ## bake-fpm/(prd|dev) [ options ]
	@$(MAKE) _docker-bake/fpm-${*}

bake-apache/%: ## bake-apache/(prd|dev) [ options ]
	@$(MAKE) _docker-bake/apache-${*}

bake-nginx/%: ## bake-nginx/(prd|dev) [ options ]
	@$(MAKE) _docker-bake/nginx-${*}

bake-cli/%: ## bake-cli/(prd|dev) [ options ]
	@$(MAKE) _docker-bake/cli-${*}

_docker-bake/%:
	@echo "\n-- Running Docker bake --\n"
	@docker bake --progress=plain \
		--set *.platform=${DOCKER_PLATFORM} \
		--set *.output=${DOCKER_OUTPUT} \
		--builder ${DOCKER_BUILDER} \
		${*}

##
## Options: DOCKER_PLATFORM="linux/amd64,linux/arm64" DOCKER_BUILDER="cloud-remote" DOCKER_OUTPUT="type=registry" DOCKER_IMAGE_NAME="smalswebtech/base-php"
##
