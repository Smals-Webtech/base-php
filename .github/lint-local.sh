#!/usr/bin/env bash
# Lints the whole tree locally, with the super-linter version and settings of
# .github/workflows/lint.yaml, so the two cannot drift apart.
#
# The CI lints only the files a pull request changes, and nothing on a merge: the
# whole tree is linted here, before a release (make release-prepare) or on demand
# (make lint). It costs no Actions minutes, and a finding stops the release before
# the tag rather than after it.
#
# It lints the tracked files as they are in the working copy -- uncommitted changes
# included, such as the CHANGELOG release-prepare just wrote -- copied to a temporary
# directory: what the CI checks out, without the ignored and untracked files of a
# working copy (a test stack's vendor directory makes super-linter run composer install).
#
# Usage: lint-local.sh   (exit status: super-linter's)
set -euo pipefail

workflow=${LINT_WORKFLOW:-.github/workflows/lint.yaml}
[[ -f "${workflow}" ]] || {
	echo "no ${workflow}" >&2
	exit 2
}

# The image tag is the version the workflow pins: "@<sha> # v9.0.0" or "@v9.0.0".
uses=$(grep -m1 -E 'uses: super-linter/super-linter' "${workflow}")
version=$(grep -oE '# v[0-9.]+' <<<"${uses}" | tr -d '# ' || true)
[[ -n "${version}" ]] || version=$(grep -oE '@v[0-9.]+' <<<"${uses}" | tr -d '@')
[[ -n "${version}" ]] || {
	echo "cannot read the super-linter version in ${workflow}" >&2
	exit 2
}
image="ghcr.io/super-linter/super-linter:slim-${version}"

# The step's env block, as KEY=value: values that are expressions (${{ ... }}) only
# make sense in GitHub Actions, and the three this script sets itself are skipped.
mapfile -t settings < <(awk '
	/uses: super-linter\/super-linter/ { step = 1; next }
	step && /^[[:space:]]*env:[[:space:]]*$/ { env = 1; match($0, /^[[:space:]]*/); indent = RLENGTH; next }
	env {
		if ($0 ~ /^[[:space:]]*(#.*)?$/) next
		match($0, /^[[:space:]]*/); if (RLENGTH <= indent) exit
		line = $0; sub(/^[[:space:]]+/, "", line); sub(/[[:space:]]+#.*$/, "", line)
		key = line; sub(/:.*/, "", key); value = line; sub(/^[^:]*:[[:space:]]*/, "", value)
		gsub(/^"|"$/, "", value)
		if (value ~ /\$\{\{/ || key ~ /^(GITHUB_TOKEN|DEFAULT_BRANCH|VALIDATE_ALL_CODEBASE)$/) next
		print key "=" value
	}
' "${workflow}")

args=()
for setting in "${settings[@]}"; do args+=(-e "${setting}"); done

branch=$(git rev-parse --abbrev-ref HEAD)
tree=$(mktemp -d)
trap 'rm -rf "${tree}"' EXIT
git ls-files -z | tar --null --files-from=- --ignore-failed-read -cf - 2>/dev/null | tar -xf - -C "${tree}"
git -C "${tree}" init -q -b "${branch}"
git -C "${tree}" add -A
git -C "${tree}" -c user.name=lint -c user.email=lint@localhost -c commit.gpgsign=false commit -qm "lint"

echo "super-linter ${version}, whole tree ($(git ls-files | wc -l) tracked files), ${#settings[@]} settings from ${workflow}"
docker run --rm -e RUN_LOCAL=true -e VALIDATE_ALL_CODEBASE=true \
	-e DEFAULT_BRANCH="${branch}" -e LOG_LEVEL=NOTICE \
	"${args[@]}" -v "${tree}:/tmp/lint" "${image}"
