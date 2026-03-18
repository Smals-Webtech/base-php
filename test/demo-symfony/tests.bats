#!/usr/bin/env bats
load "../helpers/tests"
load "../helpers/containers"

load "../lib/batslib"
load "../lib/output"

source ${BATS_TEST_DIRNAME%/}/../.env

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

@test "[$TEST_FILE] Check for (Default) Index page response code 200" {
  run curl http://localhost/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (Default) Index page response message" {
  run curl http://localhost/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for (App) Symfony Demo /fr/blog/ response code 200" {
  run curl http://localhost/fr/blog/ -H "Host: demo.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Symfony Demo /fr/blog/search response code 200" {
  run curl http://localhost/fr/blog/search -H "Host: demo.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Symfony Demo /fr/login response code 200" {
  run curl http://localhost/fr/login -H "Host: demo.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Symfony Demo Custom response headers" {
  run curl http://localhost/ -H "Host: demo.localhost" -s -I
  assert_output -l -r "Test-Engine: bats"
}