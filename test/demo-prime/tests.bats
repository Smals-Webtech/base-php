#!/usr/bin/env bats
load "../helpers/tests"
load "../helpers/containers"

load "../lib/batslib"
load "../lib/output"

source ${BATS_TEST_DIRNAME%/}/../.env

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

export BATS_CONTAINER_NAME="$(${BATS_CONTAINER_ENGINE} ps --filter "label=com.docker.compose.service=prime" --format "{{.Names}}")"

@test "[$TEST_FILE] Check for Index page response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9000/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Index page response message" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9000/index.php -H "Host: default.localhost" -s
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for Monitoring /real-time-status page response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9000/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /status page response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9000/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Monitoring /server-status page response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9000/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Index page response code 200 via Varnish" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :6081/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Index page response message via Varnish" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :6081/index.php -H "Host: default.localhost" -s
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Re-Check for Monitoring /real-time-status page response code 200 via Varnish" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :6081/real-time-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Monitoring /status page response code 200 via Varnish" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :6081/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Re-Check for Monitoring /server-status page response code 200 via Varnish" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :6081/server-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) index.php response code 200" {
  run curl http://localhost/index.php -H "Host: prime-nocache.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) index.php response code 200 via Varnish" {
  run curl http://localhost/index.php -H "Host: prime.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}