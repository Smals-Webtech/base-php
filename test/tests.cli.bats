#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"

load "lib/batslib"
load "lib/output"

source ${BATS_TEST_DIRNAME%/}/../.env

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

@test "[$TEST_FILE] Create Docker Volumes" {
  command docker volume create php_cli_app_tmp
  command docker volume create php_cli_app_etc
}

@test "[$TEST_FILE] Test PHP version" {
  run ${BATS_CONTAINER_ENGINE} run --read-only --rm \
  -v php_cli_app_tmp:/app/tmp \
  -v php_cli_app_etc:/app/etc \
  smalswebtech/base-php:cli -v
  assert_output -l -r "^PHP ${BATS_PHP_VERSION} \(cli\) \(.*\) \(NTS\)"
}

@test "[$TEST_FILE] Testing NPM Version (with unrecognized uid)" {
  run ${BATS_CONTAINER_ENGINE} run -u 1000 --read-only --rm \
  -v php_cli_app_tmp:/app/tmp \
  -v php_cli_app_etc:/app/etc \
  smalswebtech/base-php:cli npm -v
  assert_output -l -r "^[0-9]+.[0-9]+.[0-9]+*$"
}

@test "[$TEST_FILE] Test aws cli version" {
  run ${BATS_CONTAINER_ENGINE} run --read-only --rm \
  -v php_cli_app_tmp:/app/tmp \
  -v php_cli_app_etc:/app/etc \
  smalswebtech/base-php:cli aws --version
  assert_output -l -r "^aws-cli/${BATS_AWS_CLI_VERSION} Python/.* .*$"
}

@test "[$TEST_FILE] Remove Docker Volumes" {
  command docker volume rm php_cli_app_tmp
  command docker volume rm php_cli_app_etc
}