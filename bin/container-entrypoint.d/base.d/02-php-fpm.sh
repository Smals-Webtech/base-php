#!/usr/bin/env bash

log "INFO" "Setup PHP-FPM Pool Configuration File(s) ..."

OUTDIR="/app/etc/php/php-fpm.d /app/etc/supervisor.d /app/var/log /app/var/lock /app/var/run/php-fpm"
mkdir -p "$OUTDIR"

apply-template /app/config/php/php-fpm.d /app/etc/php/php-fpm.d

true
