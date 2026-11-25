#!/usr/bin/env bats
#
# .github/release-prepare.sh, the one copy every image repository shares, run on
# throwaway Git repositories. No image and no network: `make tooling-check`.

export BATS_LIB_PATH="${BATS_LIB_PATH:+${BATS_LIB_PATH}:}${BATS_TEST_DIRNAME%/}/lib"
bats_load_library bats-support
bats_load_library bats-assert

SCRIPT="${BATS_TEST_DIRNAME%/}/../.github/release-prepare.sh"

# A repository with the script, a CHANGELOG and a first tag; the commands that
# follow run inside it.
setup() {
  export LINT=0
  repo="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${repo}/.github"
  cp "${SCRIPT}" "${repo}/.github/release-prepare.sh"
  cd "${repo}"
  git init -q -b main
  git config user.name test
  git config user.email test@localhost
  git config commit.gpgsign false
  git config tag.gpgsign false
  printf '# Changelog\n\n## [Unreleased]\n\n## [1.0.0]\n\nFirst.\n' >CHANGELOG.md
  git add -A
  git commit -qm "chore: initial"
  git tag 1.0.0
}

# A squash merge: the title and its (#N) in the subject.
squash() {
  git commit -q --allow-empty -m "$1"
}

# A merge commit as GitHub writes it with "PR title" as the message.
merge_pr() {
  local -r number=$1 title=$2
  git switch -q -c "pr-${number}"
  git commit -q --allow-empty -m "work on ${number}"
  git switch -q -
  git merge -q --no-ff "pr-${number}" -m "Merge pull request #${number} from org/pr-${number}" -m "${title}"
}

unreleased() {
  section Unreleased
}

# The body of the CHANGELOG section of version $1.
section() {
  awk -v head="## [$1]" 'index($0, head) == 1 { on = 1; next } on && /^## \[/ { exit } on' CHANGELOG.md
}

@test "squash and merge commits are both recorded, by type" {
  squash "feat(nginx): a new knob (#1)"
  merge_pr 2 "fix: a crash at boot"
  squash "docs: a typo (#3)"

  run bash .github/release-prepare.sh 1.1.0
  assert_success
  run section 1.1.0
  assert_line '- `nginx`: a new knob (#1).'
  assert_line '- a crash at boot (#2).'
  assert_line '### Added'
  assert_line '### Fixed'
  refute_output --partial 'a typo'
}

@test "a commit it cannot classify is reported, not dropped in silence" {
  squash "fix: recorded (#1)"
  git commit -q --allow-empty -m "Fix the thing directly on main"

  run bash .github/release-prepare.sh 1.0.1
  assert_success
  assert_line --regexp '^not recorded: [0-9a-f]{7} Fix the thing directly on main$'
}

@test "the release commits of the tooling are neither recorded nor reported" {
  squash "fix: recorded (#1)"
  git commit -q --allow-empty -m "chore: prepare release 1.0.1"
  git commit -q --allow-empty -m "chore: re-publish 1.0.1"

  run bash .github/release-prepare.sh 1.0.2
  assert_success
  refute_output --partial 'not recorded'
}

@test "chore(deps) titles are kept without a changelog-deps.sh" {
  squash "chore(deps): update restic to v0.20.0 (#5)"

  run bash .github/release-prepare.sh 1.0.1
  assert_success
  run unreleased
  refute_output --partial 'restic'
  run section 1.0.1
  assert_line '### Changed'
  assert_line '- update restic to v0.20.0 (#5).'
}

@test "chore(deps) titles are left to changelog-deps.sh when there is one" {
  printf '#!/bin/sh\nexit 0\n' >.github/changelog-deps.sh
  git add -A && git commit -qm "chore: deps script"
  squash "chore(deps): update restic to v0.20.0 (#5)"
  squash "fix: something (#6)"

  run bash .github/release-prepare.sh 1.0.1
  assert_success
  refute_output --partial 'restic to v0.20.0 (#5).'
  run grep -c 'restic' CHANGELOG.md
  assert_output "0"
}

@test "two major lines: the previous tag is the one of the same line" {
  git switch -q -c six
  squash "fix: six only (#10)"
  git tag 6.1.0+260101
  squash "fix: after six one (#11)"
  git switch -q main
  squash "feat: seven (#20)"
  git tag 7.1.0+260101
  squash "fix: after seven one (#21)"

  run bash .github/release-prepare.sh 7.2.0+260201
  assert_success
  assert_line 'changes since 7.1.0+260101'

  git checkout -q CHANGELOG.md
  git switch -q six
  run bash .github/release-prepare.sh 6.1.1+260201
  assert_success
  assert_line 'changes since 6.1.0+260101'
  run section 6.1.1+260201
  assert_line '- after six one (#11).'
}

@test "the first release of a new major line starts from the nearest tag" {
  squash "feat: big change (#30)"

  run bash .github/release-prepare.sh 2.0.0
  assert_success
  assert_line 'changes since 1.0.0'
}

@test "a re-publication goes under the existing version, once a day" {
  squash "fix: a late fix (#40)"

  run bash .github/release-prepare.sh 1.0.0 --retag
  assert_success
  run section 1.0.0
  assert_line --regexp '^### Re-published on [0-9]{4}-[0-9]{2}-[0-9]{2}$'
  assert_line '- a late fix (#40).'

  run bash .github/release-prepare.sh 1.0.0 --retag
  assert_failure
  assert_output --partial "already has today's re-publication"
}

@test "an existing tag or section is refused for a new version" {
  run bash .github/release-prepare.sh 1.0.0
  assert_failure
  assert_output --partial 'tag 1.0.0 exists: use --retag'
}

@test "chore(deps) titles are kept with a changelog-deps.sh when told to" {
  printf '#!/bin/sh\nexit 0\n' >.github/changelog-deps.sh
  git add -A && git commit -qm "chore: deps script"
  squash "chore(deps): update dependency boto3 to v1.35.0 (#7)"

  CHANGELOG_DEPS_TITLES=keep run bash .github/release-prepare.sh 1.0.1
  assert_success
  run section 1.0.1
  assert_line '- update dependency boto3 to v1.35.0 (#7).'
}

@test "a version pinned in docker-bake.hcl only is a dependency line, named as told" {
  cp "${BATS_TEST_DIRNAME%/}/../.github/changelog-deps.sh" .github/
  printf 'FROM scratch\nARG RESTIC_VERSION_ARG=""\n' >Dockerfile
  printf 'variable "RESTIC_VERSION" {\n  default = "0.19.1"\n}\nvariable "DOCKER_IMAGE_VERSION" {\n  default = "snapshot"\n}\n' >docker-bake.hcl
  git add -A && git commit -qm "chore: pins" && git tag -f 1.0.0 >/dev/null
  sed -i 's/0.19.1/0.20.0/' docker-bake.hcl
  git commit -qam "chore(deps): update restic to v0.20.0 (#8)"

  CHANGELOG_DEP_NAMES="RESTIC_VERSION_ARG=restic" run bash .github/release-prepare.sh 1.0.1
  assert_success
  run section 1.0.1
  assert_line '- **`restic` 0.20.0**, up from 0.19.1 (dependency update).'
  refute_output --partial 'snapshot'
  refute_output --partial 'update restic to v0.20.0 (#8)'
}
