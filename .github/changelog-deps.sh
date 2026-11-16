#!/usr/bin/env bash
# Lists the dependency updates that ship in the image since a tag, as CHANGELOG lines:
#   - **`<dep>` <new>**, up from <old> (dependency update).
# It compares the versions pinned in the Dockerfile at <since> and at HEAD: every ARG under a
# `# renovate:` annotation, the `# syntax=` frontend and the FROM lines written out in full.
# Renovate no longer writes these lines itself, so its pull requests never conflict on CHANGELOG.md.
#
# Usage: changelog-deps.sh [<since>] [--apply]
#   <since>  defaults to the latest x.y.z tag reachable from HEAD (the last release or retag).
#   --apply  writes the lines under "## [Unreleased]" -> "### Changed" in CHANGELOG.md, replacing
#            a line already there for the same dependency; without it, they are only printed.
set -euo pipefail

since=""
apply=false
for arg in "$@"; do
	case "${arg}" in
	--apply) apply=true ;;
	*) since=${arg} ;;
	esac
done
[[ -n "${since}" ]] || since=$(git describe --tags --abbrev=0 --match '[0-9]*.[0-9]*.[0-9]*')
file=${CHANGELOG:-CHANGELOG.md}

# Prints "<key> <dep> <version>" for every pin of a Dockerfile, first occurrence only. An ARG is
# keyed by its name, so a pin compares with a tag older than its `# renovate:` annotation.
pins() {
	awk '
		/^# syntax=/ { split(substr($0, 10), a, ":"); sub(/@.*/, "", a[2]); print a[1], a[1], a[2]; next }
		/^# renovate:/ { if (match($0, /depName=[^ ]+/)) dep = substr($0, RSTART + 8, RLENGTH - 8); next }
		/^ARG [A-Z_]+_VERSION_ARG=/ {
			k = $2; sub(/=.*/, "", k); v = $2; sub(/^[^=]*=/, "", v)
			print k, (dep != "" ? dep : k), v; dep = ""; next
		}
		{ dep = "" }
		/^FROM / && !/\$/ {
			for (i = 2; i <= NF; i++) if ($i !~ /^--/) break
			img = $i; sub(/@.*/, "", img)
			if (split(img, a, ":") == 2) print a[1], a[1], a[2]
		}
	' | awk '!seen[$1]++'
}

# join on the key; fields: key, old dep, old version, new dep, new version.
lines=$(join <(git show "${since}:Dockerfile" | pins | sort) <(pins <Dockerfile | sort) |
	awk '$3 != $5 { printf "- **`%s` %s**, up from %s (dependency update).\n", $4, $5, $3 }')

if [[ -z "${lines}" ]]; then
	echo "no pinned dependency changed since ${since}" >&2
	exit 0
fi
if [[ "${apply}" != "true" ]]; then
	echo "${lines}"
	exit 0
fi

while IFS= read -r entry; do
	dep=${entry#- \*\*\`}
	dep=${dep%%\`*}
	awk -v dep="${dep}" -v entry="${entry}" '
		function flush_changed() {
			if (!done) { print "### Changed"; print ""; print entry; print ""; done = 1 }
		}
		/^## \[Unreleased\]/ { in_unreleased = 1; print; next }
		in_unreleased && /^## \[/ { flush_changed(); in_unreleased = 0 }
		in_unreleased && /^### Changed/ { print; changed = 1; next }
		in_unreleased && changed && !done && /^$/ && !blank_seen { print; blank_seen = 1; print entry; done = 1; next }
		in_unreleased && index($0, "- **`" dep "` ") == 1 { next }
		{ print }
		END { if (in_unreleased) flush_changed() }
	' "${file}" >"${file}.tmp"
	mv "${file}.tmp" "${file}"
done <<<"${lines}"
while IFS= read -r entry; do echo "added: ${entry}" >&2; done <<<"${lines}"
