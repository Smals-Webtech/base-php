#!/usr/bin/env bash

log "INFO" "Configure Apache ..."

if [[ "${APACHE_ENABLED}" == "true" ]]; then

	log "INFO" "- Setup Apache Configuration File(s) ..."

	OUTDIR="/app/var/cache/apache2/mod_ssl /app/etc/apache2/conf.d /app/var/run/apache2"
	mkdir -p "$OUTDIR"

	apply-template /app/config/apache2 /app/etc/apache2
	apply-template /app/config/apache2/conf.d /app/etc/apache2/conf.d

else

	log "INFO" "- Apache is not enabled.  No configuration must be done."

fi

true
