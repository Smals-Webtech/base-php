#!/usr/bin/env bash

log "INFO" "Configure Supervisor ..."

OUTDIR="/opt/etc/supervisor.d /app/var/run /app/var/log"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup Main Configuration File ..."

# The TCP listener is reachable from outside the container: it needs a password
# of its own, and the former documented default is refused like none at all.
if [[ "${SUPERVISOR_XMLRPC_INET_ENABLED}" != "false" ]] &&
	[[ -z "${SUPERVISOR_XMLRPC_INET_PASSWORD}" || "${SUPERVISOR_XMLRPC_INET_PASSWORD}" == "pa55w0rd" ]]; then
	log "ERROR" "! SUPERVISOR_XMLRPC_INET_ENABLED is on without a password: set SUPERVISOR_XMLRPC_INET_PASSWORD (not the former default)."
	exit 1
fi

apply-template /opt/config/supervisord.conf.tmpl /opt/etc/supervisord.conf

# Both files carry SUPERVISOR_XMLRPC_UNIX_SOCKET_PASSWORD. umask 002 in a tree
# copied with --chmod=777 leaves them world-readable otherwise, the same reason
# the AWS credentials file is narrowed where it is written.
chmod 600 /opt/etc/supervisord.conf

if [[ "${SUPERVISOR_FAIL_FAST_ENABLED}" == "true" ]]; then
	log "INFO" "- Setup Fail-Fast Listener (${SUPERVISOR_FAIL_FAST_PROGRAMS}) ..."
	apply-template /opt/config/supervisor.d/fail-fast.ini.tmpl /opt/etc/supervisor.d/fail-fast.ini
	chmod 600 /opt/etc/supervisor.d/fail-fast.ini
else
	# A reused /opt/etc (a volume, an emptyDir across a restart) still holds the
	# listener of a previous start: switched off means gone.
	rm -f /opt/etc/supervisor.d/fail-fast.ini
fi

true
