#!/usr/bin/env bats
load "helpers/tests"
load "helpers/containers"

load "lib/batslib"
load "lib/output"

source ${BATS_TEST_DIRNAME%/}/../.env

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

@test "[$TEST_FILE] Check for Index page response code 200" {
  run curl http://localhost:9001/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Index page response message" {
  run curl http://localhost:9001/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for Monitoring /real-time-status page response code 200" {
  run curl http://localhost:9001/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /status page response code 200" {
  run curl http://localhost:9001/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /server-status page response code 200" {
  run curl http://localhost:9001/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Index page response code 200 via Varnish" {
  run curl http://localhost:6081/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Index page response message via Varnish" {
  run curl http://localhost:6081/index.php -H "Host: default.localhost" -s 
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Re-Check for Monitoring /real-time-status page response code 200 via Varnish" {
  run curl http://localhost:6081/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Monitoring /status page response code 200 via Varnish" {
  run curl http://localhost:6081/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Monitoring /server-status page response code 200 via Varnish" {
  run curl http://localhost:6081/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}
