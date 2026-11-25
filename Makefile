#!/usr/bin/make -f

.DEFAULT_GOAL := help
.PHONY: help build test test-images ini-directives

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
	@grep -hE '(^\S*:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

# —— Environment ——————————————————————————————————————————————————————————————————————————————————————————————————————

CURRENT_USERNAME            := $(shell id -u -n)
CURRENT_HOMEDIR             := $${HOME}
CURRENT_DIR                 := $(shell pwd)

# bake reads DOCKER_IMAGE_NAME from the environment, and make does not export a variable it
# assigned itself, so without this the value below would only ever reach the help text while bake
# fell back to its own default. Exported, this file is the single source of truth. The value has to
# stay in the registry-less form bake uses, so local tags match the ones CI publishes.
DOCKER_IMAGE_NAME           ?= smalswebtech/base-php
# The export has to come after the assignment: `export VAR` on its own defines VAR as empty, which
# would make the `?=` above a no-op.
export DOCKER_IMAGE_NAME

DOCKER_PLATFORM             ?= linux/amd64
DOCKER_BUILDER              ?= default
DOCKER_OUTPUT               ?= type=image

ENABLE_ATTESTATIONS			?= true

DOCKER_PROXY_ARGS := \
	--env HTTP_PROXY --env HTTPS_PROXY --env NO_PROXY \
	--env http_proxy --env https_proxy --env no_proxy

DOCKER_BUILD_PROXY_ARGS := \
	--build-arg HTTP_PROXY --build-arg HTTPS_PROXY --build-arg NO_PROXY \
	--build-arg http_proxy --build-arg https_proxy --build-arg no_proxy

# Cache-less rebuild on the `docker buildx build` path is off by default; pass
# NO_CACHE=true to force it. Leaving it cached is safe -- CA_BUNDLE_SHA already
# busts the ca-bundle layer when the CA changes, so a cached build stays correct
# behind a proxy while iterative builds stay fast.
NO_CACHE                    ?= false
DOCKER_BUILD_NO_CACHE       := $(if $(filter true,$(NO_CACHE)),--no-cache,)

ifneq ($(strip $(CUSTOM_CA_BUNDLE)),)
# The CA's checksum busts the ca-bundle stage cache when the CA changes (a secret
# mount does not take part in the cache key, so a stale bundle would be reused).
# Exported so `docker bake` reads it into the CA_BUNDLE_SHA variable, and passed
# as a build-arg on the plain `docker build` path too.
export CA_BUNDLE_SHA := $(shell sha256sum $(CUSTOM_CA_BUNDLE) | cut -d' ' -f1)
DOCKER_CA_ARGS := --volume $(CUSTOM_CA_BUNDLE):/etc/ssl/certs/ca-certificates.crt:ro
DOCKER_BUILD_CA_ARGS := --secret id=ca_bundle,src=$(CUSTOM_CA_BUNDLE) --build-arg CA_BUNDLE_SHA=$(CA_BUNDLE_SHA)
DOCKER_BAKE_CA_ARGS := --allow=fs.read=$(CUSTOM_CA_BUNDLE)
endif

# —— Docker Compose Stack —————————————————————————————————————————————————————————————————————————————————————————————

build:
	@$(MAKE) bake-all

test:
	@$(MAKE) -C test demo-test

TARGET ?= prd
JOBS   ?= 4

# The three suites side by side, each with JOBS tests at a time, on the images
# `make bake-all/$(TARGET)` built (see test/helpers/containers.bash image_tag).
# Each log lands in test/.logs/ and is printed when its suite fails.
test-images: ## test-images [TARGET=prd|dev] [JOBS=4] : run the cli, apache and nginx suites on the images built here
	@mkdir -p test/.logs; cd test; pids=""; \
	 for v in cli apache nginx; do \
	   s=tests.web.bats; [ "$$v" = cli ] && s=tests.cli.bats; \
	   BATS_VARIANT=$$v BATS_TARGET=$(TARGET) bats --jobs $(JOBS) --print-output-on-failure $$s \
	     > .logs/$$v-$(TARGET).log 2>&1 & pids="$$pids $$!"; \
	 done; \
	 failed=0; for p in $$pids; do wait $$p || failed=1; done; \
	 for v in cli apache nginx; do \
	   l=.logs/$$v-$(TARGET).log; \
	   printf '%-7s %3s ok, %s not ok\n' $$v "$$(grep -c '^ok ' $$l)" "$$(grep -c '^not ok' $$l)"; \
	   grep -q '^not ok' $$l && cat $$l; \
	 done; \
	 exit $$failed

# The fixture is the drift witness: a PHP release that adds or removes an ini
# directive moves this file, and the diff of the pull request names it. It is
# version-specific, so a backport regenerates it rather than cherry-picking it.
ini-directives: ## ini-directives : regenerate test/fixtures/ini-directives.list from the built cli image
	@docker run --rm --entrypoint cat $(DOCKER_IMAGE_NAME):$${DOCKER_IMAGE_TAG:-snapshot}-cli \
	   /usr/local/share/base-php/ini-directives.list > test/fixtures/ini-directives.list
	@echo "test/fixtures/ini-directives.list <- $(DOCKER_IMAGE_NAME):$${DOCKER_IMAGE_TAG:-snapshot}-cli ($$(wc -l < test/fixtures/ini-directives.list) directives)"

# —— Docker build —————————————————————————————————————————————————————————————————————————————————————————————————————

build-all: ## build-all [ options ]
	@$(MAKE) build-fpm/prd
	@$(MAKE) build-fpm/dev
	@$(MAKE) build-apache/prd
	@$(MAKE) build-apache/dev
	@$(MAKE) build-nginx/prd
	@$(MAKE) build-nginx/dev
	@$(MAKE) build-cli/prd
	@$(MAKE) build-cli/dev

build-all/%: ## build-all/(prd|dev) [ options ]
	@$(MAKE) build-fpm/${*}
	@$(MAKE) build-apache/${*}
	@$(MAKE) build-nginx/${*}
	@$(MAKE) build-cli/${*}

build-fpm/%: ## build-fpm/(prd|dev) [ options ]
	@$(MAKE) _docker-build/fpm-${*}

build-apache/%: ## build-apache/(prd|dev) [ options ]
	@$(MAKE) _docker-build/apache-${*}

build-nginx/%: ## build-nginx/(prd|dev) [ options ]
	@$(MAKE) _docker-build/nginx-${*}

build-cli/%: ## build-cli/(prd|dev) [ options ]
	@$(MAKE) _docker-build/cli-${*}

_docker-build/%: ## docker-build/(prd|dev)
	@echo "\n-- Running Docker buildx build --\n"
	@docker buildx build --progress=plain $(DOCKER_BUILD_NO_CACHE) \
		$(DOCKER_BUILD_PROXY_ARGS) \
		$(DOCKER_BUILD_CA_ARGS) \
		--target ${*} \
		--tag ${DOCKER_IMAGE_NAME}:$(patsubst %-prd,%,${*}) .

# —— Docker bake ——————————————————————————————————————————————————————————————————————————————————————————————————————

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
		$(DOCKER_BAKE_CA_ARGS) \
		--set *.platform=${DOCKER_PLATFORM} \
		--set *.output=${DOCKER_OUTPUT} \
		--builder ${DOCKER_BUILDER} \
		${*}

##
## Options: DOCKER_PLATFORM="linux/amd64,linux/arm64" DOCKER_BUILDER="cloud-remote" DOCKER_OUTPUT="type=registry" DOCKER_IMAGE_NAME="smalswebtech/base-php"
##

# —— Release & Tag ————————————————————————————————————————————————————————————————————————————————————————————————————

# The release targets are .github/release.mk, the file every image repository shares (see
# docs/release-tooling.md); this Makefile only says what is particular to base-php. The release
# flow: make release-prepare VERSION=x.y.z [RETAG=1], read CHANGELOG.md, then make release or
# make retag. CHANGELOG.md is the durable copy: retag and notes regenerate the GitHub release
# notes from the previous tag and discard anything hand-written there.
RELEASE_BRANCHES    = main 8.4
# A release is named after the PHP version it ships.
VERSION_OF          = PHP_VERSION

include .github/release.mk

# The release tooling every image repository shares, byte for byte: base-php holds the reference
# copy. tooling-check runs its tests and lists the sibling checkouts whose copy drifted (found next to
# this one and under ../../smals; TOOLING_SIBLINGS="dir ..." to choose). Local only.
TOOLING_FILES    = .github/release.mk .github/release-prepare.sh .github/changelog-deps.sh .github/lint-local.sh
TOOLING_SIBLINGS ?= $(patsubst %/.github/lint-local.sh,%,$(wildcard ../*/.github/lint-local.sh ../../smals/*/.github/lint-local.sh))

.PHONY: tooling-check
tooling-check: ## tooling-check [TOOLING_SIBLINGS="dir ..."] : test the shared release tooling, list the repositories whose copy drifted
	@cd test && bats release-prepare.bats release-mk.bats
	@drift=0; for d in $(TOOLING_SIBLINGS); do \
	   for f in $(TOOLING_FILES); do \
	     if [ ! -f "$$d/$$f" ]; then echo "missing  $$d/$$f"; drift=1; \
	     elif ! cmp -s "$$f" "$$d/$$f"; then echo "differs  $$d/$$f"; drift=1; fi; \
	   done; \
	 done; \
	 [ $$drift = 0 ] && echo "tooling: $(words $(TOOLING_SIBLINGS)) sibling checkouts in line" || { echo "tooling: copy $(TOOLING_FILES) from here"; exit 1; }

# —— CI cache —————————————————————————————————————————————————————————————————————————————————————————————————————————

# Only a push to main or to a version branch writes the layer cache (see the
# bake step of docker.yml). Entries written by other refs -- pull requests, tags,
# from before that rule -- can be read by nobody but the ref that wrote them, and
# still count against the repository's 10 GB quota until GitHub evicts them.
# This removes them.
.PHONY: ci-cache-prune

ci-cache-prune: ## ci-cache-prune [APPLY=1] : list (or delete) the Actions caches not written by main or a version branch
	@t=$$(mktemp); trap 'rm -f "$$t"' EXIT; \
	 gh api --paginate "repos/$(REPO)/actions/caches?per_page=100" \
	   --jq '.actions_caches[] | select(.ref != "refs/heads/main" and (.ref | test("^refs/heads/[0-9]+[.][0-9]+$$") | not)) | [.id, .ref, .size_in_bytes] | @tsv' > "$$t" || exit 1; \
	 awk -F'\t' '{ n++; s += $$3 } END { printf "%d caches not written by main or a version branch, %.2f GB\n", n, s / 1e9 }' "$$t"; \
	 if [ -z "$(APPLY)" ]; then \
	   cut -f2 "$$t" | sed -E 's#/[0-9]+/merge$$#/N/merge#; s#tags/.*#tags/*#' | sort | uniq -c; \
	   echo "dry run -- APPLY=1 deletes them"; \
	 else \
	   n=0; f=0; \
	   while IFS="$$(printf '\t')" read -r id ref size; do \
	     if gh api -X DELETE "repos/$(REPO)/actions/caches/$$id" >/dev/null 2>&1; then n=$$((n + 1)); else f=$$((f + 1)); fi; \
	   done < "$$t"; \
	   echo "deleted $$n, failed $$f"; \
	 fi

# —— GitHub settings ——————————————————————————————————————————————————————————————————————————————————————————————————

# Branch rulesets (.github/rulesets/) and repository settings (.github/repo-settings.json) live in
# the repository and are reviewed like code; GitHub only follows them once a maintainer applies
# them. `apply` needs admin rights on the repository: run it by hand after the change is merged,
# never from CI.
.PHONY: gh-settings-diff gh-settings-apply

gh-settings-diff: ## gh-settings-diff : compare the repository's rulesets and settings with .github/ (read-only)
	@bash .github/gh-settings.sh diff $(REPO)

gh-settings-apply: ## gh-settings-apply [YES=1] : apply .github/rulesets and .github/repo-settings.json to the repository (admin)
	@bash .github/gh-settings.sh diff $(REPO)
	@if [ -z "$(YES)" ]; then printf "Apply these settings to $(REPO)? [y/N] "; read a; [ "$$a" = y ] || [ "$$a" = Y ] || { echo Aborted >&2; exit 1; }; fi
	@bash .github/gh-settings.sh apply $(REPO)
