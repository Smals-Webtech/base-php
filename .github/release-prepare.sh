#!/usr/bin/env bash
# Writes the CHANGELOG.md section of a release, so `make release` commits it with the tag.
#
#   release-prepare.sh <x.y.z>            a new version: [Unreleased] becomes [x.y.z]
#   release-prepare.sh <x.y.z> --retag    a re-publication: [Unreleased] moves under the existing
#                                         [x.y.z], as "### Re-published on <date>"
#
# What it writes, under [Unreleased] first:
#   - the pinned dependencies that changed (changelog-deps.sh);
#   - one line per pull request merged since the tag, from its title: feat -> Added, fix -> Fixed,
#     perf/refactor/revert -> Changed. chore, ci, docs, test and build titles do not change the image
#     and are left out; Renovate's chore(deps) ones are the dependency lines already.
# Anything already written under [Unreleased] by hand is kept. Nothing is committed: read the
# result (git diff CHANGELOG.md), add prose if you want to, then `make release` or `make retag`.
set -euo pipefail

version=${1:?usage: release-prepare.sh x.y.z [--retag]}
retag=false
[[ "${2:-}" == "--retag" ]] && retag=true
file=${CHANGELOG:-CHANGELOG.md}
dir=$(cd "$(dirname "$0")" && pwd)

[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || { echo "not a version: ${version}" >&2; exit 1; }
grep -q '^## \[Unreleased\]' "${file}" || { echo "no '## [Unreleased]' in ${file}" >&2; exit 1; }

if [[ "${retag}" == "true" ]]; then
	git rev-parse -q --verify "refs/tags/${version}" >/dev/null || { echo "no tag ${version} to re-publish" >&2; exit 1; }
	grep -qF "## [${version}]" "${file}" || { echo "no '## [${version}]' section in ${file}" >&2; exit 1; }
	if awk -v version="## [${version}]" -v title="### Re-published on $(date -u +%Y-%m-%d)" '
		index($0, version) == 1 { inside = 1; next } inside && /^## \[/ { inside = 0 } inside && $0 == title { found = 1 }
		END { exit !found }' "${file}"; then
		echo "${version} already has today's re-publication in ${file}: edit it, or git checkout ${file} and run again" >&2
		exit 1
	fi
	since=${version}
else
	git rev-parse -q --verify "refs/tags/${version}" >/dev/null && { echo "tag ${version} exists: use --retag" >&2; exit 1; }
	grep -qF "## [${version}]" "${file}" && { echo "'## [${version}]' is already in ${file}" >&2; exit 1; }
	since=$(git describe --tags --abbrev=0 --match '[0-9]*.[0-9]*.[0-9]*')
fi
echo "changes since ${since}"

# Adds <entry> under <heading> in [Unreleased], unless a line with the same (#N) is there already.
add_entry() {
	local heading=$1 entry=$2
	awk -v heading="### ${heading}" -v entry="${entry}" -v key="${3:-}" '
		function flush() { if (!done) { print heading; print ""; print entry; print ""; done = 1 } }
		/^## \[Unreleased\]/ { inside = 1; print; next }
		inside && /^## \[/ { flush(); inside = 0 }
		inside && key != "" && index($0, key) { done = 1 }
		inside && $0 == heading { print; found = 1; next }
		inside && found && !done && /^$/ { print; print entry; done = 1; next }
		{ print }
		END { if (inside) flush() }
	' "${file}" >"${file}.tmp" && mv "${file}.tmp" "${file}"
}

bash "${dir}/changelog-deps.sh" "${since}" --apply

while IFS= read -r subject; do
	[[ "${subject}" =~ ^([a-z]+)(\(([^\)]+)\))?!?:\ (.+)\ \(#([0-9]+)\)$ ]] || continue
	type=${BASH_REMATCH[1]} scope=${BASH_REMATCH[3]} text=${BASH_REMATCH[4]} pr=${BASH_REMATCH[5]}
	case "${type}" in
		feat) heading=Added ;;
		fix) heading=Fixed ;;
		perf | refactor | revert) heading=Changed ;;
		*) continue ;;
	esac
	entry="- ${scope:+\`${scope}\`: }${text} (#${pr})."
	add_entry "${heading}" "${entry}" "(#${pr})"
	echo "added: ${entry}" >&2
done < <(git log --first-parent --format=%s "${since}..HEAD")

# The [Unreleased] body, without its heading and its surrounding blank lines.
body=$(awk '/^## \[Unreleased\]/ { inside = 1; next } inside && /^## \[/ { exit } inside' "${file}" |
	sed -e '/./,$!d' | tac | sed -e '/./,$!d' | tac)
[[ -n "${body}" ]] || { echo "nothing to record since ${since}" >&2; exit 1; }

if [[ "${retag}" == "true" ]]; then
	# Under the version, after its introduction and before its first subsection; the subsection
	# headings of [Unreleased] become plain lines, the entries keep their order.
	entries=$(grep -v '^### ' <<<"${body}" | sed '/^$/d')
	awk -v version="## [${version}]" -v title="### Re-published on $(date -u +%Y-%m-%d)" -v entries="${entries}" '
		/^## \[Unreleased\]/ { print; print ""; skip = 1; next }
		skip && /^## \[/ { skip = 0 }
		skip { next }
		index($0, version) == 1 { print; inside = 1; next }
		inside && (/^### / || /^## \[/) { print title; print ""; print entries; print ""; inside = 0 }
		{ print }
		END { if (inside) { print ""; print title; print ""; print entries } }
	' "${file}" >"${file}.tmp" && mv "${file}.tmp" "${file}"
else
	awk -v version="## [${version}]" '
		/^## \[Unreleased\]/ { print; print ""; print version; next }
		{ print }
	' "${file}" >"${file}.tmp" && mv "${file}.tmp" "${file}"
fi

# The markdown checks the CI runs, on this file only, when Docker is there (LINT=0 skips them).
if [[ "${LINT:-1}" == "1" ]] && command -v docker >/dev/null 2>&1; then
	echo "linting ${file}..."
	docker run --rm -e RUN_LOCAL=true -e VALIDATE_ALL_CODEBASE=true -e VALIDATE_MARKDOWN=true \
		-e DEFAULT_BRANCH="$(git rev-parse --abbrev-ref HEAD)" \
		-e VALIDATE_NATURAL_LANGUAGE=true -e FILTER_REGEX_INCLUDE="${file}" -e LOG_LEVEL=ERROR \
		-v "$(pwd):/tmp/lint" ghcr.io/super-linter/super-linter:slim-v9.0.0 >/dev/null 2>&1 &&
		echo "lint: clean" || echo "lint: findings -- run the linter on ${file} before releasing" >&2
fi

git --no-pager diff -- "${file}"
