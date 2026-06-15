#!/usr/bin/env bash

log "INFO" "Cleaning up stale runtime sockets and pid files ..."

# A previous container may have exited uncleanly (SIGKILL after the termination
# grace period, OOM kill, failed liveness/readiness probe). On orchestrators
# where the runtime volume (/app/var) outlives a container restart -- e.g. an
# OpenShift emptyDir or a tmpfs emptyDir, both scoped to the pod lifetime --
# leftover unix sockets (php-fpm, nginx, supervisor) and pid files survive and
# make php-fpm/apache/nginx fail with "Address already in use" on the next
# start. Remove them here, before supervisord launches the services: nothing is
# listening yet, so this is safe and idempotent. /app/var/lock is left alone on
# purpose (it holds the app-init guard, see 90-app.sh).
if [ -d /app/var/run ]; then
	find /app/var/run -type s -delete 2>/dev/null || true
	find /app/var/run -type f -name '*.pid' -delete 2>/dev/null || true
fi

true
