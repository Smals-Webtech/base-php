#!/usr/bin/env bash

log "INFO" "Setup PHP-FPM Pool Configuration File(s) ..."

OUTDIR="/opt/etc/php/php-fpm.d /opt/etc/supervisor.d /app/var/log /app/var/lock /app/var/run/php-fpm"
mkdir -p $OUTDIR

apply-template /opt/config/php/php-fpm.d /opt/etc/php/php-fpm.d
apply-template /opt/config/supervisor.d/php-fpm.ini.tmpl /opt/etc/supervisor.d/php-fpm.ini

true
