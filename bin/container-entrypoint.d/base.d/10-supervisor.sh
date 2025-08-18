#!/usr/bin/env bash

log "INFO" "| Configure Supervisor ..."

OUTDIR="/opt/etc/supervisor.d /app/var/run /app/var/log"
mkdir -p $OUTDIR

apply-template /opt/config/supervisord.conf.tmpl /opt/etc/supervisord.conf

true
