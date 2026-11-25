#!/usr/bin/env bats
#
# .github/release.mk, the release targets every image repository shares, run on a throwaway
# repository: a bare repository is the remote (a hook logs every ref update), a fake gh logs
# its calls and answers as told (FAKE_GH), a fake gpg signs. No network: `make tooling-check`.

export BATS_LIB_PATH="${BATS_LIB_PATH:+${BATS_LIB_PATH}:}${BATS_TEST_DIRNAME%/}/lib"
bats_load_library bats-support
bats_load_library bats-assert

TOOLING="${BATS_TEST_DIRNAME%/}/../.github"

setup() {
  export LINT=0 YES=1 FAKE_GH=ok
  local -r bin="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "${bin}"
  export GH_LOG="${BATS_TEST_TMPDIR}/gh.log" REFS_LOG="${BATS_TEST_TMPDIR}/refs.log"
  : >"${GH_LOG}"
  : >"${REFS_LOG}"

  cat >"${bin}/gh" <<'EOF'
#!/bin/sh
echo "gh $*" >>"${GH_LOG}"
case "$*" in
  "api repos/"*"/releases/tags/"*)
    case "${FAKE_GH}" in
      404) echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
      neterr) echo "error connecting to api.github.com" >&2; exit 1 ;;
    esac
    echo 42 ;;
  "api repos/"*"/generate-notes"*) echo "## notes" ;;
  "release edit"*"--notes-file -"*) cat >/dev/null ;;
esac
exit 0
EOF
  # git reads SIG_CREATED on the status descriptor (stderr here) and the signature on stdout.
  cat >"${bin}/gpg" <<'EOF'
#!/bin/sh
[ -z "${FAKE_GPG_FAIL}" ] || { echo "gpg: signing failed" >&2; exit 2; }
cat >/dev/null
echo "[GNUPG:] SIG_CREATED D 1 8 00 $(date +%s) FAKE" >&2
printf -- '-----BEGIN PGP SIGNATURE-----\n\nfake\n-----END PGP SIGNATURE-----\n'
EOF
  chmod +x "${bin}/gh" "${bin}/gpg"
  export PATH="${bin}:${PATH}"

  remote="${BATS_TEST_TMPDIR}/remote.git"
  git init -q --bare "${remote}"
  printf '#!/bin/sh\nwhile read o n r; do echo "$o $n $r" >> "%s"; done\n' "${REFS_LOG}" >"${remote}/hooks/pre-receive"
  chmod +x "${remote}/hooks/pre-receive"

  repo="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${repo}/.github"
  cp "${TOOLING}/release.mk" "${TOOLING}/release-prepare.sh" "${TOOLING}/changelog-deps.sh" "${repo}/.github/"
  cd "${repo}"
  git init -q -b main
  git config user.name test
  git config user.email test@localhost
  git config user.signingkey FAKE
  git config gpg.program gpg
  git remote add origin "git@github.com:example/app.git"
  git config remote.origin.pushurl "${remote}"
  git config remote.origin.url "${remote}"
  printf 'RELEASE_BRANCHES = main 1.x\nVERSION_OF = APP_VERSION\nREPO = example/app\ninclude .github/release.mk\n' >Makefile
  printf 'FROM scratch\nARG APP_VERSION_ARG=1.0.0\n' >Dockerfile
  printf 'variable "APP_VERSION" {\n  default = "1.0.0"\n}\n' >docker-bake.hcl
  printf '# Changelog\n\n## [Unreleased]\n\n## [1.0.0]\n\nFirst.\n' >CHANGELOG.md
  git add -A
  git commit -q -m "chore: initial"
  git tag -s -m "Version 1.0.0" 1.0.0
  git push -q origin main refs/tags/1.0.0
  : >"${REFS_LOG}"
}

# Moves the image to version $1, through a merged pull request, and pushes it.
bump() {
  sed -i "s/^ARG APP_VERSION_ARG=.*/ARG APP_VERSION_ARG=$1/" Dockerfile
  sed -i "s/default = \".*\"/default = \"$1\"/" docker-bake.hcl
  git commit -q -am "feat: version $1 (#${2:-1})"
  git push -q origin HEAD
  : >"${REFS_LOG}"
}

@test "release: the prepared section is committed, tagged, pushed and published" {
  bump 1.1.0
  run make -s release-prepare VERSION=1.1.0
  assert_success

  run make -s release VERSION=1.1.0
  assert_success
  assert_output --partial "release 1.1.0 created"
  run git log -1 --format=%s origin/main
  assert_output "chore: prepare release 1.1.0"
  run git ls-remote origin refs/tags/1.1.0
  refute_output ""
  run cat "${GH_LOG}"
  assert_output --partial "release create 1.1.0 --repo example/app --generate-notes --latest=true --notes-start-tag 1.0.0 --verify-tag"
}

@test "release: refused without its CHANGELOG section" {
  bump 1.1.0
  run make -s release VERSION=1.1.0
  assert_failure
  assert_output --partial "no '## [1.1.0]' section in CHANGELOG.md -> 'make release-prepare VERSION=1.1.0' first"
}

@test "release: refused when VERSION is not what the image builds" {
  bump 1.1.0
  run make -s release-prepare VERSION=1.2.0
  run make -s release VERSION=1.2.0
  assert_failure
  assert_output --partial "docker-bake.hcl APP_VERSION is '1.1.0'"
}

@test "release: refused from a branch that does not release" {
  bump 1.1.0
  git switch -q -c feature
  run make -s release VERSION=1.1.0
  assert_failure
  assert_output --partial "release only from main 1.x (on feature)"
}

@test "release: refused when the branch is not the remote's" {
  bump 1.1.0
  git commit -q --allow-empty -m "fix: not pushed (#2)"
  run make -s release-prepare VERSION=1.1.0
  run make -s release VERSION=1.1.0
  assert_failure
  assert_output --partial "local main differs from origin/main"
}

@test "release: refused when the tag exists on the remote only" {
  bump 1.1.0
  run make -s release-prepare VERSION=1.1.0
  git tag -s -m x 1.1.0 && git push -q origin refs/tags/1.1.0 && git tag -d 1.1.0 >/dev/null
  run make -s release VERSION=1.1.0
  assert_failure
  assert_output --partial "tag 1.1.0 already exists on origin"
}

@test "retag: the tag moves in one push, with the re-publication's CHANGELOG" {
  git commit -q --allow-empty -m "fix: a late fix (#3)"
  git push -q origin main
  : >"${REFS_LOG}"
  run make -s release-prepare VERSION=1.0.0 RETAG=1
  assert_success

  run make -s retag VERSION=1.0.0
  assert_success
  assert_output --partial "release 1.0.0 re-published"
  run git log -1 --format=%s origin/main
  assert_output "chore: re-publish 1.0.0"
  # One update of the tag, from the old object to the new: never deleted in between.
  run grep -c 'refs/tags/1.0.0$' "${REFS_LOG}"
  assert_output "1"
  run grep -E '^0{40} |^[0-9a-f]{40} 0{40} ' "${REFS_LOG}"
  assert_failure
}

@test "retag: a failed signature changes neither tag" {
  local -r before_local=$(git rev-parse 1.0.0) before_remote=$(git ls-remote origin refs/tags/1.0.0 | cut -f1)
  FAKE_GPG_FAIL=1 run make -s retag VERSION=1.0.0
  assert_failure
  [ "$(git rev-parse 1.0.0)" = "${before_local}" ]
  [ "$(git ls-remote origin refs/tags/1.0.0 | cut -f1)" = "${before_remote}" ]
}

@test "release-refresh: no release is not an error, a network error is" {
  FAKE_GH=404 run make -s release-refresh VERSION=1.0.0
  assert_success
  assert_output --partial "no GitHub release 1.0.0 (skip refresh)"

  FAKE_GH=neterr run make -s release-refresh VERSION=1.0.0
  assert_failure
  assert_output --partial "run 'make release-refresh VERSION=1.0.0'"
}

@test "an older line: notes from its own previous tag, not marked latest" {
  git switch -q -c 1.x
  git push -q origin 1.x
  git switch -q main
  bump 2.0.0 4
  git tag -s -m v 2.0.0 && git push -q origin refs/tags/2.0.0
  git switch -q 1.x
  bump 1.0.1 5
  run make -s release-prepare VERSION=1.0.1
  assert_success
  run make -s release VERSION=1.0.1
  assert_success
  run cat "${GH_LOG}"
  assert_output --partial "release create 1.0.1 --repo example/app --generate-notes --latest=false --notes-start-tag 1.0.0"
}

@test "a version that decides its branch is released from that branch only" {
  sed -i 's/^RELEASE_BRANCHES = .*/RELEASE_BRANCHES = main 1.x\nRELEASE_BRANCH = $(if $(VERSION),$(RELEASE_MAJOR).x)/' Makefile
  git commit -qam "chore: one branch per major"
  git push -q origin main
  git switch -q -c 1.x
  git push -q origin 1.x
  bump 1.0.1 6
  run make -s release-prepare VERSION=1.0.1
  assert_success

  git switch -q main
  run make -s release-prepare VERSION=1.0.2
  assert_failure
  assert_output --partial "1.0.2 is released from 1.x (on main)"
}
