#!/usr/bin/env bash

log "INFO" "Configure Apache ..."

if [[ "${APACHE_ENABLED}" == "true" ]]; then

	OUTDIR="/app/var/cache/apache2/mod_ssl /opt/etc/apache2/conf.d /opt/etc/apache2/sites-enabled /app/var/run/apache2 /app/var/www/html ${APACHE_MONITORING_DOCUMENT_ROOT}"

	# require-writable rather than a bare mkdir: it names the cause when a file
	# mounted under /opt/etc left one of these directories root-owned.
	#
	# A symbolic link is skipped: /app/var/www/html is linked to /var/www/html below,
	# so on a restart that keeps /app/var (an emptyDir survives a container restart)
	# the check would land on the image's directory, read-only on a read-only root.
	for dir in $OUTDIR; do
		[ -L "$dir" ] && continue
		require-writable "$dir" || exit 1
	done

	log "INFO" "- Setup Configuration File(s) ..."

	apply-template /opt/config/apache2 /opt/etc/apache2
	apply-template /opt/config/apache2/conf.d /opt/etc/apache2/conf.d
	apply-template /opt/config/apache2/sites-enabled /opt/etc/apache2/sites-enabled
	apply-template /opt/config/supervisor.d/apache2.ini.tmpl /opt/etc/supervisor.d/apache2.ini

	log "INFO" "- Setup Module(s) ..."

	create-symlink /app/var/www/modules /var/www/modules

	log "INFO" "- Setup base static content ..."

	create-symlink /app/var/www/html /var/www/html

else

	log "INFO" "- Apache is not enabled.  No configuration must be done."

fi

true
