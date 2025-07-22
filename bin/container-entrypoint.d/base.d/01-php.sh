#!/usr/bin/env bash

log "INFO" "Setup PHP INI Configuration File(s) ..."

OUTDIR="/app/etc/php/conf.d"
mkdir -p "$OUTDIR"

apply-template /app/config/php/conf.d /app/etc/php/conf.d

true
