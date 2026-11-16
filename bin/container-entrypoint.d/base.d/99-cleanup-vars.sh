#!/usr/bin/env bash

IFS=':' read -r -a VARS <<<"$CLEANUP_VAR_LIST"

for VAR in "${VARS[@]}"; do

	# The name only: these are the variables that carry the credentials.
	[[ "${DEBUG}" == "true" ]] && log "DEBUG" "Unsetting $VAR"
	unset "$VAR"

done

unset CLEANUP_VAR_LIST

true
