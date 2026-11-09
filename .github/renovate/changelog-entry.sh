#!/usr/bin/env bash
# Adds "- **`<dep>` <new>**, up from <current>." under "## [Unreleased]" -> "### Changed"
# in CHANGELOG.md. Renovate runs it after updating a dependency that ships in the
# image (see renovate.json, postUpgradeTasks). Run again for the same dependency,
# it replaces its own line instead of adding a second one.
set -euo pipefail

dep=$1
from=$2
to=$3
file=${CHANGELOG:-CHANGELOG.md}
entry="- **\`${dep}\` ${to}**, up from ${from} (dependency update)."

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
