#!/usr/bin/env bash

if [ -d /opt/bin/container-entrypoint.d/entrypoint.d ]; then

	for FILE in $(find /opt/bin/container-entrypoint.d/entrypoint.d -iname \*.sh | sort); do
		source "${FILE}"
	done

fi

true
