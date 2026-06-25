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

# —— Release & Tag ————————————————————————————————————————————————————————————————————————————————————————————————————

.PHONY: release-info sync release retag tag-restore notes build-version

# Canonical remote: 'upstream' when working from a fork, else 'origin' (the real repo).
RELEASE_REMOTE              ?= $(shell git remote | grep -qx upstream && echo upstream || echo origin)
# Fork remote we ALSO push branches to (no-op when it equals the canonical remote).
FORK_REMOTE                 ?= origin
# GitHub owner/repo slug derived from the canonical remote URL (for `gh --repo`).
REPO                        ?= $(shell git config --get remote.$(RELEASE_REMOTE).url | sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$$##')

# Commit/ref a tag should point at (default: current HEAD).
REF                         ?= HEAD
# Previous tag for release notes (default: auto-detected as the next-lower semver tag).
SINCE                       ?=
# Set YES=1 to skip confirmation prompts on destructive operations.
YES                         ?=

# Shell snippet: print the semver tag immediately below VERSION (works whether or not VERSION is already a tag).
PREV_TAG = (git tag --sort=-v:refname | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$$'; echo $(VERSION)) | sort -rV | uniq | awk -v v=$(VERSION) '$$0==v{p=1;next} p{print;exit}'

##
## Release & Tag (VERSION=x.y.z, REF=HEAD, SINCE=x.y.z, YES=1 to skip prompts; remote auto-detected):
##

release-info: ## release-info : show detected canonical remote, repo slug, branch and latest tags
	@echo "canonical remote : $(RELEASE_REMOTE)"
	@echo "fork remote      : $(FORK_REMOTE)"
	@echo "gh repo slug     : $(REPO)"
	@echo "current branch   : $$(git rev-parse --abbrev-ref HEAD)"
	@echo "latest tags      : $$(git tag --sort=-v:refname | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$$' | head -5 | tr '\n' ' ')"

sync: ## sync : fast-forward main + 8.4 from the canonical remote, then push to the fork
	@git fetch $(RELEASE_REMOTE) --no-tags --prune
	@cur=$$(git rev-parse --abbrev-ref HEAD); \
	 for b in main 8.4; do \
	   git show-ref --verify --quiet refs/heads/$$b || continue; \
	   git rev-parse --verify --quiet $(RELEASE_REMOTE)/$$b >/dev/null || continue; \
	   if ! git merge-base --is-ancestor $$b $(RELEASE_REMOTE)/$$b; then echo "skip $$b (not fast-forwardable)"; continue; fi; \
	   if [ "$$b" = "$$cur" ]; then git merge --ff-only $(RELEASE_REMOTE)/$$b >/dev/null; else git branch -f $$b $(RELEASE_REMOTE)/$$b; fi; \
	   echo "FF $$b -> $$(git rev-parse --short $$b)"; \
	 done
	@if [ "$(FORK_REMOTE)" != "$(RELEASE_REMOTE)" ]; then \
	   for b in main 8.4; do git show-ref --verify --quiet refs/heads/$$b && git push $(FORK_REMOTE) $$b || true; done; \
	 fi

release: ## release VERSION=x.y.z : prepare commit + signed tag + push + GitHub release (new version)
	@[ -n "$(VERSION)" ] || { echo "VERSION=x.y.z required" >&2; exit 1; }
	@b=$$(git rev-parse --abbrev-ref HEAD); case "$$b" in main|[0-9]*.[0-9]*) ;; *) echo "release only from main or x.y (on $$b)" >&2; exit 1;; esac
	@git rev-parse "$(VERSION)" >/dev/null 2>&1 && { echo "tag $(VERSION) already exists -> use 'make retag VERSION=$(VERSION)'" >&2; exit 1; } || true
	@if [ -z "$(YES)" ]; then printf "Release $(VERSION) from $$(git rev-parse --abbrev-ref HEAD) to $(RELEASE_REMOTE) ($(REPO))? [y/N] "; read a; [ "$$a" = y ] || [ "$$a" = Y ] || { echo Aborted >&2; exit 1; }; fi
	@git commit -S -a -m "chore: prepare release $(VERSION)" || echo "No changes to commit."
	@git tag -s -m "Version $(VERSION)" $(VERSION)
	@b=$$(git rev-parse --abbrev-ref HEAD); \
	 git push $(RELEASE_REMOTE) $$b; \
	 git push $(RELEASE_REMOTE) refs/tags/$(VERSION); \
	 [ "$(FORK_REMOTE)" != "$(RELEASE_REMOTE)" ] && git push $(FORK_REMOTE) $$b || true
	@prev=$$( $(PREV_TAG) ); \
	 latest=""; [ "$$(git rev-parse --abbrev-ref HEAD)" = "main" ] && latest="--latest"; \
	 gh release create $(VERSION) --repo $(REPO) --generate-notes $$latest $${prev:+--notes-start-tag $$prev} --verify-tag && echo "release $(VERSION) created"

retag: ## retag VERSION=x.y.z [REF=HEAD] : move an existing tag, fire the tag build, refresh the release
	@[ -n "$(VERSION)" ] || { echo "VERSION=x.y.z required" >&2; exit 1; }
	@b=$$(git rev-parse --abbrev-ref HEAD); case "$$b" in main|[0-9]*.[0-9]*) ;; *) echo "retag only from main or x.y (on $$b)" >&2; exit 1;; esac
	@sha=$$(git rev-parse --short "$(REF)"); \
	 echo "retag $(VERSION) -> $$sha on $(RELEASE_REMOTE) ($(REPO))"; \
	 if [ -z "$(YES)" ]; then printf "Proceed (delete+recreate tag, triggers a DockerHub rebuild)? [y/N] "; read a; [ "$$a" = y ] || [ "$$a" = Y ] || { echo Aborted >&2; exit 1; }; fi
	@if [ "$$(git rev-parse $(REF))" = "$$(git rev-parse HEAD)" ]; then \
	   b=$$(git rev-parse --abbrev-ref HEAD); \
	   git push $(RELEASE_REMOTE) $$b; \
	   [ "$(FORK_REMOTE)" != "$(RELEASE_REMOTE)" ] && git push $(FORK_REMOTE) $$b || true; \
	 fi
	@git push $(RELEASE_REMOTE) :refs/tags/$(VERSION) 2>/dev/null || true
	@git tag -d $(VERSION) 2>/dev/null || true
	@git tag -s -m "Version $(VERSION)" $(VERSION) $(REF)
	@git push $(RELEASE_REMOTE) refs/tags/$(VERSION)
	@echo "tag $(VERSION) pushed -> tag build triggered"
	@if gh release view $(VERSION) --repo $(REPO) >/dev/null 2>&1; then \
	   gh release edit $(VERSION) --repo $(REPO) --draft=false >/dev/null; \
	   prev=$$( $(PREV_TAG) ); \
	   if [ -n "$$prev" ]; then \
	     gh api repos/$(REPO)/releases/generate-notes -f tag_name=$(VERSION) -f previous_tag_name=$$prev --jq .body | gh release edit $(VERSION) --repo $(REPO) --notes-file - >/dev/null && echo "release $(VERSION) re-published, notes regenerated from $$prev"; \
	   else echo "release $(VERSION) re-published (no previous tag for notes)"; fi; \
	 else echo "no GitHub release $(VERSION) (skip refresh)"; fi

tag-restore: ## tag-restore VERSION=x.y.z : force-push the LOCAL tag to the canonical remote (fix a moved tag)
	@[ -n "$(VERSION)" ] || { echo "VERSION=x.y.z required" >&2; exit 1; }
	@git rev-parse "$(VERSION)" >/dev/null 2>&1 || { echo "no local tag $(VERSION)" >&2; exit 1; }
	@sha=$$(git rev-parse --short "$(VERSION)^{commit}"); \
	 echo "force-push local tag $(VERSION) ($$sha) -> $(RELEASE_REMOTE) ($(REPO))"; \
	 if [ -z "$(YES)" ]; then printf "Proceed? [y/N] "; read a; [ "$$a" = y ] || [ "$$a" = Y ] || { echo Aborted >&2; exit 1; }; fi
	@git push --force $(RELEASE_REMOTE) refs/tags/$(VERSION)
	@echo "restored (note: a single tag push may NOT rebuild if that commit was already built -> use 'make build-version VERSION=$(VERSION)')"

notes: ## notes VERSION=x.y.z [SINCE=x.y.z] : regenerate GitHub release notes
	@[ -n "$(VERSION)" ] || { echo "VERSION=x.y.z required" >&2; exit 1; }
	@prev="$(SINCE)"; [ -n "$$prev" ] || prev=$$( $(PREV_TAG) ); \
	 [ -n "$$prev" ] || { echo "no previous tag found; pass SINCE=x.y.z" >&2; exit 1; }; \
	 gh api repos/$(REPO)/releases/generate-notes -f tag_name=$(VERSION) -f previous_tag_name=$$prev --jq .body | gh release edit $(VERSION) --repo $(REPO) --notes-file - >/dev/null && echo "notes for $(VERSION) regenerated from $$prev"

build-version: ## build-version VERSION=x.y.z : trigger a docker build via workflow_dispatch (main path)
	@[ -n "$(VERSION)" ] || { echo "VERSION=x.y.z required" >&2; exit 1; }
	@gh workflow run docker.yml --repo $(REPO) -f version=$(VERSION) && echo "workflow_dispatch sent for $(VERSION) (runs the 'main' path, not the 'tag' path)"
