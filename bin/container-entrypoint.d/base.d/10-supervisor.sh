#!/usr/bin/env bash

log "INFO" "Configure Supervisor ..."

OUTDIR="/opt/etc/supervisor.d /app/var/run /app/var/log"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup Main Configuration File ..."

apply-template /opt/config/supervisord.conf.tmpl /opt/etc/supervisord.conf

# Both files carry SUPERVISOR_XMLRPC_UNIX_SOCKET_PASSWORD. umask 002 in a tree
# copied with --chmod=777 leaves them world-readable otherwise, the same reason
# the AWS credentials file is narrowed where it is written.
chmod 600 /opt/etc/supervisord.conf

if [[ "${SUPERVISOR_FAIL_FAST_ENABLED}" == "true" ]]; then
	log "INFO" "- Setup Fail-Fast Listener (${SUPERVISOR_FAIL_FAST_PROGRAMS}) ..."
	apply-template /opt/config/supervisor.d/fail-fast.ini.tmpl /opt/etc/supervisor.d/fail-fast.ini
	chmod 600 /opt/etc/supervisor.d/fail-fast.ini
fi

true
