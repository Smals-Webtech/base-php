#!/usr/bin/make -f

.DEFAULT_GOAL := help
.PHONY: help demo-test

help: ## Show help for each of the Makefile recipes.
	@grep -E '(^\S*:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

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

