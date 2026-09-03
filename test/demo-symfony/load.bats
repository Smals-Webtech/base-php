#!/usr/bin/env bats
load "../helpers/tests"
load "../helpers/containers"

# bats-support and bats-assert are resolved through BATS_LIB_PATH: the CI job
# gets it from bats-core/bats-action, a local run from `make -C test deps`,
# which clones the same pinned tags into test/lib.
export BATS_LIB_PATH="${BATS_LIB_PATH:+${BATS_LIB_PATH}:}${BATS_TEST_DIRNAME%/}/../lib"

bats_load_library bats-support
bats_load_library bats-assert

source ${BATS_TEST_DIRNAME%/}/../.env

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

# Requires the demo stack up: demo-infra (traefik, profile all) + symfony started.
# A short headless Locust run: --exit-code-on-error 1 makes the process exit non-zero
# if ANY request failed, so assert_success alone proves 0 failures; the Aggregated
# line proves requests were actually generated.
@test "[$TEST_FILE] Locust headless load has 0 failures and generates requests" {
  run make load LOCUST_USERS=5 LOCUST_SPAWN_RATE=5 LOCUST_RUN_TIME=15s
  assert_success
  assert_line --regexp "Aggregated"
}
