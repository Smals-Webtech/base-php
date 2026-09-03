#!/usr/bin/env bash

# How long a replica waits for another one sharing /app/var to finish running the
# application init scripts before giving up and failing the boot. Failing is the
# point: the alternative is running someone else's migrations alongside them.
APP_INIT_LOCK_TIMEOUT_WCMTECH_DEFAULT="300"

if [ -d /opt/bin/container-entrypoint.d/entrypoint.d ]; then

	for FILE in $(find /opt/bin/container-entrypoint.d/entrypoint.d -iname \*.sh | sort); do
		source "${FILE}"
	done

fi

true
