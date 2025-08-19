#!/usr/bin/env bash

log "INFO" "Configure Nginx ..."

if [[ "${NGINX_ENABLED}" == "true" ]]; then

	OUTDIR="/opt/etc/nginx/sites-enabled /app/var/run/nginx /app/var/cache/nginx/fcgi /app/var/tmp/client /app/var/tmp/scgi /app/var/tmp/fastcgi /app/var/tmp/uwsgi /app/var/tmp/scgi /app/var/www/html"

	for dir in $OUTDIR; do
		mkdir -p "$dir"
	done

	log "INFO" "- Setup Configuration File(s) ..."

	apply-template /opt/config/nginx /opt/etc/nginx
	apply-template /opt/config/nginx/sites-enabled /opt/etc/nginx/sites-enabled
	apply-template /opt/config/supervisor.d/nginx.ini.tmpl /opt/etc/supervisor.d/nginx.ini

	log "INFO" "- Setup Module(s) ..."

	create-symlink /app/var/www/modules /usr/lib/nginx/modules

else

	log "INFO" "- Nginx is not enabled.  No configuration must be done."

fi

true
