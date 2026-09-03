#!/usr/bin/env bats
#
# Assertions read through php-fpm rather than through the PHP CLI.
#
# The two do not always agree: a php_admin_value in the pool file overrides
# php.ini for php-fpm only, which is how an 8.4 image served memory_limit=16M
# while `php -r` in the same container reported 128M. A CLI check is the natural
# way to test locally and it is exactly the check that misses this class of
# defect, so everything below goes over HTTP through the web server.

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

export BATS_VARIANT="${BATS_VARIANT:-nginx}"
export BATS_TARGET="${BATS_TARGET:-prd}"

# Boot a container of the image under test, publish its HTTP port on the
# loopback and wait for the health check. Echoes the published port.
#
# $1 container name
# $@ additional options to pass to `docker run`
web_container_start() {
  local -r container=$1
  shift

  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${container}" \
    --publish 127.0.0.1::9000 --publish 127.0.0.1::9090 \
    "$@" "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")" >/dev/null

  # container_wait_for_healthy echoes the matched health state through retry,
  # which would otherwise end up in the port this function returns.
  container_wait_for_healthy "${container}" 60 >/dev/null

  ${BATS_CONTAINER_ENGINE} port "${container}" 9000/tcp | head -1 | sed 's/.*://'
}

# Serve a PHP snippet from the docroot of container $1 and echo the response.
#
# $1 container name
# $2 published port
# $3 PHP snippet
web_php() {
  local -r container=$1
  local -r port=$2
  local -r snippet=$3
  local -r script="probe-${RANDOM}.php"

  ${BATS_CONTAINER_ENGINE} exec -i "${container}" \
    sh -c "cat > /app/var/www/html/${script}" <<<"${snippet}"

  curl --silent --fail --max-time 20 "http://127.0.0.1:${port}/${script}"
}

# Write a file into the docroot of container $1 under name $2.
web_put() {
  ${BATS_CONTAINER_ENGINE} exec -i "$1" \
    sh -c "mkdir -p \$(dirname /app/var/www/html/$2); cat > /app/var/www/html/$2"
}

# Status code for path $2 on port $1 of the container under test.
web_status() {
  curl --silent --output /dev/null --write-out '%{http_code}' --max-time 20 "http://127.0.0.1:$1$2"
}

setup_file() {
  export BATS_WEB_CONTAINER="bats-web-${BATS_VARIANT}-${BATS_TARGET}-$$"
  container_clean "${BATS_WEB_CONTAINER}"
  export BATS_WEB_PORT="$(web_container_start "${BATS_WEB_CONTAINER}")"
  export BATS_MONITORING_PORT="$(${BATS_CONTAINER_ENGINE} port "${BATS_WEB_CONTAINER}" 9090/tcp | head -1 | sed 's/.*://')"

  # Fixtures an application would hold and a base image must never hand out.
  web_put "${BATS_WEB_CONTAINER}" secret.php <<<'<?php $credential = "s3cr3t"; echo "executed";'
  web_put "${BATS_WEB_CONTAINER}" .env <<<'APP_SECRET=very-secret'
  web_put "${BATS_WEB_CONTAINER}" .git/config <<<'[remote "origin"] url = git@internal:app.git'
  web_put "${BATS_WEB_CONTAINER}" .well-known/probe.txt <<<'well-known ok'
}

teardown_file() {
  container_clean "${BATS_WEB_CONTAINER}"
  container_clean "${BATS_WEB_CONTAINER}-memory"
  container_clean "${BATS_WEB_CONTAINER}-drain"
}

@test "[$TEST_FILE] The container reports healthy" {
  container_assert_healthy "${BATS_WEB_CONTAINER}"
}

@test "[$TEST_FILE] php-fpm runs the expected PHP version" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" '<?php echo PHP_VERSION;'
  assert_line "${BATS_PHP_VERSION}"
}

@test "[$TEST_FILE] php-fpm answers requests over FastCGI, not as source" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" '<?php echo "executed";'
  assert_line "executed"
}

# Guards the php_admin_value regression: the pool file must not pin memory_limit,
# or the two assertions below report 16M whatever php.ini and the environment say.
@test "[$TEST_FILE] memory_limit through php-fpm is the php.ini default" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" '<?php echo ini_get("memory_limit");'
  assert_line "${BATS_PHP_MEMORY_LIMIT}"
}

@test "[$TEST_FILE] PHP_MEMORY_LIMIT reaches php-fpm" {
  local -r container="${BATS_WEB_CONTAINER}-memory"
  local port

  port="$(web_container_start "${container}" --env PHP_MEMORY_LIMIT=512M)"

  # Nothing may run between `run` and the assertion: any command resets $output.
  # The container is removed in teardown_file.
  run web_php "${container}" "${port}" '<?php echo ini_get("memory_limit");'
  assert_line "512M"
}

@test "[$TEST_FILE] A request may allocate up to the configured limit" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" \
    '<?php $b = str_repeat("x", 32 * 1024 * 1024); echo "allocated ", strlen($b);'
  assert_line "allocated 33554432"
}

@test "[$TEST_FILE] expose_php stays off" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" '<?php echo ini_get("expose_php") ? "on" : "off";'
  assert_line "off"
}

@test "[$TEST_FILE] Xdebug is absent from a production image" {
  [ "${BATS_TARGET}" = "prd" ] || skip "the development image ships Xdebug on purpose"

  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" \
    '<?php echo extension_loaded("xdebug") ? "loaded" : "absent";'
  assert_line "absent"
}

# The monitoring server declared the application docroot as its root and had no
# catch-all, so every path that was not an endpoint fell through to the static
# handler -- returning PHP as source, and outside the MONITORING_ALLOW check,
# which guards the named locations only.
@test "[$TEST_FILE] The monitoring port serves no application file" {
  [ "${BATS_VARIANT}" = "nginx" ] || skip "only the nginx variant has a separate monitoring port"

  run web_status "${BATS_MONITORING_PORT}" /secret.php
  assert_line "404"
}

@test "[$TEST_FILE] The monitoring port endpoints still answer" {
  [ "${BATS_VARIANT}" = "nginx" ] || skip "only the nginx variant has a separate monitoring port"

  local endpoint
  for endpoint in /healthcheck /metrics /vts-status /stub-status /real-time-status /status /ping; do
    run web_status "${BATS_MONITORING_PORT}" "${endpoint}"
    assert_line "200"
  done
}

# A prefix match answered on /metricsfoo and resolved any path under the
# /real-time-status alias.
@test "[$TEST_FILE] The monitoring endpoints are exact paths" {
  [ "${BATS_VARIANT}" = "nginx" ] || skip "only the nginx variant has a separate monitoring port"

  run web_status "${BATS_MONITORING_PORT}" /metricsfoo
  assert_line "404"
}

@test "[$TEST_FILE] Dotfiles in the docroot are not served" {
  run web_status "${BATS_WEB_PORT}" /.env
  assert_line "404"
}

@test "[$TEST_FILE] A file inside a dot directory is not served" {
  run web_status "${BATS_WEB_PORT}" /.git/config
  assert_line "404"
}

@test "[$TEST_FILE] /.well-known keeps its normal handling" {
  run web_status "${BATS_WEB_PORT}" /.well-known/probe.txt
  assert_line "200"
}

# The docroot was browsable and the PHP front controller was not a DirectoryIndex
# candidate, so / returned a listing of the application files instead of running
# the application.
@test "[$TEST_FILE] The document root is not browsable" {
  ${BATS_CONTAINER_ENGINE} exec "${BATS_WEB_CONTAINER}" rm -f /app/var/www/html/index.html
  web_put "${BATS_WEB_CONTAINER}" index.php <<<'<?php echo "front controller";'

  run curl --silent --max-time 20 "http://127.0.0.1:${BATS_WEB_PORT}/"
  assert_line "front controller"
}

@test "[$TEST_FILE] TRACE is refused" {
  run curl --silent --output /dev/null --write-out '%{http_code}' --max-time 20 \
    --request TRACE "http://127.0.0.1:${BATS_WEB_PORT}/"
  refute_line "200"
}

# ServerTokens is Prod, so the error page footer must not disagree by printing
# the server version and port.
@test "[$TEST_FILE] Error pages carry no server signature" {
  run curl --silent --max-time 20 "http://127.0.0.1:${BATS_WEB_PORT}/no-such-path"
  refute_output --partial "<address>"
}

# php-fpm's process_control_timeout defaults to 0, which makes the master kill
# its children on a graceful stop instead of waiting: every rollout, scale-down
# and eviction cut the requests in flight, and the client saw a 502.
@test "[$TEST_FILE] A request in flight survives a graceful stop" {
  local -r container="${BATS_WEB_CONTAINER}-drain"
  local port

  port="$(web_container_start "${container}")"
  # A clock loop, not sleep(): sleep is interrupted by the stop signal and
  # returns early, which reports a pass on an image that drains nothing.
  web_put "${container}" slow.php <<<'<?php $end = microtime(true) + 8; while (microtime(true) < $end) { usleep(100000); } echo "completed";'

  curl --silent --max-time 60 "http://127.0.0.1:${port}/slow.php" > "${BATS_TEST_TMPDIR}/drain" &
  local -r client=$!
  sleep 2
  ${BATS_CONTAINER_ENGINE} stop --time 30 "${container}" >/dev/null
  wait "${client}"

  run cat "${BATS_TEST_TMPDIR}/drain"
  assert_output "completed"
}
