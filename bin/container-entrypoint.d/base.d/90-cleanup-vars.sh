#!/usr/bin/env bash

IFS=':' read -r -a VARS <<<"$CLEANUP_VAR_LIST"

for VAR in "${VARS[@]}"; do

	[[ "${DEBUG}" == "true" ]] && log "DEBUG" "Unsetting $VAR (was '${!VAR}')"
	unset "$VAR"

done

unset CLEANUP_VAR_LIST

true
