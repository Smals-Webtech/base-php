#!/usr/bin/env bash
# Writes the CHANGELOG.md section of a release, so `make release` commits it with the tag.
#
#   release-prepare.sh <version>          a new version: [Unreleased] becomes [<version>]
#   release-prepare.sh <version> --retag  a re-publication: [Unreleased] moves under the existing
#                                         [<version>], as "### Re-published on <date>"
#
# <version> is x.y.z, with an optional +suffix (limesurvey's x.y.z+yymmdd). The same file is copied
# in every image repository (make tooling-check in base-php compares them): what differs between
# repositories is their CHANGELOG.md and their changelog-deps.sh, not this script.
#
# What it writes, under [Unreleased] first:
#   - the pinned dependencies that changed, when the repository has a changelog-deps.sh;
#   - one line per pull request merged since the previous tag of the same major line, from its
#     title: feat -> Added, fix -> Fixed, perf/refactor/revert -> Changed. chore, ci, docs, test and
#     build titles do not change the image and are left out. Renovate's chore(deps) titles are the
#     dependency lines already; without a changelog-deps.sh, or with CHANGELOG_DEPS_TITLES=keep
#     (dependencies the script cannot read, such as Python packages), they are kept, under
#     Changed, as the record of the update.
#   A squash merge carries the title in its subject, "title (#N)"; a merge commit carries it in its
#   body, after "Merge pull request #N from ...". Any other commit on the first-parent line (a
#   rebase merge, a direct commit) is listed as "not recorded", for a line to be written by hand.
# Anything already written under [Unreleased] by hand is kept. Nothing is committed: read the
# result (git diff CHANGELOG.md), add prose if you want to, then `make release` or `make retag`.
set -euo pipefail

version=${1:?usage: release-prepare.sh x.y.z[+suffix] [--retag]}
retag=false
[[ "${2:-}" == "--retag" ]] && retag=true
file=${CHANGELOG:-CHANGELOG.md}
dir=$(cd "$(dirname "$0")" && pwd)

[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || {
	echo "not a version: ${version}" >&2
	exit 1
}
grep -q '^## \[Unreleased\]' "${file}" || {
	echo "no '## [Unreleased]' in ${file}" >&2
	exit 1
}

if [[ "${retag}" == "true" ]]; then
	git rev-parse -q --verify "refs/tags/${version}" >/dev/null || {
		echo "no tag ${version} to re-publish" >&2
		exit 1
	}
	grep -qF "## [${version}]" "${file}" || {
		echo "no '## [${version}]' section in ${file}" >&2
		exit 1
	}
	if awk -v version="## [${version}]" -v title="### Re-published on $(date -u +%Y-%m-%d)" '
		index($0, version) == 1 { inside = 1; next } inside && /^## \[/ { inside = 0 } inside && $0 == title { found = 1 }
		END { exit !found }' "${file}"; then
		echo "${version} already has today's re-publication in ${file}: edit it, or git checkout ${file} and run again" >&2
		exit 1
	fi
	since=${version}
else
	git rev-parse -q --verify "refs/tags/${version}" >/dev/null && {
		echo "tag ${version} exists: use --retag" >&2
		exit 1
	}
	grep -qF "## [${version}]" "${file}" && {
		echo "'## [${version}]' is already in ${file}" >&2
		exit 1
	}
	# The nearest tag of the same major line: limesurvey releases 6.x and 7.x side by side. The
	# first release of a new major line falls back to the nearest tag of any line.
	since=$(git describe --tags --abbrev=0 --match "${version%%.*}.*" 2>/dev/null ||
		git describe --tags --abbrev=0 --match '[0-9]*.[0-9]*.[0-9]*')
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

deps_script=false
if [[ -f "${dir}/changelog-deps.sh" ]]; then
	bash "${dir}/changelog-deps.sh" "${since}" --apply
	deps_script=true
fi

# One record per first-parent commit: sha, subject and body, separated by \x1f, ended by \x1e.
while IFS=$'\x1f' read -r -d $'\x1e' sha subject body; do
	sha=${sha#$'\n'}
	if [[ "${subject}" =~ ^Merge\ pull\ request\ \#([0-9]+)\  ]]; then
		pr=${BASH_REMATCH[1]}
		title=$(sed -n '/[^[:space:]]/{p;q}' <<<"${body}")
		line="${title} (#${pr})"
	elif [[ "${subject}" =~ ^chore(\(release\))?:\ (prepare\ release|re-publish) ]]; then
		continue
	else
		line=${subject}
	fi
	if ! [[ "${line}" =~ ^([a-z]+)(\(([^\)]+)\))?!?:\ (.+)\ \(#([0-9]+)\)$ ]]; then
		echo "not recorded: ${sha:0:7} ${subject}" >&2
		continue
	fi
	type=${BASH_REMATCH[1]} scope=${BASH_REMATCH[3]} text=${BASH_REMATCH[4]} pr=${BASH_REMATCH[5]}
	case "${type}" in
	feat) heading=Added ;;
	fix) heading=Fixed ;;
	perf | refactor | revert) heading=Changed ;;
	chore)
		[[ "${scope}" == "deps" ]] || continue
		[[ "${deps_script}" == "false" || "${CHANGELOG_DEPS_TITLES:-}" == "keep" ]] || continue
		heading=Changed scope=""
		;;
	*) continue ;;
	esac
	entry="- ${scope:+\`${scope}\`: }${text} (#${pr})."
	add_entry "${heading}" "${entry}" "(#${pr})"
	echo "added: ${entry}" >&2
done < <(git log --first-parent --format='%H%x1f%s%x1f%b%x1e' "${since}..HEAD")

# The [Unreleased] body, without its heading and its surrounding blank lines.
body=$(awk '/^## \[Unreleased\]/ { inside = 1; next } inside && /^## \[/ { exit } inside' "${file}" |
	sed -e '/./,$!d' | tac | sed -e '/./,$!d' | tac)
[[ -n "${body}" ]] || {
	echo "nothing to record since ${since}" >&2
	exit 1
}

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

git --no-pager diff -- "${file}"

# The whole tree, with the CI's super-linter version and settings: the CI lints only
# the files a pull request changes, so this is where everything is checked before a
# tag. A finding stops here, with the CHANGELOG written: fix, `make lint`, then
# release. LINT=0 skips it (tests of this script).
if [[ "${LINT:-1}" == "1" ]]; then
	command -v docker >/dev/null 2>&1 || {
		echo "docker is required for the release lint (LINT=0 skips it)" >&2
		exit 1
	}
	bash "${dir}/lint-local.sh" >"${TMPDIR:-/tmp}/release-prepare-lint.log" 2>&1 || {
		grep -E 'ERROR|error' "${TMPDIR:-/tmp}/release-prepare-lint.log" | tail -20 >&2
		echo "lint: findings in the tree (full log: ${TMPDIR:-/tmp}/release-prepare-lint.log) -- fix them before releasing" >&2
		exit 1
	}
	echo "lint: the whole tree is clean"
fi
