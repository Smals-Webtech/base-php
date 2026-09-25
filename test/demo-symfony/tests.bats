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

@test "[$TEST_FILE] Check for (Default) Index page response code 200" {
  run curl http://localhost/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_line -n 0 $'200'
}

@test "[$TEST_FILE] Check for (Default) Index page response message" {
  run curl http://localhost/index.php -H "Host: default.localhost" -s 
  assert_line --regexp "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for (App) Symfony Demo /fr/blog/ response code 200" {
  run curl http://localhost/fr/blog/ -H "Host: demo.localhost" -s -w %{http_code} -o /dev/null
  assert_line -n 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Symfony Demo /fr/blog/search response code 200" {
  run curl http://localhost/fr/blog/search -H "Host: demo.localhost" -s -w %{http_code} -o /dev/null
  assert_line -n 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Symfony Demo /fr/login response code 200" {
  run curl http://localhost/fr/login -H "Host: demo.localhost" -s -w %{http_code} -o /dev/null
  assert_line -n 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Symfony Demo Custom response headers" {
  run curl http://localhost/ -H "Host: demo.localhost" -s -I
  assert_line --regexp "Test-Engine: bats"
}
# The demo's SQLite database lived in the code mount, owned by whoever cloned the
# demo: the web (1001:0) read it but could not write it, nor create the journal
# SQLite needs next to it, and every edit answered 500 "attempt to write a
# readonly database". It now lives on the writable /app/var volume. A no-op
# UPDATE still takes the write lock and the journal, as the web user (the
# container's) and as the caller's uid, the one the Makefile's console commands
# run under.
@test "[$TEST_FILE] The web user and the caller can write the demo database" {
  local compose="${BATS_CONTAINER_COMPOSE_ENGINE} --project-directory=${BATS_TEST_DIRNAME} --env-file=${BATS_TEST_DIRNAME}/../.env --profile=symfony"
  local sql="UPDATE symfony_demo_post SET title = title WHERE id = 1"

  run ${compose} exec -T symfony php bin/console dbal:run-sql "${sql}"
  assert_success
  assert_output --partial "1 rows affected"

  run ${compose} exec -T --user "$(id -u)" symfony php bin/console dbal:run-sql "${sql}"
  assert_success
  assert_output --partial "1 rows affected"
}
