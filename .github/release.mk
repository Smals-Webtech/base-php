# Release targets shared by the Smals-Webtech image repositories. The same file is copied in each
# of them (base-php holds the reference copy, its `make tooling-check` compares them), and each
# Makefile includes it after setting what differs:
#
#   RELEASE_BRANCHES       the branches a release is made from (default: main)
#   RELEASE_BRANCH         the one branch VERSION must be released from, when the version decides
#                          it (limesurvey: $(RELEASE_MAJOR).x); empty: any of RELEASE_BRANCHES
#   VERSION_OF             the docker-bake.hcl variable VERSION must equal (PHP_VERSION, ...), and
#                          the Dockerfile's <VERSION_OF>_ARG when it has a value; empty: VERSION is
#                          the image's own version
#   CHANGELOG_DEP_NAMES    "X_VERSION_ARG=Name ...", read by .github/changelog-deps.sh
#   CHANGELOG_DEPS_TITLES  keep: release-prepare.sh keeps Renovate's chore(deps) titles
#
#   include .github/release.mk
#
# base-php's docs/release-tooling.md describes the whole set.

RELEASE_BRANCHES      ?= main
RELEASE_BRANCH        ?=
VERSION_OF            ?=
CHANGELOG_DEP_NAMES   ?=
CHANGELOG_DEPS_TITLES ?=
export CHANGELOG_DEP_NAMES CHANGELOG_DEPS_TITLES

# The canonical remote: upstream when working from a fork, origin otherwise. The fork, when there
# is one, gets the release branches too.
RELEASE_REMOTE ?= $(shell git remote | grep -qx upstream && echo upstream || echo origin)
FORK_REMOTE    ?= origin
REPO           ?= $(shell git config --get remote.$(RELEASE_REMOTE).url | sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$$##')

# The commit a tag points at, the tag release notes start from, and YES=1 to skip the prompts.
REF   ?= HEAD
SINCE ?=
YES   ?=

TAG_RE        := ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$$
RELEASE_MAJOR  = $(firstword $(subst ., ,$(VERSION)))

# Shell snippets. TAGS lists the release tags; LINE_TAGS those of VERSION's major line, or every
# tag when that line has none yet; PREV_TAG prints the tag just below VERSION in its line, so the
# notes of an older line's release (8.4.x after 8.5.x, 6.x after 7.x) start from that line;
# HIGHEST prints the highest of the tags and VERSION; IS_LATEST says whether VERSION is it. Left
# to GitHub, creating or re-publishing a release marks it Latest whatever its version: the 8.4.27
# retag of 2026-11-16 took Latest from 8.5.12.
TAGS      = git tag --list | grep -E '$(TAG_RE)'
LINE_TAGS = { t=$$($(TAGS)); l=$$(printf '%s\n' "$$t" | grep -E '^$(RELEASE_MAJOR)\.' || true); printf '%s\n' "$${l:-$$t}"; }
PREV_TAG  = ($(LINE_TAGS); echo $(VERSION)) | sort -V | uniq | awk -v v=$(VERSION) '$$0==v{print p; exit} {p=$$0}'
HIGHEST   = ($(TAGS); echo $(VERSION)) | sort -V | tail -n1
IS_LATEST = [ "$$( $(HIGHEST) )" = "$(VERSION)" ] && echo true || echo false

# Recipe lines. NEED_VERSION stops without a well-formed VERSION; NEED_BRANCH unless the current
# branch may release it.
NEED_VERSION = [ -n "$(VERSION)" ] || { echo "VERSION=x.y.z required" >&2; exit 1; }; \
	echo "$(VERSION)" | grep -Eq '$(TAG_RE)' || { echo "VERSION $(VERSION) is not x.y.z[-pre][+build]" >&2; exit 1; }
NEED_BRANCH = b=$$(git rev-parse --abbrev-ref HEAD); \
	if [ -n "$(RELEASE_BRANCH)" ]; then \
	  [ "$$b" = "$(RELEASE_BRANCH)" ] || { echo "$(VERSION) is released from $(RELEASE_BRANCH) (on $$b)" >&2; exit 1; }; \
	else \
	  case " $(RELEASE_BRANCHES) " in *" $$b "*) ;; *) echo "release only from $(RELEASE_BRANCHES) (on $$b)" >&2; exit 1;; esac; \
	fi

# VERSION against the version the image builds at $(1): the working tree, or a commit.
NEED_VERSION_OF = if [ -n "$(VERSION_OF)" ]; then \
	show() { if [ "$(1)" = worktree ]; then cat "$$1"; else git show "$(1):$$1"; fi; }; \
	bake=$$(show docker-bake.hcl | sed -nE '/^variable "$(VERSION_OF)"/,/^}/s/.*default *= *"([^"]+)".*/\1/p'); \
	arg=$$(show Dockerfile | sed -nE 's/^ARG $(VERSION_OF)_ARG="?([^" ]*)"?.*/\1/p' | head -n1); \
	[ "$$bake" = "$(VERSION)" ] || { echo "VERSION $(VERSION) is not what the image builds: docker-bake.hcl $(VERSION_OF) is '$$bake'" >&2; exit 1; }; \
	[ -z "$$arg" ] || [ "$$arg" = "$(VERSION)" ] || { echo "VERSION $(VERSION) is not what the image builds: the Dockerfile's $(VERSION_OF)_ARG is '$$arg'" >&2; exit 1; }; \
	fi

CONFIRM = if [ -z "$(YES)" ]; then printf "Proceed? [y/N] "; read a; [ "$$a" = y ] || [ "$$a" = Y ] || { echo Aborted >&2; exit 1; }; fi

.PHONY: release-info sync lint changelog release-prepare release retag release-refresh tag-restore notes build-version

##
## Release (VERSION=x.y.z, REF=HEAD, SINCE=x.y.z, YES=1 to skip the prompts):
##

release-info: ## release-info [VERSION=x.y.z] : show the remote, repository and tags; with VERSION, the release plan
	@echo "canonical remote : $(RELEASE_REMOTE)"
	@echo "fork remote      : $$([ "$(FORK_REMOTE)" != "$(RELEASE_REMOTE)" ] && git remote | grep -x "$(FORK_REMOTE)" || echo none)"
	@echo "gh repo slug     : $(REPO)"
	@echo "current branch   : $$(git rev-parse --abbrev-ref HEAD)"
	@echo "release branches : $(RELEASE_BRANCHES)"
	@echo "version is       : $(if $(VERSION_OF),docker-bake.hcl $(VERSION_OF),the image's own version)"
	@echo "latest tags      : $$($(TAGS) | sort -rV | head -n5 | tr '\n' ' ')"
	@if [ -n "$(VERSION)" ]; then \
	   echo "release branch   : $(or $(RELEASE_BRANCH),one of $(RELEASE_BRANCHES))"; \
	   echo "previous tag     : $$( $(PREV_TAG) )"; \
	   [ "$$( $(HIGHEST) )" = "$(VERSION)" ] && echo "mark latest      : yes" || echo "mark latest      : no ($$( $(HIGHEST) ) is higher)"; \
	 fi

sync: ## sync : fast-forward the release branches from the canonical remote, then push them to the fork
	@git fetch $(RELEASE_REMOTE) --no-tags --prune
	@cur=$$(git rev-parse --abbrev-ref HEAD); \
	 for b in $(RELEASE_BRANCHES); do \
	   git show-ref --verify --quiet refs/heads/$$b || continue; \
	   git rev-parse --verify --quiet $(RELEASE_REMOTE)/$$b >/dev/null || continue; \
	   if ! git merge-base --is-ancestor $$b $(RELEASE_REMOTE)/$$b; then echo "skip $$b (not fast-forwardable)"; continue; fi; \
	   wt=$$(git worktree list --porcelain | awk -v ref="refs/heads/$$b" '/^worktree /{w=substr($$0, 10)} $$0 == "branch " ref {print w}'); \
	   if [ "$$b" = "$$cur" ]; then git merge --ff-only --quiet $(RELEASE_REMOTE)/$$b; \
	   elif [ -n "$$wt" ]; then git -C "$$wt" merge --ff-only --quiet $(RELEASE_REMOTE)/$$b || { echo "skip $$b (its worktree $$wt did not fast-forward)"; continue; }; \
	   else git branch -f $$b $(RELEASE_REMOTE)/$$b; fi; \
	   echo "FF $$b -> $$(git rev-parse --short $$b)"; \
	 done
	@if [ "$(FORK_REMOTE)" != "$(RELEASE_REMOTE)" ] && git remote | grep -qx "$(FORK_REMOTE)"; then \
	   for b in $(RELEASE_BRANCHES); do git show-ref --verify --quiet refs/heads/$$b && git push --quiet $(FORK_REMOTE) $$b || true; done; \
	 fi

lint: ## lint : lint the whole tree locally, with the CI's super-linter version and settings
	@bash .github/lint-local.sh

changelog: ## changelog [SINCE=x.y.z] [APPLY=1] : list (or write under [Unreleased]) the pinned dependencies changed since the last tag
	@bash .github/changelog-deps.sh $(SINCE) $(if $(APPLY),--apply)

# The CHANGELOG section is written by the tooling, not by a pull request: release-prepare fills it
# from the dependency pins and the merged pull requests, then lints the whole tree; the section is
# read (prose optional), and release or retag commits it with the tag.
release-prepare: ## release-prepare VERSION=x.y.z [RETAG=1] : write the CHANGELOG section of a release (no commit)
	@$(NEED_VERSION)
	@$(NEED_BRANCH)
	@bash .github/release-prepare.sh $(VERSION) $(if $(RETAG),--retag)

release: ## release VERSION=x.y.z : commit the prepared CHANGELOG, signed tag, push, GitHub release (new version)
	@$(NEED_VERSION)
	@$(NEED_BRANCH)
	@$(call NEED_VERSION_OF,worktree)
	@grep -qF '## [$(VERSION)]' CHANGELOG.md || { echo "no '## [$(VERSION)]' section in CHANGELOG.md -> 'make release-prepare VERSION=$(VERSION)' first" >&2; exit 1; }
	@git rev-parse -q --verify "refs/tags/$(VERSION)" >/dev/null && { echo "tag $(VERSION) already exists locally -> 'make retag VERSION=$(VERSION)'" >&2; exit 1; } || true
	@[ -z "$$(git ls-remote --tags $(RELEASE_REMOTE) refs/tags/$(VERSION))" ] || { echo "tag $(VERSION) already exists on $(RELEASE_REMOTE) -> 'make retag VERSION=$(VERSION)'" >&2; exit 1; }
	@b=$$(git rev-parse --abbrev-ref HEAD); git fetch --quiet $(RELEASE_REMOTE) $$b; \
	 [ "$$(git rev-parse $$b)" = "$$(git rev-parse $(RELEASE_REMOTE)/$$b)" ] || { echo "local $$b differs from $(RELEASE_REMOTE)/$$b -> 'make sync', or push, first" >&2; exit 1; }
	@# `git commit -a` stages tracked files only, so a new file that was never added would be
	@# released without ever being committed. --exclude-standard honours .git/info/exclude, so a
	@# deliberately untracked file does not trip this.
	@u=$$(git ls-files --others --exclude-standard); [ -z "$$u" ] || { \
	   echo "untracked files present -- 'git commit -a' would SKIP them:" >&2; echo "$$u" | sed 's/^/  /' >&2; \
	   echo "git add them (or exclude them) before releasing" >&2; exit 1; }
	@echo "release $(VERSION) from $$(git rev-parse --abbrev-ref HEAD) to $(RELEASE_REMOTE) ($(REPO)); previous tag $$( $(PREV_TAG) ); latest $$( $(IS_LATEST) )"
	@$(CONFIRM)
	@# Only a genuinely clean tree may skip the commit: a signing failure must stop the release
	@# rather than let it tag a tree with no release commit in it.
	@if [ -n "$$(git status --porcelain --untracked-files=no)" ]; then \
	   git commit -S -a -m "chore: prepare release $(VERSION)"; \
	 else echo "Nothing to commit -- tagging the current HEAD."; fi
	@git tag -s -m "Version $(VERSION)" $(VERSION)
	@b=$$(git rev-parse --abbrev-ref HEAD); \
	 git push $(RELEASE_REMOTE) $$b && git push $(RELEASE_REMOTE) refs/tags/$(VERSION); \
	 if [ "$(FORK_REMOTE)" != "$(RELEASE_REMOTE)" ] && git remote | grep -qx "$(FORK_REMOTE)"; then git push --quiet $(FORK_REMOTE) $$b || true; fi
	@prev=$$( $(PREV_TAG) ); \
	 gh release create $(VERSION) --repo $(REPO) --generate-notes --latest=$$( $(IS_LATEST) ) $${prev:+--notes-start-tag $$prev} --verify-tag && echo "release $(VERSION) created"

retag: ## retag VERSION=x.y.z [REF=HEAD] : move an existing tag in one push, fire the tag build, refresh the release
	@$(NEED_VERSION)
	@$(NEED_BRANCH)
	@# The re-publication's CHANGELOG lines (make release-prepare RETAG=1) go in the commit the tag
	@# moves to. Only when the tag moves to HEAD: an older REF cannot take a new commit.
	@if ! git diff --quiet -- CHANGELOG.md; then \
	   [ "$$(git rev-parse $(REF))" = "$$(git rev-parse HEAD)" ] || { echo "CHANGELOG.md has changes but REF is not HEAD" >&2; exit 1; }; \
	   git commit -S -m "chore: re-publish $(VERSION)" -- CHANGELOG.md; \
	 fi
	@$(call NEED_VERSION_OF,$(REF))
	@echo "retag $(VERSION) -> $$(git rev-parse --short "$(REF)") on $(RELEASE_REMOTE) ($(REPO)), which triggers a Docker Hub rebuild"
	@$(CONFIRM)
	@if [ "$$(git rev-parse $(REF))" = "$$(git rev-parse HEAD)" ]; then \
	   b=$$(git rev-parse --abbrev-ref HEAD); git push $(RELEASE_REMOTE) $$b; \
	   if [ "$(FORK_REMOTE)" != "$(RELEASE_REMOTE)" ] && git remote | grep -qx "$(FORK_REMOTE)"; then git push --quiet $(FORK_REMOTE) $$b || true; fi; \
	 fi
	@# The new tag is signed locally, then replaces the remote one in a single --force push:
	@# deleting the remote tag first left a window without it (a network error there, 2026-11-25,
	@# left base-php 8.4.28 untagged and its release a draft). -f replaces the local tag the same
	@# way: a failed signature leaves both tags where they were.
	@git tag -s -f -m "Version $(VERSION)" $(VERSION) $(REF)
	@git push --force $(RELEASE_REMOTE) refs/tags/$(VERSION)
	@echo "tag $(VERSION) pushed -> tag build triggered"
	@$(MAKE) --no-print-directory release-refresh VERSION=$(VERSION)

release-refresh: ## release-refresh VERSION=x.y.z : publish the GitHub release of a moved tag again (latest flag, notes)
	@$(NEED_VERSION)
	@# A 404 means there is no release to refresh; any other failure (network, auth) is reported
	@# with the command to run again, not taken for "no release".
	@if ! out=$$(gh api repos/$(REPO)/releases/tags/$(VERSION) --jq .id 2>&1); then \
	   case "$$out" in *"HTTP 404"*) echo "no GitHub release $(VERSION) (skip refresh)"; exit 0;; esac; \
	   echo "release $(VERSION) not refreshed ($$out): run 'make release-refresh VERSION=$(VERSION)'" >&2; exit 1; \
	 fi; \
	 gh release edit $(VERSION) --repo $(REPO) --draft=false --latest=$$( $(IS_LATEST) ) >/dev/null || { \
	   echo "release $(VERSION) not refreshed: run 'make release-refresh VERSION=$(VERSION)'" >&2; exit 1; }; \
	 prev=$$( $(PREV_TAG) ); \
	 if [ -z "$$prev" ]; then echo "release $(VERSION) re-published (no previous tag for notes)"; exit 0; fi; \
	 notes=$$(gh api repos/$(REPO)/releases/generate-notes -f tag_name=$(VERSION) -f previous_tag_name=$$prev --jq .body) && \
	   printf '%s\n' "$$notes" | gh release edit $(VERSION) --repo $(REPO) --notes-file - >/dev/null || { \
	   echo "release $(VERSION) published, notes not regenerated: run 'make release-refresh VERSION=$(VERSION)'" >&2; exit 1; }; \
	 echo "release $(VERSION) re-published, notes regenerated from $$prev"

tag-restore: ## tag-restore VERSION=x.y.z : force-push the LOCAL tag to the canonical remote (fix a moved tag)
	@$(NEED_VERSION)
	@git rev-parse -q --verify "refs/tags/$(VERSION)" >/dev/null || { echo "no local tag $(VERSION)" >&2; exit 1; }
	@echo "force-push local tag $(VERSION) ($$(git rev-parse --short "$(VERSION)^{commit}")) -> $(RELEASE_REMOTE) ($(REPO))"
	@$(CONFIRM)
	@git push --force $(RELEASE_REMOTE) refs/tags/$(VERSION)
	@echo "restored (a tag push may NOT rebuild if that commit was already built -> 'make build-version VERSION=$(VERSION)')"

notes: ## notes VERSION=x.y.z [SINCE=x.y.z] : regenerate the GitHub release notes
	@$(NEED_VERSION)
	@prev="$(SINCE)"; [ -n "$$prev" ] || prev=$$( $(PREV_TAG) ); \
	 [ -n "$$prev" ] || { echo "no previous tag found; pass SINCE=x.y.z" >&2; exit 1; }; \
	 notes=$$(gh api repos/$(REPO)/releases/generate-notes -f tag_name=$(VERSION) -f previous_tag_name=$$prev --jq .body) && \
	   printf '%s\n' "$$notes" | gh release edit $(VERSION) --repo $(REPO) --notes-file - >/dev/null && echo "notes for $(VERSION) regenerated from $$prev"

build-version: ## build-version VERSION=x.y.z : run the image workflow for VERSION by workflow_dispatch, without moving a tag
	@$(NEED_VERSION)
	@# --ref: the workflow as it stands on the release branch of VERSION.
	@ref="$(RELEASE_BRANCH)"; [ -n "$$ref" ] || ref=$$(git rev-parse --abbrev-ref HEAD); \
	 gh workflow run docker.yml --repo $(REPO) --ref $$ref -f version=$(VERSION) && echo "workflow_dispatch sent for $(VERSION) on $$ref"
