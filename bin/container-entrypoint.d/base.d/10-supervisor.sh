#!/usr/bin/env bash

log "INFO" "Configure Supervisor ..."

OUTDIR="/opt/etc/supervisor.d /app/var/run /app/var/log"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup Main Configuration File ..."

apply-template /opt/config/supervisord.conf.tmpl /opt/etc/supervisord.conf

true
