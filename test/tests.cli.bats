#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"

# bats-support and bats-assert are resolved through BATS_LIB_PATH: the CI job
# gets it from bats-core/bats-action, a local run from `make -C test deps`,
# which clones the same pinned tags into test/lib.
export BATS_LIB_PATH="${BATS_LIB_PATH:+${BATS_LIB_PATH}:}${BATS_TEST_DIRNAME%/}/lib"

bats_load_library bats-support
bats_load_library bats-assert

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
  assert_line --regexp "^PHP ${BATS_PHP_VERSION} \(cli\) \(.*\) \(NTS\)"
}

@test "[$TEST_FILE] Testing NPM Version (with unrecognized uid and anonymous volumes)" {
  run ${BATS_CONTAINER_ENGINE} run --pull=never -u 1000 --read-only --rm \
    -v /app/tmp \
    -v /opt/etc \
    "${BATS_CLI_IMAGE}" npm -v
  assert_line --regexp "^[0-9]+.[0-9]+.[0-9]+*$"
}

@test "[$TEST_FILE] Test aws cli version" {
  run_cli "${BATS_CLI_IMAGE}" aws --version
  assert_line --regexp "^aws-cli/${BATS_AWS_CLI_VERSION} Python/.* .*$"
}

@test "[$TEST_FILE] Test GH cli version (dev only)" {
  [ "${BATS_TARGET}" = "dev" ] || skip "the GitHub CLI ships in cli-dev only"

  run_cli "${BATS_CLI_IMAGE}" gh --version
  assert_line --regexp "^gh version [0-9]+\.[0-9]+\.[0-9]+ \([^)]+\)$"
}

# The cli variant sourced no AWS script at all: no rendered configuration, no
# wrapper -- and, because nothing registered the variables for cleanup, the raw
# AWS_* reached the process. That is the opposite of what the web variants do,
# in the variant most likely to actually run `aws`.
@test "[$TEST_FILE] The cli variant renders the AWS configuration" {
  run_cli "${BATS_CLI_IMAGE}" sh -c 'command -v aws; ls /opt/etc/aws'
  assert_line "/usr/local/bin/aws"
  assert_line "config"
  assert_line "wrapper.env"
}

# The policy this image applies on purpose: the CLI is configured through files,
# so no AWS credential is left in the environment the application runs in.
@test "[$TEST_FILE] AWS credentials never reach the application environment" {
  run_cli \
    -e AWS_ACCESS_KEY_ID=AKIAEXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=secret \
    -e AWS_SESSION_TOKEN=FwoGZXIvEXAMPLE \
    "${BATS_CLI_IMAGE}" \
    sh -c 'echo "id=${AWS_ACCESS_KEY_ID:-unset} secret=${AWS_SECRET_ACCESS_KEY:-unset} token=${AWS_SESSION_TOKEN:-unset}"'
  assert_line "id=unset secret=unset token=unset"
}

# Temporary credentials (STS, assume-role) are rejected without their session
# token, and the credentials template rendered only the two long-term keys.
@test "[$TEST_FILE] Temporary credentials are rendered with their session token" {
  run_cli \
    -e AWS_ACCESS_KEY_ID=ASIAEXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=secret \
    -e AWS_SESSION_TOKEN=FwoGZXIvEXAMPLE \
    "${BATS_CLI_IMAGE}" sh -c 'cat /opt/etc/aws/credentials'
  assert_line "aws_session_token=FwoGZXIvEXAMPLE"
}

# Both templates used to hard-code [default], so a named profile produced files
# the CLI could not find. The config file prefixes every non-default profile
# with "profile", the credentials file never does.
@test "[$TEST_FILE] A named AWS profile is honoured" {
  run_cli \
    -e AWS_PROFILE=ci \
    -e AWS_ACCESS_KEY_ID=AKIAEXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=secret \
    "${BATS_CLI_IMAGE}" sh -c 'cat /opt/etc/aws/config /opt/etc/aws/credentials'
  assert_line "[profile ci]"
  assert_line "[ci]"
}
