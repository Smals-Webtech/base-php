#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"

load "lib/batslib"
load "lib/output"

source ${BATS_TEST_DIRNAME%/}/../.env

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

export BATS_CONTAINER_NETWORK_NAME="base-php_default"

@test "[$TEST_FILE] Check for (App) PHP Info page response code 200" {
  run curl http://localhost:9000/phpinfo.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Index page response code 200" {
  run curl http://localhost:9000/index.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Index page response message" {
  run curl http://localhost:9000/index.php -H "Host: localhost" -s 
  assert_output -l -r "Application index.php page"
}

@test "[$TEST_FILE] Check for (App) MariaDB Connection CheckUp response code 200" {
  run curl http://localhost:9000/check-db.php -H "Host: localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) MariaDB Connection CheckUp response message" {
  run curl http://localhost:9000/check-db.php -H "Host: localhost" -s 
  assert_output -l -r "Check DB Connection Done."
}
