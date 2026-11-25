## functions to help deal with containers (podman or docker)

# Resolve the image tag bake produces for a variant/target pair.
#
# The suite must exercise the image the current build produced, not whatever
# floating tag happens to sit in the local daemon: `base-php:cli` is the bake
# "latest" tag, so a build of another branch leaves it pointing at a different
# PHP version, and an absent tag makes `docker run` pull the published image
# instead -- the suite then passes against something that was never built here.
#
# DOCKER_IMAGE_NAME and DOCKER_IMAGE_VERSION default to bake's own defaults, so
# a plain `make bake-cli/prd` followed by `bats test/tests.cli.bats` works.
#
# $1 variant (cli, fpm, nginx, apache)
# $2 target  (prd, dev) -- defaults to prd
function image_tag {
  local -r variant=$1
  local -r target=${2:-prd}
  local suffix=""

  [ "${target}" = "dev" ] && suffix="-dev"

  echo "${DOCKER_IMAGE_NAME:-smalswebtech/base-php}:${DOCKER_IMAGE_VERSION:-snapshot}-${variant}${suffix}"
}

# Docker probes a starting container at the image's start interval (5s by
# default), so a container that answers after about 3s was reported healthy
# after 5s, and most web tests wait for one. Probing every 250ms during a 30s
# start period reports it as soon as the image's own health command passes;
# after the first success the image's interval applies again. The image is not
# changed: the options apply to the containers the suites start.
if [ "${BATS_CONTAINER_ENGINE:-docker}" = "docker" ]; then
  export BATS_FAST_HEALTH="--health-start-period=30s --health-start-interval=250ms"
else
  export BATS_FAST_HEALTH=""
fi

# Removes the containers named $@ (rm -f kills a running one first).
function container_clean {
  ${BATS_CONTAINER_ENGINE} rm -vf "$@" &>/dev/null ||:
}

# Removes every container whose name starts with $1.
function container_clean_prefix {
  local ids
  ids=$(${BATS_CONTAINER_ENGINE} ps -aq --filter "name=^/?$1" 2>/dev/null)
  [ -z "${ids}" ] || ${BATS_CONTAINER_ENGINE} rm -vf ${ids} &>/dev/null ||:
}

# get the ip of container $1
function container_ip {
  CONTAINER_INSPECT_GO_TEMPLATE_FORMAT="{{(index .NetworkSettings.Networks \"${BATS_CONTAINER_NETWORK_NAME}\").IPAddress }}"
  echo $(container_inspect "${CONTAINER_INSPECT_GO_TEMPLATE_FORMAT}" $1)
}

# get the id of container $1
function container_id {
  CONTAINER_INSPECT_GO_TEMPLATE_FORMAT="{{ .ID }}"
  echo $(container_inspect "${CONTAINER_INSPECT_GO_TEMPLATE_FORMAT}" $1)
}

# get the running state of container $1
# → true/false
# fails if the container does not exist
function container_running_state {
  CONTAINER_INSPECT_GO_TEMPLATE_FORMAT="{{ .State.Running }}"
  echo $(container_inspect "${CONTAINER_INSPECT_GO_TEMPLATE_FORMAT}" $1)
}

# get the health state of container $1
# fails if the container does not exist
function container_health_state() {
  CONTAINER_INSPECT_GO_TEMPLATE_FORMAT="{{ .State.Health.Status }}"
  echo $(container_inspect "${CONTAINER_INSPECT_GO_TEMPLATE_FORMAT}" $1)
}

# get the container $1 PID
function container_pid {
  CONTAINER_INSPECT_GO_TEMPLATE_FORMAT="{{.State.Pid}}"
  echo $(container_inspect "${CONTAINER_INSPECT_GO_TEMPLATE_FORMAT}" $1)
}

function container_inspect {
  command ${BATS_CONTAINER_ENGINE} inspect --format "$1" $2
}

# asserts state from container $1 contains healthy
function container_assert_healthy {
  local -r container=$1
  shift
  # `run` is required: assert_output reads $output, which only a `run` sets.
  # Calling container_health_state directly left $output from the previous run,
  # so the assertion checked an unrelated command's output.
  run container_health_state "$container"
  assert_line "healthy"
}

# asserts logs from container $1 contains $2
function container_assert_log {
  local -r container=$1
  shift
  run ${BATS_CONTAINER_ENGINE} logs $container
  assert_output --regexp "$*"
}

# asserts command $2 output from container $1 contains $3
function container_assert_command {
  local -r container=$1
  local -r command_to_exec=$2
  shift 2
  run ${BATS_CONTAINER_ENGINE} exec $container $command_to_exec
  assert_output --regexp "$*"
}

# wait for a container to produce a given text in its log
# $1 container
# $2 timeout in second
# $* text to wait for
function container_wait_for_log {
  local -r container=$1
  local -ir timeout_sec=$2
  shift 2
  retry $(( $timeout_sec * 2 )) .5s container_assert_log $container "$*"
}

# wait for a container to produce a given text in its command output
# $1 container
# $2 timeout in second
# $* text to wait for
function container_wait_for_command {
  local -r container=$1
  local -r cmd=$2
  local -ir timeout_sec=$3
  shift 3
  retry $(( $timeout_sec * 2 )) .5s container_assert_command $container "$cmd" "$*"
}

# wait for a container healthy state
# $1 container
# $2 timeout in second
function container_wait_for_healthy {
  local -r container=$1
  local -ir timeout_sec=$2
  shift 2
  retry $(( $timeout_sec * 2 )) .5s container_assert_healthy $container
}
