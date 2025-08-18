#!/usr/bin/env bash

log "INFO" "Setup PHP INI Configuration File(s) ..."

OUTDIR="/opt/etc/php/conf.d"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

apply-template /opt/config/php/conf.d /opt/etc/php/conf.d

true
