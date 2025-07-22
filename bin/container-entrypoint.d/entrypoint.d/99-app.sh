#!/usr/bin/env bash

if [ -d /app/bin/container-entrypoint.d/entrypoint.d ]; then

	for FILE in $(find /app/bin/container-entrypoint.d/entrypoint.d -iname \*.sh | sort); do
		source "${FILE}"
	done

fi

true
