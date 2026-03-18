#!/usr/bin/env bats
load "../helpers/tests"
load "../helpers/containers"

load "../lib/batslib"
load "../lib/output"

source ${BATS_TEST_DIRNAME%/}/../.env

export BATS_CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

export BATS_CONTAINER_NAME="$(${BATS_CONTAINER_ENGINE} ps --filter "label=com.docker.compose.service=origin" --format "{{.Names}}")"

@test "[$TEST_FILE] Check for (Default) Index page response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9000/index.php -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (Default) Index page response message" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9000/index.php -H "Host: default.localhost" -s
  assert_output -l -r "Docker Base image - Default index.php page"
}

@test "[$TEST_FILE] Check for (App) MariaDB Connection CheckUp response code 200" {
  run curl http://localhost/check-db.php -H "Host: origin.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) MariaDB Connection CheckUp response message" {
  run curl http://localhost/check-db.php -H "Host: origin.localhost" -s
  assert_output -l -r "Check DB Connection Done."
}

@test "[$TEST_FILE] Check for (App) Index page response code 200" {
  run curl http://localhost/index.php -H "Host: origin.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) Index page response message" {
  run curl http://localhost/index.php -H "Host: origin.localhost" -s
  assert_output -l -r "Application index.php page"
}

@test "[$TEST_FILE] Check for (App) PHPINFO page response code 200" {
  run curl http://localhost/phpinfo.php -H "Host: origin.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for (App) PHPINFO page response message" {
  run curl http://localhost/phpinfo.php -H "Host: origin.localhost" -s
  assert_output -l -r "<h1 class=\"p\">PHP Version ${BATS_PHP_VERSION}</h1>"
}

@test "[$TEST_FILE] Check for (App) Custom response headers" {
  run curl http://localhost/index.php -H "Host: origin.localhost" -s -I
  assert_output -l -r "Test-Engine: bats"
}

@test "[$TEST_FILE] Check for Vhost Traffic Status Prometheus response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/metrics -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Vhost Traffic Status Prometheus response message" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/metrics -H "Host: default.localhost" -s
  assert_output -l -r "# HELP nginx_vts_info Nginx info"
}

@test "[$TEST_FILE] Check for Vhost Traffic Status Monitor Page response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/vts-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Vhost Traffic Status Monitor Page response message" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/vts-status -H "Host: default.localhost" -s
  assert_output -l -r "nginx vhost traffic status monitor"
}

@test "[$TEST_FILE] Check for PHP-FPM Ping response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/ping -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for PHP-FPM Ping response message" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/ping -H "Host: default.localhost" -s
  assert_output -l -r "pong"
}

@test "[$TEST_FILE] Check for PHP-FPM Status response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for PHP-FPM Status response message" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/status -H "Host: default.localhost" -s
  assert_output -l -r "max children reached"
}

@test "[$TEST_FILE] Check for Nginx Stub Status response code 200" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/stub-status -H "Host: default.localhost" -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Nginx Stub Status response message" {
  retry 12 5 curl_container ${BATS_CONTAINER_NAME} :9090/stub-status -H "Host: default.localhost" -s
  assert_output -l -r "server accepts handled requests"
}
