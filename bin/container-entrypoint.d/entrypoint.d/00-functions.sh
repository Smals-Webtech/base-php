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

function apply-template {

	TPLDIR=$1
	OUTDIR=$2

	for f in "${TPLDIR}"/*.tmpl; do
		ff=$(basename "$f")
		if [ -w "$OUTDIR" ]; then
			gomplate \
				-f "${TPLDIR}"/"${ff}" \
				-o "${OUTDIR}"/"${ff%.tmpl}"
		else
			log "ERROR" "! Write permission is NOT granted on $OUTDIR ."
		fi

	done

}

true
