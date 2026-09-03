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

load "lib/batslib"
load "lib/output"

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
    --publish 127.0.0.1::9000 "$@" "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")" >/dev/null

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

setup_file() {
  export BATS_WEB_CONTAINER="bats-web-${BATS_VARIANT}-${BATS_TARGET}-$$"
  container_clean "${BATS_WEB_CONTAINER}"
  export BATS_WEB_PORT="$(web_container_start "${BATS_WEB_CONTAINER}")"
}

teardown_file() {
  container_clean "${BATS_WEB_CONTAINER}"
  container_clean "${BATS_WEB_CONTAINER}-memory"
}

@test "[$TEST_FILE] The container reports healthy" {
  container_assert_healthy "${BATS_WEB_CONTAINER}"
}

@test "[$TEST_FILE] php-fpm runs the expected PHP version" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" '<?php echo PHP_VERSION;'
  assert_output -l "${BATS_PHP_VERSION}"
}

@test "[$TEST_FILE] php-fpm answers requests over FastCGI, not as source" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" '<?php echo "executed";'
  assert_output -l "executed"
}

# Guards the php_admin_value regression: the pool file must not pin memory_limit,
# or the two assertions below report 16M whatever php.ini and the environment say.
@test "[$TEST_FILE] memory_limit through php-fpm is the php.ini default" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" '<?php echo ini_get("memory_limit");'
  assert_output -l "${BATS_PHP_MEMORY_LIMIT}"
}

@test "[$TEST_FILE] PHP_MEMORY_LIMIT reaches php-fpm" {
  local -r container="${BATS_WEB_CONTAINER}-memory"
  local port

  port="$(web_container_start "${container}" --env PHP_MEMORY_LIMIT=512M)"

  # Nothing may run between `run` and the assertion: any command resets $output.
  # The container is removed in teardown_file.
  run web_php "${container}" "${port}" '<?php echo ini_get("memory_limit");'
  assert_output -l "512M"
}

@test "[$TEST_FILE] A request may allocate up to the configured limit" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" \
    '<?php $b = str_repeat("x", 32 * 1024 * 1024); echo "allocated ", strlen($b);'
  assert_output -l "allocated 33554432"
}

@test "[$TEST_FILE] expose_php stays off" {
  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" '<?php echo ini_get("expose_php") ? "on" : "off";'
  assert_output -l "off"
}

@test "[$TEST_FILE] Xdebug is absent from a production image" {
  [ "${BATS_TARGET}" = "prd" ] || skip "the development image ships Xdebug on purpose"

  run web_php "${BATS_WEB_CONTAINER}" "${BATS_WEB_PORT}" \
    '<?php echo extension_loaded("xdebug") ? "loaded" : "absent";'
  assert_output -l "absent"
}
