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
  container_clean "${BATS_WEB_CONTAINER}-logrotate"
  container_clean "${BATS_WEB_CONTAINER}-failfast"
  container_clean "${BATS_WEB_CONTAINER}-init1"
  container_clean "${BATS_WEB_CONTAINER}-init2"
  container_clean "${BATS_WEB_CONTAINER}-etc1"
  container_clean "${BATS_WEB_CONTAINER}-etc2"
  container_clean "${BATS_WEB_CONTAINER}-ro"
  container_clean "${BATS_WEB_CONTAINER}-plain"
  container_clean "${BATS_WEB_CONTAINER}-mounts"
  container_clean "${BATS_WEB_CONTAINER}-hook0"
  container_clean "${BATS_WEB_CONTAINER}-hooklock"
  container_clean "${BATS_WEB_CONTAINER}-hookenv"
  container_clean "${BATS_WEB_CONTAINER}-port"
  container_clean "${BATS_WEB_CONTAINER}-remoteip"
  container_clean "${BATS_WEB_CONTAINER}-slowlog"
  container_clean "${BATS_WEB_CONTAINER}-stanza"
  ${BATS_CONTAINER_ENGINE} volume rm -f "${BATS_WEB_CONTAINER}-lock" "${BATS_WEB_CONTAINER}-log" \
    "${BATS_WEB_CONTAINER}-etc" >/dev/null 2>&1 || true
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
  run web_status "${BATS_MONITORING_PORT}" /secret.php
  assert_line "404"
}

@test "[$TEST_FILE] The monitoring port endpoints still answer" {
  local endpoint endpoints

  # The two web servers expose different sets: the nginx ones come from VTS and
  # the stub-status module, apache's from mod_status. What both must satisfy is
  # that every endpoint they do publish answers on the monitoring port.
  case "${BATS_VARIANT}" in
    nginx)  endpoints="/healthcheck /metrics /vts-status /stub-status /real-time-status /status /ping" ;;
    apache) endpoints="/server-status /status /real-time-status" ;;
    *)      skip "no monitoring port on the ${BATS_VARIANT} variant" ;;
  esac

  for endpoint in ${endpoints}; do
    run web_status "${BATS_MONITORING_PORT}" "${endpoint}"
    assert_line "200"
  done
}

# A prefix match answered on /metricsfoo and resolved any path under the
# /real-time-status alias.
@test "[$TEST_FILE] The monitoring endpoints are exact paths" {
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

# nginx sizes the buffer that has to hold the whole response header at one page
# by default, so a framework putting a session cookie and a few Link headers on
# the response overran it and the request failed as a 502.
@test "[$TEST_FILE] A large response header does not fail the request" {
  [ "${BATS_VARIANT}" = "nginx" ] || skip "mod_proxy_fcgi caps a header line at 8k and offers no knob"

  web_put "${BATS_WEB_CONTAINER}" big-header.php \
    <<<'<?php header("X-Big: " . str_repeat("a", 9 * 1024)); echo "ok";'

  run web_status "${BATS_WEB_PORT}" /big-header.php
  assert_output "200"
}

# The option list used to be split on whitespace and sorted, so a directive
# carrying an argument -- "maxage 7" -- reached the stanza as two lines in
# alphabetical order. logrotate rejects that and skips the whole stanza, which
# stops every file from being rotated, silently, for the life of the container.
@test "[$TEST_FILE] A logrotate directive with an argument still rotates" {
  local -r container="${BATS_WEB_CONTAINER}-logrotate"
  local port

  port="$(web_container_start "${container}" \
    --env "LOGROTATE_DEFAULT_OPTIONS=compress;copytruncate;missingok;notifempty;maxage 7" \
    --env "LOGROTATE_DEFAULT_SIZE_LIMIT=1k")"

  ${BATS_CONTAINER_ENGINE} exec "${container}" sh -c \
    'head -c 4096 /dev/zero | tr "\0" "x" > /app/var/log/rotate-me.log; /opt/sbin/logrotate.sh'

  run ${BATS_CONTAINER_ENGINE} exec "${container}" test -f /app/var/log/rotate-me.log.1.gz
  assert_success
}

# The fail-fast listener keyed on the event payload's `expected` field, which
# reports whether the exit code was in the program's `exitcodes` list -- not
# whether supervisor asked for the exit. A SIGTERM reaching the php-fpm master
# from outside supervisor makes it exit 0, so the listener stayed silent and the
# container kept running with no php-fpm behind the web server.
@test "[$TEST_FILE] An exit of php-fpm stops the container" {
  local -r container="${BATS_WEB_CONTAINER}-failfast"

  web_container_start "${container}" >/dev/null

  ${BATS_CONTAINER_ENGINE} exec "${container}" sh -c \
    'kill -TERM $(supervisorctl -c /opt/etc/supervisord.conf pid php-fpm)'

  # A bounded wait on the state, not `retry`: retry stops as soon as the command
  # succeeds, and container_running_state succeeds while printing "true".
  local i
  for ((i = 0; i < 40; i++)); do
    [ "$(container_running_state "${container}")" = "false" ] && break
    sleep .5
  done

  run container_running_state "${container}"
  assert_output "false"
}

# nginx set access_log off inside the PHP location and apache pointed the default
# vhost logs at /dev/null, so the only trace of a PHP request was php-fpm's own
# line -- which began "- -", %R being the peer address of a unix socket.
@test "[$TEST_FILE] A PHP request is logged with the client address" {
  local -r marker="logged-${RANDOM}"

  web_put "${BATS_WEB_CONTAINER}" "${marker}.php" <<<'<?php echo "ok";'
  curl --silent --output /dev/null --max-time 20 "http://127.0.0.1:${BATS_WEB_PORT}/${marker}.php"

  run ${BATS_CONTAINER_ENGINE} logs "${BATS_WEB_CONTAINER}"
  assert_line --regexp "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} .*${marker}"
}

# The apache default vhost discarded everything, so a 404 -- and any 5xx, and the
# PHP errors mod_proxy_fcgi relays -- left no trace at all.
@test "[$TEST_FILE] A request that reaches no handler is still logged" {
  local -r marker="missing-${RANDOM}"

  curl --silent --output /dev/null --max-time 20 "http://127.0.0.1:${BATS_WEB_PORT}/${marker}"

  run ${BATS_CONTAINER_ENGINE} logs "${BATS_WEB_CONTAINER}"
  assert_line --regexp "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} .*${marker}"
}

# The TICK_60 subscriber echoed the event header and the payload on every tick,
# and the listener's stdout -- which is the protocol channel, not a log stream --
# was captured too, so a RESULT line joined them. Two lines a minute, forever,
# burying whatever else the container had to say.
@test "[$TEST_FILE] The tick listener is quiet" {
  # The assertion only means something once a TICK_60 has fired. The shared
  # container has been up since setup_file, so by this point that has usually
  # happened already; wait out whatever is left rather than a flat 60 seconds.
  local -r started="$(${BATS_CONTAINER_ENGINE} inspect -f '{{.State.StartedAt}}' "${BATS_WEB_CONTAINER}")"
  local -r uptime=$(( $(date +%s) - $(date -d "${started}" +%s) ))

  [ "${uptime}" -gt 65 ] || sleep $(( 65 - uptime ))

  run ${BATS_CONTAINER_ENGINE} logs "${BATS_WEB_CONTAINER}"
  refute_line --regexp "eventname:TICK_60"
  refute_line --regexp "^RESULT [0-9]"
}

# .js is served as application/javascript, which the gzip_types list omitted --
# it carried application/x-javascript and text/javascript, neither of which this
# image ever emits, so no script was ever compressed.
@test "[$TEST_FILE] Javascript is compressed" {
  [ "${BATS_VARIANT}" = "nginx" ] || skip "apache compresses application/javascript already"

  web_put "${BATS_WEB_CONTAINER}" app.js <<<"$(head -c 3000 /dev/zero | tr '\0' 'x')"

  run curl --silent --head --header 'Accept-Encoding: gzip' --max-time 20 \
    "http://127.0.0.1:${BATS_WEB_PORT}/app.js"
  assert_line --regexp '^[Cc]ontent-[Ee]ncoding: gzip'
}

# add_header appends, so these locations answered with the Content-Type nginx had
# already set plus the one they added.
@test "[$TEST_FILE] Responses carry a single Content-Type" {
  [ "${BATS_VARIANT}" = "nginx" ] || skip "the /healthcheck endpoint is nginx-only"

  run bash -c "curl --silent --head --max-time 20 http://127.0.0.1:${BATS_MONITORING_PORT}/healthcheck | grep -ci '^content-type'"
  assert_output "1"
}

# location ~ \.php$ could not match /index.php/fr/blog, so a front controller
# never received PATH_INFO and the parameters set for it were dead code. apache
# has always handled this, which left the two variants routing differently.
@test "[$TEST_FILE] A front controller receives PATH_INFO" {
  web_put "${BATS_WEB_CONTAINER}" front.php \
    <<<'<?php echo "path_info=[", $_SERVER["PATH_INFO"] ?? "", "]";'

  run curl --silent --max-time 20 "http://127.0.0.1:${BATS_WEB_PORT}/front.php/fr/blog"
  assert_output "path_info=[/fr/blog]"
}

# The other half of accepting path info: a request whose .php does not exist must
# not fall back to executing the file before it.
@test "[$TEST_FILE] A path-info request cannot execute a non-PHP file" {
  web_put "${BATS_WEB_CONTAINER}" uploads/photo.jpg <<<'<?php echo "EXECUTED"; ?>'

  run web_status "${BATS_WEB_PORT}" /uploads/photo.jpg/shell.php
  assert_output "404"
}

# The marker said whether the hooks had run, not whether they were running, so
# replicas sharing the volume it lives on all read it at once, all decided the
# hooks were pending, and all ran them. A migration hook ran once per replica.
#
# Only /app/var/lock and /app/var/log are shared here, which is the realistic
# scope: sharing /app/var whole makes the two supervisords fight over one RPC
# socket and the second container never reaches its init scripts.
@test "[$TEST_FILE] Replicas sharing the init marker run the hooks once" {
  local -r hook="${BATS_TEST_TMPDIR}/10-slow.sh"
  local -r lock="${BATS_WEB_CONTAINER}-lock"
  local -r logs="${BATS_WEB_CONTAINER}-log"
  local -r image="$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"
  local n

  printf '#!/bin/bash\necho "ran" >> /app/var/log/hook-runs.txt\nsleep 3\n' >"${hook}"
  chmod +x "${hook}"

  for n in 1 2; do
    ${BATS_CONTAINER_ENGINE} volume create "${lock}" >/dev/null
    ${BATS_CONTAINER_ENGINE} volume create "${logs}" >/dev/null
    ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${BATS_WEB_CONTAINER}-init${n}" \
      --volume "${lock}:/app/var/lock" --volume "${logs}:/app/var/log" \
      --volume "${hook}:/opt/bin/container-entrypoint.d/10-slow.sh:ro" "${image}" >/dev/null &
  done
  wait

  container_wait_for_healthy "${BATS_WEB_CONTAINER}-init1" 60 >/dev/null
  container_wait_for_healthy "${BATS_WEB_CONTAINER}-init2" 60 >/dev/null

  run ${BATS_CONTAINER_ENGINE} exec "${BATS_WEB_CONTAINER}-init1" \
    sh -c 'grep -c ran /app/var/log/hook-runs.txt'
  assert_output "1"
}

# /opt/etc holds the rendered configuration, and PHP_INI_SCAN_DIR points at it,
# so the entrypoint read its own previous output back as input. Where the volume
# outlives the container, the extension_dir probe resolved to the symlink farm
# the entrypoint itself builds, every extension symlink was recreated pointing
# at itself, and PHP loaded none of them -- a "Symbolic link loop" per module on
# stderr, with the container still starting and serving. An override taken out
# of the environment kept applying from the same stale render.
@test "[$TEST_FILE] A reused /opt/etc does not poison the PHP configuration" {
  local -r etc="${BATS_WEB_CONTAINER}-etc"
  local -r image="$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"

  ${BATS_CONTAINER_ENGINE} volume create "${etc}" >/dev/null
  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${BATS_WEB_CONTAINER}-etc1" \
    --volume "${etc}:/opt/etc" --env PHP_MEMORY_LIMIT=512M "${image}" >/dev/null
  container_wait_for_healthy "${BATS_WEB_CONTAINER}-etc1" 60 >/dev/null
  ${BATS_CONTAINER_ENGINE} rm -f "${BATS_WEB_CONTAINER}-etc1" >/dev/null

  # Same volume, no override: the second boot has to render from the image
  # defaults rather than from what the first boot left behind.
  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${BATS_WEB_CONTAINER}-etc2" \
    --volume "${etc}:/opt/etc" "${image}" >/dev/null
  container_wait_for_healthy "${BATS_WEB_CONTAINER}-etc2" 60 >/dev/null

  run ${BATS_CONTAINER_ENGINE} exec "${BATS_WEB_CONTAINER}-etc2" \
    php -r 'echo ini_get("memory_limit"), " apcu=", (int) extension_loaded("apcu");'
  assert_line "128M apcu=1"
}

# The wrapper that points the CLI at its rendered configuration is baked into
# the image, not written to a runtime path: it has to shadow /usr/bin/aws in
# every variant, including cli, which mounts no /opt/sbin at all. It used to
# live in /opt/sbin, where a noexec mount made execve fail with EACCES while the
# shell quietly carried on with its PATH search and ran /usr/bin/aws
# unconfigured. That mount is now refused outright at startup -- see "A noexec
# /opt/sbin is refused at startup" -- so what is asserted here is the property
# that made the move worthwhile: the wrapper is image content, and it is the one
# that runs.
@test "[$TEST_FILE] The AWS wrapper is image content, not a rendered file" {
  local -r image="$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"

  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm --read-only \
    --tmpfs /opt/etc --tmpfs /opt/sbin:rw,exec --tmpfs /app/var --tmpfs /app/tmp \
    --entrypoint sh "${image}" -c \
    '/usr/local/bin/container-entrypoint true >/dev/null 2>&1; command -v aws; aws configure list'
  assert_line "/usr/local/bin/aws"
  assert_line --regexp "^ *region *: us-east-1 *: config-file *: /opt/etc/aws/config *$"
}

# The image used to declare VOLUME for its four runtime paths. A VOLUME is
# inherited and cannot be removed by a child image, and anything a child writes
# to such a path during its build is silently discarded -- a cache warmup under
# /app/var would lose its files without an error.
@test "[$TEST_FILE] The image declares no VOLUME" {
  run ${BATS_CONTAINER_ENGINE} image inspect \
    --format '{{if .Config.Volumes}}{{range $k,$_ := .Config.Volumes}}{{$k}} {{end}}{{else}}none{{end}}' \
    "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"
  assert_output "none"
}

# Without the declarations a read-only container gets no anonymous volume, so an
# unusable path has to be reported at startup rather than surfacing halfway
# through the boot as a confusing render failure.
@test "[$TEST_FILE] A read-only container without mounts refuses to start" {
  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm --read-only \
    "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"
  assert_failure
  assert_output --partial "/opt/etc is not writable"
  assert_output --partial "--tmpfs /opt/etc"
}

@test "[$TEST_FILE] A read-only container with the documented mounts is healthy" {
  local -r name="${BATS_WEB_CONTAINER}-ro"

  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${name}" --read-only \
    --tmpfs /opt/etc --tmpfs /opt/sbin:rw,exec --tmpfs /app/var --tmpfs /app/tmp \
    "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")" >/dev/null
  container_wait_for_healthy "${name}" 60 >/dev/null

  run ${BATS_CONTAINER_ENGINE} inspect -f '{{.State.Health.Status}}' "${name}"
  assert_output "healthy"
}

# /opt/sbin holds rendered scripts. A noexec mount reports nothing on its own:
# execve returns EACCES and the shell quietly moves on to the next PATH entry,
# which is how log rotation would stop without a single error line.
@test "[$TEST_FILE] A noexec /opt/sbin is refused at startup" {
  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm --read-only \
    --tmpfs /opt/etc --tmpfs /opt/sbin:rw,noexec --tmpfs /app/var --tmpfs /app/tmp \
    "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"
  assert_failure
  assert_output --partial "/opt/sbin is mounted noexec"
}

# /opt/config/sbin is the extension point: a mounted template is rendered with
# the resolved environment and made executable, the same way the image renders
# its own supervised scripts.
@test "[$TEST_FILE] A template mounted in /opt/config/sbin becomes an executable" {
  local -r tmpl="${BATS_TEST_TMPDIR}/my-job.sh.tmpl"

  printf '#!/bin/sh\necho region={{ .Env.AWS_DEFAULT_REGION }}\n' >"${tmpl}"

  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm \
    --volume "${tmpl}:/opt/config/sbin/my-job.sh.tmpl:ro" \
    --entrypoint sh "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")" -c \
    '/usr/local/bin/container-entrypoint true >/dev/null 2>&1; /opt/sbin/my-job.sh'
  assert_output "region=us-east-1"
}

# The image shipped everything under /opt and /app world-writable, files
# included -- every configuration template and every hook. The runtime user is
# 1001:0 and an arbitrary uid still lands in group 0, so group write is enough.
@test "[$TEST_FILE] Nothing under /opt or /app is world-writable" {
  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm --entrypoint sh \
    "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")" -c \
    'find /opt /app -perm -o+w 2>/dev/null | wc -l'
  assert_output "0"
}

# The common case, and the one the VOLUME declarations used to serve: a plain
# docker run. Nothing has to be mounted -- the writes land in the container
# layer. Against an image that still declares the volumes, /opt/etc shows up in
# /proc/mounts as the anonymous volume backing it, which is what this asserts is
# gone.
@test "[$TEST_FILE] A container without --read-only and without mounts is healthy" {
  local -r name="${BATS_WEB_CONTAINER}-plain"
  local -r image="$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"

  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${name}" "${image}" >/dev/null
  container_wait_for_healthy "${name}" 60 >/dev/null

  run ${BATS_CONTAINER_ENGINE} exec "${name}" sh -c \
    'echo "separate_mounts=$(grep -c " /opt/etc " /proc/mounts)"; test -f /opt/etc/php/conf.d/base-php-core.ini && echo rendered'
  assert_line "separate_mounts=0"
  assert_line "rendered"
}

# Mounts without --read-only: what a compose file that wants the runtime state
# on a tmpfs or a named volume looks like, short of a fully hardened container.
# The rendered configuration has to land in the mount, not in the layer beneath.
@test "[$TEST_FILE] A container without --read-only but with mounts is healthy" {
  local -r name="${BATS_WEB_CONTAINER}-mounts"
  local -r image="$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"

  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${name}" \
    --tmpfs /opt/etc --tmpfs /opt/sbin:rw,exec --tmpfs /app/var --tmpfs /app/tmp \
    "${image}" >/dev/null
  container_wait_for_healthy "${name}" 60 >/dev/null

  run ${BATS_CONTAINER_ENGINE} exec "${name}" sh -c \
    'echo "type=$(grep " /opt/etc " /proc/mounts | cut -d" " -f3)"; test -f /opt/etc/php/conf.d/base-php-core.ini && echo rendered'
  assert_line "type=tmpfs"
  assert_line "rendered"
}

# Late hooks used to be sourced into the entrypoint's own shell. Ending a script
# with `exit 0` is a common habit, and it terminated the entrypoint before it
# could exec supervisord: the container stopped with exit code 0, so nothing
# reported an error and restart-on-failure never fired.
@test "[$TEST_FILE] A hook ending in exit 0 does not stop the container" {
  local -r name="${BATS_WEB_CONTAINER}-hook0"
  local -r hook="${BATS_TEST_TMPDIR}/10-exit0.sh"

  printf '#!/bin/bash\necho "hook: doing my init"\nexit 0\n' >"${hook}"

  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${name}" \
    --volume "${hook}:/opt/bin/container-entrypoint.d/10-exit0.sh:ro" \
    "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")" >/dev/null
  container_wait_for_healthy "${name}" 60 >/dev/null

  run ${BATS_CONTAINER_ENGINE} logs "${name}"
  assert_output --partial "hook: doing my init"
  assert_output --partial "10-exit0.sh done"
}

# A hook that fails still stops the boot -- that has not changed, and should not:
# a failed migration must not lead to a serving container. What changed is that
# the log now says which hook it was and what it returned.
@test "[$TEST_FILE] A failing hook stops the boot and is named" {
  local -r hook="${BATS_TEST_TMPDIR}/10-fail.sh"

  printf '#!/bin/bash\necho "hook: about to fail"\nexit 3\n' >"${hook}"

  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm \
    --volume "${hook}:/opt/bin/container-entrypoint.d/10-fail.sh:ro" \
    "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"
  assert_failure
  assert_output --partial "10-fail.sh exited with 3"
}

# Sourcing put the hooks in this script's variable scope, so a hook assigning
# APP_INIT_LOCK sent the run-once fingerprint somewhere else and left the real
# marker unwritten -- which silently re-ran every hook on every start.
@test "[$TEST_FILE] A hook cannot redirect the run-once marker" {
  local -r name="${BATS_WEB_CONTAINER}-hooklock"
  local -r hook="${BATS_TEST_TMPDIR}/10-clobber.sh"

  printf '#!/bin/bash\nAPP_INIT_LOCK=/tmp/hijacked\necho "hook ran"\n' >"${hook}"

  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${name}" \
    --volume "${hook}:/opt/bin/container-entrypoint.d/10-clobber.sh:ro" \
    "$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")" >/dev/null
  container_wait_for_healthy "${name}" 60 >/dev/null

  ${BATS_CONTAINER_ENGINE} restart "${name}" >/dev/null
  container_wait_for_healthy "${name}" 60 >/dev/null

  # The marker survived, so the second boot skipped the hook.
  run ${BATS_CONTAINER_ENGINE} exec "${name}" sh -c \
    'test -s /app/var/lock/appinit && echo marker-written'
  assert_output "marker-written"

  run ${BATS_CONTAINER_ENGINE} logs "${name}"
  assert_equal "$(grep -c 'hook ran' <<<"${output}")" "1"
}

# Hooks are child processes, so what they set stays with them. This pins the
# contract: the place to put a variable in the application's environment is an
# early hook, which is sourced.
@test "[$TEST_FILE] A variable exported by a late hook does not reach the application" {
  local -r name="${BATS_WEB_CONTAINER}-hookenv"
  local -r hook="${BATS_TEST_TMPDIR}/10-export.sh"
  local port

  printf '#!/bin/bash\nexport HOOK_INJECTED=yes\n' >"${hook}"

  port="$(web_container_start "${name}" \
    --volume "${hook}:/opt/bin/container-entrypoint.d/10-export.sh:ro")"

  run web_php "${name}" "${port}" '<?php echo getenv("HOOK_INJECTED") ?: "(absent)";'
  assert_line "(absent)"
}

# The endpoints used to live in the application vhost, on the port a Route or a
# Service publishes. MONITORING_ALLOW could not protect them there: behind a
# router the address the server sees is the router's, which is private and so
# matches the list -- every request from the internet did too. Measured on
# 8.5.9-apache from outside the container: /server-status, /status and
# /real-time-status all answered 200.
@test "[$TEST_FILE] The application port serves no monitoring endpoint" {
  local endpoint

  for endpoint in /server-status /status /real-time-status; do
    run web_status "${BATS_WEB_PORT}" "${endpoint}"
    assert_line "404"
  done
}

# Both listen ports are knobs now. A port knob that reached no template would
# behave exactly like the default and go unnoticed, which is how six inert knobs
# survived in this image until they were measured -- so this asserts the new
# port answers and the default one no longer does.
@test "[$TEST_FILE] The monitoring listen port is configurable" {
  local -r name="${BATS_WEB_CONTAINER}-port"
  local -r image="$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"
  local var port

  case "${BATS_VARIANT}" in
    nginx)  var=NGINX_MONITORING_LISTEN ;;
    apache) var=APACHE_MONITORING_LISTEN ;;
    *)      skip "no monitoring port on the ${BATS_VARIANT} variant" ;;
  esac

  ${BATS_CONTAINER_ENGINE} run --pull=never --detach --name "${name}" \
    --publish 127.0.0.1::8090 --publish 127.0.0.1::9090 \
    --env "${var}=8090" "${image}" >/dev/null
  container_wait_for_healthy "${name}" 60 >/dev/null

  port="$(${BATS_CONTAINER_ENGINE} port "${name}" 8090/tcp | head -1 | sed 's/.*://')"
  run web_status "${port}" /status
  assert_line "200"

  # Nothing is listening on the default any more, so the connection fails and
  # curl reports 000 rather than a status code.
  port="$(${BATS_CONTAINER_ENGINE} port "${name}" 9090/tcp | head -1 | sed 's/.*://')"
  run web_status "${port}" /status
  refute_line "200"
}

# Behind a proxy the address apache reports is the proxy's, so the access log,
# Require ip and REMOTE_ADDR all named the router rather than the client. nginx
# has resolved this since it gained NGINX_REAL_IP_*; apache had no equivalent.
# Off by default on both, so this asserts the capability, not a new default.
@test "[$TEST_FILE] The client address is resolved from a configurable header" {
  [ "${BATS_VARIANT}" = "apache" ] || skip "the nginx variant resolves it through NGINX_REAL_IP_*"

  local -r name="${BATS_WEB_CONTAINER}-remoteip"
  local -r image="$(image_tag "${BATS_VARIANT}" "${BATS_TARGET}")"
  local port

  # A name of an organisation's own, to prove the header is not hard-coded.
  port="$(web_container_start "${name}" \
    --env APACHE_REMOTE_IP_ENABLED=true \
    --env APACHE_REMOTE_IP_HEADER_NAME=X-Corp-Client-IP)"

  curl --silent --output /dev/null --max-time 20 \
    --header "X-Corp-Client-IP: 203.0.113.42" "http://127.0.0.1:${port}/"
  # Only the configured header is read, so a forged standard one changes nothing.
  curl --silent --output /dev/null --max-time 20 \
    --header "X-Forwarded-For: 198.51.100.7" "http://127.0.0.1:${port}/"

  run ${BATS_CONTAINER_ENGINE} logs "${name}"
  assert_output --partial "203.0.113.42"
  refute_output --partial "198.51.100.7"
}

# The slowlog default was php-fpm.log.slow, which the /app/var/log/*.log glob
# does not match: logrotate never considered it, so a deployment that turned the
# slowlog on grew one unbounded file on the very volume every other log was being
# rotated on. Measured on 8.5.9: 60 MB untouched while app.log rotated.
@test "[$TEST_FILE] The php-fpm slowlog is covered by the rotation glob" {
  local -r name="${BATS_WEB_CONTAINER}-slowlog"

  web_container_start "${name}" --env PHP_FPM_REQUEST_SLOWLOG_TIMEOUT=1s >/dev/null

  run ${BATS_CONTAINER_ENGINE} exec "${name}" sh -c \
    ': > "$(sed -n "s/^slowlog *= *//p" /opt/etc/php/php-fpm.d/base-php.conf)"
     logrotate --debug --state /tmp/rotate-probe /opt/etc/logrotate.conf 2>&1'
  assert_output --partial "considering log /app/var/log/php-fpm-slow.log"
}

# logrotate.conf is an `include /opt/etc/logrotate.d`, so a second stanza was
# always possible in principle -- but nothing rendered one, and the README
# described a flexibility that did not exist.
@test "[$TEST_FILE] A logrotate template mounted by the operator is rendered" {
  local -r name="${BATS_WEB_CONTAINER}-stanza"
  local -r tmpl="${BATS_TEST_TMPDIR}/myapp.conf.tmpl"

  # Uses the options datasource, to prove a stanza can reuse the shared policy.
  cat >"${tmpl}" <<'TMPL'
/app/var/log/myapp/*.log {
    size 10M
    rotate 3
{{- range (datasource "options") }}
    {{ . }}
{{- end }}
}
TMPL

  web_container_start "${name}" \
    --volume "${tmpl}:/opt/config/logrotate/logrotate.d/myapp.conf.tmpl:ro" >/dev/null

  run ${BATS_CONTAINER_ENGINE} exec "${name}" sh -c \
    'mkdir -p /app/var/log/myapp && : > /app/var/log/myapp/x.log
     grep -q compress /opt/etc/logrotate.d/myapp.conf && echo options-applied
     logrotate --debug --state /tmp/rotate-probe /opt/etc/logrotate.conf 2>&1'
  assert_output --partial "options-applied"
  assert_output --partial "considering log /app/var/log/myapp/x.log"
}
