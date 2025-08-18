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

	SRC=$1
	DEST=$2

	# .tmpl file
	if [ -f "$SRC" ]; then

		if [[ "$SRC" == *.tmpl ]]; then
			if [ -d "$(dirname "$DEST")" ] && [ -w "$(dirname "$DEST")" ]; then
				gomplate -f "$SRC" -o "$DEST"
			else
				log "ERROR" "! Write permission is NOT granted on $(dirname "$DEST") ."
			fi
		else
			log "ERROR" "! File $SRC is not a .tmpl file."
		fi

	# dir
	elif [ -d "$SRC" ]; then

		if [ ! -d "$DEST" ]; then
			log "ERROR" "! $DEST is not a directory."
			return 1
		fi
		if [ ! -w "$DEST" ]; then
			log "ERROR" "! Write permission is NOT granted on $DEST ."
			return 1
		fi
		for f in "$SRC"/*.tmpl; do
			ff=$(basename "$f")
			gomplate -f "$f" -o "$DEST/${ff%.tmpl}"
		done

	else
		log "ERROR" "! $SRC is neither a tmpl file nor a directory."
		return 1
	fi

}

function create-symlink {

	SRC=$1
	DEST=$2

	if [ -L "$SRC" ]; then
		echo "Lien symbolique déjà présent : $SRC"
	elif [ -e "$SRC" ]; then
		echo "Un fichier ou dossier existe déjà à cet emplacement : $SRC"
		echo "Suppression de l'ancien fichier/dossier..."
		rm -rf "$SRC"
		ln -s "$DEST" "$SRC"
		echo "Lien symbolique recréé : $SRC → $DEST"
	else
		ln -s "$DEST" "$SRC"
		echo "Lien symbolique créé : $SRC → $DEST"
	fi

}

true
