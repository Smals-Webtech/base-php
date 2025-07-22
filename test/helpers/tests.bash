# Test if requirements are met
(
	type ${BATS_CONTAINER_ENGINE} &>/dev/null || ( echo "${BATS_CONTAINER_ENGINE} is not available"; exit 1 )
    type ${BATS_CONTAINER_COMPOSE_ENGINE} &>/dev/null || ( echo "${BATS_CONTAINER_COMPOSE_ENGINE} is not available"; exit 1 )
)>&2

TEST_FILE=$(basename $BATS_TEST_FILENAME .bats)

# stop all containers with the "bats-type" label (matching the optionally supplied value)
#
# $1 optional label value
function stop_bats_containers {
	run ${BATS_CONTAINER_COMPOSE_ENGINE} stop $1
}

# delete all containers
docker_cleanup() {
	run ${BATS_CONTAINER_COMPOSE_ENGINE} down -v
}

# Send a HTTP request to container $1 for path $2 and
# Additional curl options can be passed as $@
#
# $1 container name
# $2 HTTP path to query
# $@ additional options to pass to the curl command
function curl_container {
  local -r curl_image_name="docker.io/curlimages/curl:8.11.1"

  local -r container=$1
  local -r path=$2
  shift 2
  ${BATS_CONTAINER_ENGINE} run --rm --net=${BATS_CONTAINER_NETWORK_NAME} --label bats-type="curl" ${curl_image_name} --silent \
    --connect-timeout 5 \
    --max-time 20 \
    --retry 4 --retry-delay 5 \
    "$@" \
    http://$(container_ip $container)${path}
}

# Retry a command $1 times until it succeeds. Wait $2 seconds between retries.
function retry {
    local attempts=$1
    shift
    local delay=$1
    shift
    local i

    for ((i=0; i < attempts; i++)); do
        run "$@"
        if [ "$status" -eq 0 ]; then
            echo "$output"
            return 0
        fi
        sleep $delay
    done

    echo "Command \"$@\" failed $attempts times. Status: $status. Output: $output" >&2
    false
}