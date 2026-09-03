#!/usr/bin/make -f

.DEFAULT_GOAL := help
.PHONY: help deps demo-test FORCE

# Pinned so a local run and a CI run load the same assertions. The CI job takes
# the same versions through bats-core/bats-action.
BATS_SUPPORT_VERSION           = v0.3.0
BATS_ASSERT_VERSION            = v2.1.0

help: ## Show help for each of the Makefile recipes.
	@grep -E '(^\S*:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

# —— Dependencies —————————————————————————————————————————————————————————————————————————————————————————————————————

deps: ## deps : fetch bats-support and bats-assert into lib/ at the pinned tags
	@$(MAKE) --no-print-directory lib/bats-support VERSION=$(BATS_SUPPORT_VERSION)
	@$(MAKE) --no-print-directory lib/bats-assert VERSION=$(BATS_ASSERT_VERSION)

# FORCE rather than .PHONY: make skips the implicit rule search for a phony
# target, so a pattern rule declared phony never fires. Comparing the tag that
# is actually checked out keeps the target idempotent while still reacting to a
# version bump above.
lib/bats-%: FORCE
	@if [ "$$(git -C "$@" describe --tags 2>/dev/null)" = "$(VERSION)" ]; then \
	   echo "bats-$* $(VERSION) -> $@ (up to date)"; \
	 else \
	   rm -rf "$@"; \
	   git clone --quiet --branch "$(VERSION)" --depth 1 "https://github.com/bats-core/bats-$*.git" "$@"; \
	   echo "bats-$* $(VERSION) -> $@"; \
	 fi

FORCE:

# —— Demo —————————————————————————————————————————————————————————————————————————————————————————————————————————————

demo-test:
	@$(MAKE) infra/start
	@$(MAKE) symfony/build
	@$(MAKE) symfony/start
	@$(MAKE) symfony/configure
	@$(MAKE) symfony/test

symfony/%:
	@$(MAKE) -C demo-symfony ${*}

# —— Infra ————————————————————————————————————————————————————————————————————————————————————————————————————————————

infra/%:
	@$(MAKE) -C demo-infra ${*}

# —— Prime ————————————————————————————————————————————————————————————————————————————————————————————————————————————

prime/%:
	@$(MAKE) -C demo-prime ${*}

# —— Origin ———————————————————————————————————————————————————————————————————————————————————————————————————————————

origin/%:
	@$(MAKE) -C demo-origin ${*}

