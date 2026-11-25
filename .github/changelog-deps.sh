#!/usr/bin/env bash
# Lists the dependency updates that ship in the image since a tag, as CHANGELOG lines:
#   - **`<dep>` <new>**, up from <old> (dependency update).
#   - **<image> images updated** to their latest published digests.
# It compares the versions pinned at <since> and at HEAD: in the Dockerfile, the `# syntax=`
# frontend, every `ARG *_VERSION_ARG` and the base images pinned by digest (`FROM` lines written
# out in full, `ARG *_IMAGE`); in docker-bake.hcl, the default of every `variable "*_VERSION"`.
# A bake variable and the ARG of the same name (X_VERSION, X_VERSION_ARG) are one pin: the ARG's
# value when it has one, the bake default otherwise (an ARG left empty, filled by bake). Renovate
# no longer writes these lines itself, so its pull requests never conflict on CHANGELOG.md.
#
# The same file is copied in every image repository (make tooling-check in base-php compares
# them). What differs is set by the repository's Makefile (.github/release.mk exports it):
#   CHANGELOG_DEP_NAMES  "X_VERSION_ARG=Name ...": the name a line gives to a pin without a
#                        `# renovate: ... depName=` annotation (default: the variable's name).
#
# Usage: changelog-deps.sh [<since>] [--apply]
#   <since>  defaults to the latest release tag reachable from HEAD.
#   --apply  writes the lines under "## [Unreleased]" -> "### Changed" in CHANGELOG.md, replacing
#            a line already there for the same dependency; without it, they are only printed.
set -euo pipefail

names=${CHANGELOG_DEP_NAMES:-}

since=""
apply=false
for arg in "$@"; do
	case "${arg}" in
	--apply) apply=true ;;
	*) since=${arg} ;;
	esac
done
[[ -n "${since}" ]] || since=$(git describe --tags --abbrev=0 --match '[0-9]*.[0-9]*.[0-9]*')
git rev-parse -q --verify "${since}^{commit}" >/dev/null || {
	echo "unknown revision: ${since}" >&2
	exit 1
}
file=${CHANGELOG:-CHANGELOG.md}

# Prints "<key> <dep> <version> <digest>" for every pin of a Dockerfile, first occurrence only
# ("-" when there is no digest). An ARG is keyed by its name, a FROM line by its stage. An ARG
# without a value is left out: docker-bake.hcl gives it one (bake_pins).
dockerfile_pins() {
	awk -v names="${names}" '
		BEGIN { n = split(names, a, " "); for (i = 1; i <= n; i++) { split(a[i], kv, "="); name[kv[1]] = kv[2] } }
		function image(key, ref,   dig, at) {
			dig = "-"
			if ((at = index(ref, "@")) > 0) { dig = substr(ref, at + 1); ref = substr(ref, 1, at - 1) }
			if (!match(ref, /:[^:\/]+$/)) return
			print key, substr(ref, 1, RSTART - 1), substr(ref, RSTART + 1), dig
		}
		/^# syntax=/ { image("syntax", substr($0, 10)); next }
		/^# renovate:/ { if (match($0, /depName=[^ ]+/)) dep = substr($0, RSTART + 8, RLENGTH - 8); next }
		/^ARG [A-Z_]+_VERSION_ARG=/ {
			k = $2; sub(/=.*/, "", k); v = $2; sub(/^[^=]*=/, "", v); gsub(/"/, "", v)
			if (v != "") print k, (dep != "" ? dep : (k in name ? name[k] : k)), v, "-"
			dep = ""; next
		}
		/^ARG [A-Z_]+_IMAGE=/ { k = $2; sub(/=.*/, "", k); v = $2; sub(/^[^=]*=/, "", v); gsub(/"/, "", v); image(k, v); dep = ""; next }
		{ dep = "" }
		/^FROM / && !/\$/ {
			for (i = 2; i <= NF; i++) if ($i !~ /^--/) break
			stage = (tolower($(i + 1)) == "as") ? $(i + 2) : $i
			image("FROM:" stage, $i)
		}
	'
}

# Prints "<key> <dep> <version> -" for every `variable "X_VERSION"` of a docker-bake.hcl with a
# default, keyed X_VERSION_ARG like the matching ARG. DOCKER_IMAGE_VERSION is the build's own tag.
bake_pins() {
	awk -v names="${names}" '
		BEGIN { n = split(names, a, " "); for (i = 1; i <= n; i++) { split(a[i], kv, "="); name[kv[1]] = kv[2] } }
		/^# renovate:/ { if (match($0, /depName=[^ ]+/)) dep = substr($0, RSTART + 8, RLENGTH - 8); next }
		/^variable "[A-Z_]+_VERSION"/ {
			k = $2; gsub(/"/, "", k); var = (k == "DOCKER_IMAGE_VERSION") ? "" : k "_ARG"; d = dep; dep = ""; next
		}
		var != "" && /^[[:space:]]*default[[:space:]]*=/ {
			v = $0; sub(/^[^=]*=[[:space:]]*/, "", v); gsub(/[" ]/, "", v)
			if (v != "") print var, (d != "" ? d : (var in name ? name[var] : var)), v, "-"
			var = ""; next
		}
		/^}/ { var = "" }
		{ dep = "" }
	'
}

# The pins of a revision ("" for the working tree): the Dockerfile first, so an ARG with a value
# wins over the bake default of the same name.
pins() {
	local rev=$1
	{
		if [[ -z "${rev}" ]]; then dockerfile_pins <Dockerfile; else git show "${rev}:Dockerfile" | dockerfile_pins; fi
		if [[ -z "${rev}" ]]; then
			[[ ! -f docker-bake.hcl ]] || bake_pins <docker-bake.hcl
		else
			git show "${rev}:docker-bake.hcl" 2>/dev/null | bake_pins || true
		fi
	} | awk '!seen[$1]++'
}

# join on the key; fields: key, old dep, old version, old digest, new dep, new version, new digest.
lines=$(join <(pins "${since}" | sort) <(pins "" | sort) |
	awk '
		$3 != $6 { printf "- **`%s` %s**, up from %s (dependency update).\n", $5, $6, $3; next }
		$4 != $7 { img = $5; sub(/.*\//, "", img); if (!seen[img]++) printf "- **%s images updated** to their latest published digests.\n", img }
	')

if [[ -z "${lines}" ]]; then
	echo "no pinned dependency changed since ${since}" >&2
	exit 0
fi
if [[ "${apply}" != "true" ]]; then
	echo "${lines}"
	exit 0
fi

# The key of a line is its text up to the version ("- **`<dep>` ") or the whole bold part of a
# digest line; a line with the same key under [Unreleased] is replaced.
awk -v lines="${lines}" '
	BEGIN {
		n = split(lines, entry, "\n")
		for (i = 1; i <= n; i++) {
			k = entry[i]
			if (k ~ /images updated\*\*/) sub(/\*\* .*/, "**", k); else sub(/ [^ ]*\*\*, up from .*/, " ", k)
			key[i] = k
		}
	}
	function flush() {
		if (done) return
		if (!changed) { print "### Changed"; print "" }
		for (i = 1; i <= n; i++) print entry[i]
		if (!changed) print ""
		done = 1
	}
	function known(line,   i) { for (i = 1; i <= n; i++) if (index(line, key[i]) == 1) return 1; return 0 }
	/^## \[Unreleased\]/ { in_unreleased = 1; print; next }
	in_unreleased && /^## \[/ { flush(); in_unreleased = 0 }
	in_unreleased && known($0) { next }
	in_unreleased && /^### Changed/ { print; changed = 1; next }
	in_unreleased && changed && !done && /^$/ { print; flush(); next }
	{ print }
	END { if (in_unreleased) flush() }
' "${file}" >"${file}.tmp"
mv "${file}.tmp" "${file}"
while IFS= read -r entry; do echo "added: ${entry}" >&2; done <<<"${lines}"
