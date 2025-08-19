#!/usr/bin/env bash

log "INFO" "Configure PHP-FPM ..."

OUTDIR="/opt/etc/php/php-fpm.d /opt/etc/supervisor.d /app/var/log /app/var/lock /app/var/run/php-fpm"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup Pool Configuration File(s) ..."

apply-template /opt/config/php/php-fpm.d /opt/etc/php/php-fpm.d
apply-template /opt/config/supervisor.d/php-fpm.ini.tmpl /opt/etc/supervisor.d/php-fpm.ini

true
