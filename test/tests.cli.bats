#!/usr/bin/env bats
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
export BATS_CONTAINER_COMPOSE_ENGINE="${BATS_CONTAINER_ENGINE} compose"

# The variant is fixed, the target follows the build under test: a build job
# produces one image, and only cli-dev carries the GitHub CLI.
BATS_TARGET="${BATS_TARGET:-prd}"
BATS_CLI_IMAGE="$(image_tag cli "${BATS_TARGET}")"

# --pull=never keeps a missing local image an error instead of a silent pull of
# the published one, which would test an image this build never produced.
run_cli() {
  run ${BATS_CONTAINER_ENGINE} run --pull=never --read-only --rm \
    -v php_cli_app_tmp:/app/tmp \
    -v php_cli_opt_etc:/opt/etc \
    "$@"
}

setup_file() {
  command ${BATS_CONTAINER_ENGINE} volume create php_cli_app_tmp
  command ${BATS_CONTAINER_ENGINE} volume create php_cli_opt_etc
}

teardown_file() {
  command ${BATS_CONTAINER_ENGINE} volume rm -f php_cli_app_tmp php_cli_opt_etc
}

@test "[$TEST_FILE] Test PHP version" {
  run_cli "${BATS_CLI_IMAGE}" -v
  assert_line --regexp "^PHP ${BATS_PHP_VERSION} \(cli\) \(.*\) \(NTS\)"
}

@test "[$TEST_FILE] Testing NPM Version (with unrecognized uid and anonymous volumes)" {
  run ${BATS_CONTAINER_ENGINE} run --pull=never -u 1000 --read-only --rm \
    -v /app/tmp \
    -v /opt/etc \
    "${BATS_CLI_IMAGE}" npm -v
  assert_line --regexp "^[0-9]+.[0-9]+.[0-9]+*$"
}

# The test above passes a bare uid, which Docker completes with gid 0 -- so the
# group bit of a 775 runtime directory carries it. A build invoked the way the
# demo Makefiles do it, `--user $(id -u):$(id -g)` so that its output belongs to
# the person who started it, lands in its own gid instead and was locked out.
# That is the form asserted here.
@test "[$TEST_FILE] The runtime paths accept an arbitrary uid:gid" {
  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm -u 4242:4242 \
    "${BATS_CLI_IMAGE}" php -r 'echo "started";'
  assert_success
  assert_line "started"
}

@test "[$TEST_FILE] Test aws cli version" {
  run_cli "${BATS_CLI_IMAGE}" aws --version
  assert_line --regexp "^aws-cli/${BATS_AWS_CLI_VERSION} Python/.* .*$"
}

@test "[$TEST_FILE] Test GH cli version (dev only)" {
  [ "${BATS_TARGET}" = "dev" ] || skip "the GitHub CLI ships in cli-dev only"

  run_cli "${BATS_CLI_IMAGE}" gh --version
  assert_line --regexp "^gh version [0-9]+\.[0-9]+\.[0-9]+ \([^)]+\)$"
}

# The cli variant sourced no AWS script at all: no rendered configuration, no
# wrapper -- and, because nothing registered the variables for cleanup, the raw
# AWS_* reached the process. That is the opposite of what the web variants do,
# in the variant most likely to actually run `aws`.
@test "[$TEST_FILE] The cli variant renders the AWS configuration" {
  run_cli "${BATS_CLI_IMAGE}" sh -c 'command -v aws; ls /opt/etc/aws'
  assert_line "/usr/local/bin/aws"
  assert_line "config"
  assert_line "wrapper.env"
}

# The policy this image applies on purpose: the CLI is configured through files,
# so no AWS credential is left in the environment the application runs in.
@test "[$TEST_FILE] AWS credentials never reach the application environment" {
  run_cli \
    -e AWS_ACCESS_KEY_ID=AKIAEXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=secret \
    -e AWS_SESSION_TOKEN=FwoGZXIvEXAMPLE \
    "${BATS_CLI_IMAGE}" \
    sh -c 'echo "id=${AWS_ACCESS_KEY_ID:-unset} secret=${AWS_SECRET_ACCESS_KEY:-unset} token=${AWS_SESSION_TOKEN:-unset}"'
  assert_line "id=unset secret=unset token=unset"
}

# Temporary credentials (STS, assume-role) are rejected without their session
# token, and the credentials template rendered only the two long-term keys.
@test "[$TEST_FILE] Temporary credentials are rendered with their session token" {
  run_cli \
    -e AWS_ACCESS_KEY_ID=ASIAEXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=secret \
    -e AWS_SESSION_TOKEN=FwoGZXIvEXAMPLE \
    "${BATS_CLI_IMAGE}" sh -c 'cat /opt/etc/aws/credentials'
  assert_line "aws_session_token=FwoGZXIvEXAMPLE"
}

# Both templates used to hard-code [default], so a named profile produced files
# the CLI could not find. The config file prefixes every non-default profile
# with "profile", the credentials file never does.
@test "[$TEST_FILE] A named AWS profile is honoured" {
  run_cli \
    -e AWS_PROFILE=ci \
    -e AWS_ACCESS_KEY_ID=AKIAEXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=secret \
    "${BATS_CLI_IMAGE}" sh -c 'cat /opt/etc/aws/config /opt/etc/aws/credentials'
  assert_line "[profile ci]"
  assert_line "[ci]"
}

# The list of ini directives the image can be asked about is derived from PHP at
# build time rather than written by hand, so the only thing left to watch is
# drift: a PHP release that adds or removes a directive must be seen, not
# absorbed in silence. The fixture is that witness -- `make ini-directives`
# regenerates it, and the diff of the pull request names what moved.
#
# It is version-specific, like the php.ini files: a backport regenerates it
# instead of cherry-picking it.
@test "[$TEST_FILE] The shipped ini directive list matches the fixture" {
  local -r fixture="${BATS_TEST_DIRNAME}/fixtures/ini-directives.list"
  local -r shipped="${BATS_TEST_TMPDIR}/ini-directives.list"

  ${BATS_CONTAINER_ENGINE} run --pull=never --rm --entrypoint cat "${BATS_CLI_IMAGE}" \
    /usr/local/share/base-php/ini-directives.list >"${shipped}"

  run diff --unified=0 "${fixture}" "${shipped}"
  assert_success
}

# The banner is drawn with runs of spaces, and a web console that renders its
# logs into HTML collapses every run to a single space: the art arrived as a
# line of debris. Measured on the production OpenShift console -- the QA one
# does not collapse, which is why this went unnoticed for so long.
#
# Every run is now broken up with a no-break space, which no renderer collapses.
# The assertion is the property itself, testable without a console: no two
# consecutive ASCII spaces anywhere in the banner.
@test "[$TEST_FILE] The startup banner survives a space-collapsing log viewer" {
  local banner

  banner="$(${BATS_CONTAINER_ENGINE} run --pull=never --rm "${BATS_CLI_IMAGE}" true 2>&1 |
    sed -e 's/\x1b\[[0-9;]*m//g' -e '/Configure PHP Container/,$d')"

  run grep -c '  ' <<<"${banner}"
  assert_output "0"
}

# The counterpart of the assertion above, and the reason the fill character is a
# no-break space rather than a zero-width one: the substitution fires on runs of
# two spaces and never on a single one, so the words keep ordinary ASCII spaces
# between them and the line stays greppable in a log file. A zero-width space
# would have survived the console too -- and silently broken this.
@test "[$TEST_FILE] The banner text is still greppable with ordinary spaces" {
  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm "${BATS_CLI_IMAGE}" true
  assert_output --partial "Smals WebAgency WcmTech Base Image"
}

# print-banner reads /opt/config/motd, which is a mount point like everything
# else under /opt/config. An empty file is how an operator turns the banner off:
# it must print nothing and must not fail the boot, since it runs under `set -e`.
@test "[$TEST_FILE] An empty banner file prints nothing and does not stop the boot" {
  local -r empty="${BATS_TEST_TMPDIR}/motd"

  : >"${empty}"

  run ${BATS_CONTAINER_ENGINE} run --pull=never --rm \
    --volume "${empty}:/opt/config/motd:ro" \
    "${BATS_CLI_IMAGE}" php -r 'echo "started";'
  assert_success
  assert_output --partial "started"
  refute_output --partial "Smals WebAgency"
}
