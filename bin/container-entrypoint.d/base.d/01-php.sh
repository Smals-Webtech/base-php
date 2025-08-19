#!/usr/bin/env bash

log "INFO" "Configure PHP ..."

OUTDIR="/opt/etc/php/conf.d"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup INI Configuration File(s) ..."

apply-template /opt/config/php/conf.d /opt/etc/php/conf.d

true
