#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"

load "lib/batslib"
load "lib/output"

source ${BATS_TEST_DIRNAME%/}/.env

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

# The variant is fixed, the target follows the build under test: a build job
# produces one image, and only cli-dev carries the GitHub CLI.
BATS_TARGET="${BATS_TARGET:-prd}"
BATS_CLI_IMAGE="$(image_tag cli "${BATS_TARGET}")"

# --pull=never keeps a missing local image an error instead of a silent pull of
# the published one, which would test an image this build never produced.
run_cli() {
  run ${BATS_CONTAINER_ENGINE} run --pull=never --read-only --rm \
    -v php_cli_app_tmp:/app/tmp \
    -v php_cli_opt_etc:/opt/etc \
    "$@"
}

setup_file() {
  command ${BATS_CONTAINER_ENGINE} volume create php_cli_app_tmp
  command ${BATS_CONTAINER_ENGINE} volume create php_cli_opt_etc
}

teardown_file() {
  command ${BATS_CONTAINER_ENGINE} volume rm -f php_cli_app_tmp php_cli_opt_etc
}

@test "[$TEST_FILE] Test PHP version" {
  run_cli "${BATS_CLI_IMAGE}" -v
  assert_output -l -r "^PHP ${BATS_PHP_VERSION} \(cli\) \(.*\) \(NTS\)"
}

@test "[$TEST_FILE] Testing NPM Version (with unrecognized uid and anonymous volumes)" {
  run ${BATS_CONTAINER_ENGINE} run --pull=never -u 1000 --read-only --rm \
    -v /app/tmp \
    -v /opt/etc \
    "${BATS_CLI_IMAGE}" npm -v
  assert_output -l -r "^[0-9]+.[0-9]+.[0-9]+*$"
}

@test "[$TEST_FILE] Test aws cli version" {
  run_cli "${BATS_CLI_IMAGE}" aws --version
  assert_output -l -r "^aws-cli/${BATS_AWS_CLI_VERSION} Python/.* .*$"
}

@test "[$TEST_FILE] Test GH cli version (dev only)" {
  [ "${BATS_TARGET}" = "dev" ] || skip "the GitHub CLI ships in cli-dev only"

  run_cli "${BATS_CLI_IMAGE}" gh --version
  assert_output -l -r "^gh version [0-9]+\.[0-9]+\.[0-9]+ \([^)]+\)$"
}
