#!/usr/bin/env bats
load "../helpers/tests"
load "../helpers/containers"

load "../lib/batslib"
load "../lib/output"

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
  assert_output -l -r "Aggregated"
}
