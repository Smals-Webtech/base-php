#!/usr/bin/env bash

function log {

	local level=$1
	local message=$2

	# shellcheck disable=SC2155
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	local color_reset="\033[0m"
	local color_red="\033[31m"
	local color_green="\033[32m"
	local color_yellow="\033[33m"
	local color_blue="\033[34m"

	case $level in
	INFO)
		color="$color_green"
		;;
	WARN)
		color="$color_yellow"
		;;
	ERROR)
		color="$color_red"
		;;
	DEBUG)
		color="$color_blue"
		;;
	*)
		color="$color_reset"
		;;
	esac

	echo -e "${color}[${timestamp}] [${level}] ${message}${color_reset}"

}

# The four runtime paths this image writes to used to be declared as VOLUME, so
# a plain `docker run --read-only` got an anonymous volume for each and always
# worked. The declarations are gone -- they are inherited, cannot be removed by
# a child image, and silently discard anything a child writes to those paths at
# build time -- so the caller now provides the mounts, and an unusable path has
# to say so loudly instead of failing halfway through the boot.
function _mount-hint {

	log "ERROR" "! docker:     add --tmpfs /opt/etc --tmpfs /opt/sbin:exec --tmpfs /app/var --tmpfs /app/tmp"
	log "ERROR" "! Kubernetes: mount an emptyDir at each path."

}

# A real write rather than `[ -w ]`, which reports success for root even on a
# read-only mount.
function require-writable {

	local dir=$1
	local probe="${dir}/.wcmtech-writable-$$"

	mkdir -p "$dir" 2>/dev/null

	if ! (: >"$probe") 2>/dev/null; then
		log "ERROR" "! ${dir} is not writable."
		log "ERROR" "! This image renders its runtime state there and no longer declares a VOLUME for it."
		_mount-hint
		return 1
	fi

	rm -f "$probe"

}

# /opt/sbin holds scripts, so it has to be executable and not merely writable. A
# noexec mount reports nothing: execve returns EACCES and the shell quietly
# carries on with its PATH search, which is how a wrapper on that path was being
# bypassed without a single error line. Refuse it at boot instead.
function require-executable {

	local dir=$1
	local probe="${dir}/.wcmtech-executable-$$"

	require-writable "$dir" || return 1

	printf '#!/bin/sh\nexit 0\n' >"$probe"
	chmod +x "$probe" 2>/dev/null

	if ! "$probe" 2>/dev/null; then
		rm -f "$probe"
		log "ERROR" "! ${dir} is mounted noexec, and this image renders scripts there."
		log "ERROR" "! Mount it executable, e.g. --tmpfs ${dir}:rw,exec"
		return 1
	fi

	rm -f "$probe"

}

function apply-template {

	SRC=$1
	DEST=$2

	# .tmpl file
	if [ -f "$SRC" ]; then

		if [[ "$SRC" == *.tmpl ]]; then
			require-writable "$(dirname "$DEST")" || return 1
			log "INFO" "  Rendering template: $SRC → $DEST"
			gomplate -f "$SRC" -o "$DEST"
		else
			log "ERROR" "! File $SRC is not a .tmpl file."
			return 1
		fi

	# dir
	elif [ -d "$SRC" ]; then

		if [ ! -d "$DEST" ]; then
			log "ERROR" "! $DEST is not a directory."
			return 1
		fi
		require-writable "$DEST" || return 1

		# Without nullglob an empty directory leaves the pattern literal and
		# gomplate is handed a path that does not exist. /opt/config/sbin is
		# exactly that case: the image may ship no template there at all, and
		# everything in it comes from whoever mounts one.
		local had_nullglob=1
		shopt -q nullglob || had_nullglob=0
		shopt -s nullglob

		for f in "$SRC"/*.tmpl; do
			ff=$(basename "$f")
			log "INFO" "  Rendering template: $f → $DEST/${ff%.tmpl}"
			gomplate -f "$f" -o "$DEST/${ff%.tmpl}"
		done

		[ "$had_nullglob" -eq 1 ] || shopt -u nullglob

	else
		log "ERROR" "! $SRC is neither a tmpl file nor a directory."
		return 1
	fi

}

function create-symlink {

	SRC=$1
	DEST=$2

	if [ -L "$SRC" ]; then
		CURRENT_TARGET="$(readlink "$SRC")"
		if [ "$CURRENT_TARGET" = "$DEST" ]; then
			log "INFO" "  Symbolic link already exists: $SRC → $DEST"
		else
			log "WARN" "  Symbolic link $SRC points to $CURRENT_TARGET; expected $DEST. Recreating ..."
			rm -f "$SRC"
			ln -s "$DEST" "$SRC"
			log "INFO" "  Symbolic link recreated: $SRC → $DEST"
		fi
	elif [ -e "$SRC" ]; then
		log "INFO" "  A file or directory already exists at this location: $SRC"
		log "INFO" "  Removing the existing file/directory..."
		rm -rf "$SRC"
		ln -s "$DEST" "$SRC"
		log "INFO" "  Symbolic link recreated: $SRC → $DEST"
	else
		ln -s "$DEST" "$SRC"
		log "INFO" "  Symbolic link created: $SRC → $DEST"
	fi

}

# Prints a banner, protected against a web console that renders logs into HTML.
# There a *run* of spaces collapses to a single one and the art falls apart --
# measured on the production console, while the QA one leaves it alone.
# Alternating a real space with a no-break space breaks up every run, so there is
# nothing left to collapse, and the cell count does not move.
#
# It fires on two spaces and never on one, so words stay separated by ordinary
# ASCII spaces and the line remains greppable in a log file. That is what rules a
# zero-width character out here: it would survive the console too, invisibly, and
# would take `grep "Smals WebAgency"` down with it.
#
# FILE defaults to the image's own banner and is optional in that case. A child
# image passes its own path, and then an unreadable file is an error rather than
# a silent no-op. An empty file prints nothing -- that is how a banner is turned
# off, no knob needed.
function print-banner {

	local file=${1:-/opt/config/motd}
	local content

	# A directory passes -r, and reading one yields nothing: a bind mount whose
	# source is missing on the host makes the engine create a directory in its
	# place, and the banner then vanished in silence. Rejecting directories
	# rather than requiring a regular file keeps a fifo, or a process
	# substitution, working.
	if [ -d "$file" ] || [ ! -r "$file" ]; then
		[ $# -eq 0 ] && return 0
		log "ERROR" "! Banner file ${file} is not a readable file."
		return 1
	fi

	# $(<file) is read by bash itself: no subprocess, unlike $(cat file).
	content=$(<"$file")
	[ -n "$content" ] || return 0

	# Raw UTF-8 bytes rather than \u escapes, so this does not depend on the locale.
	printf '\033[32m%s\033[0m\n\n' "${content//  /$' \xc2\xa0'}"

}

true
