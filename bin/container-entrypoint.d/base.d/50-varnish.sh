#!/usr/bin/env bash

log "INFO" "Configure Varnish ..."

if [[ "${VARNISH_ENABLED}" == "true" ]]; then

	log "INFO" "- Setup Varnish Configuration File(s) ..."

	OUTDIR="/opt/etc/supervisor.d /app/var/varnish /app/var/cache/varnish/varnishd /app/var/run/varnish"

	for dir in $OUTDIR; do
		mkdir -p "$dir"
	done

	apply-template /opt/config/supervisor.d/varnish.ini.tmpl /opt/etc/supervisor.d/varnish.ini
	apply-template /opt/config/sbin/start-varnishncsa.tmpl /opt/sbin/start-varnishncsa.sh
	apply-template /opt/config/sbin/start-varnishd.tmpl /opt/sbin/start-varnishd.sh

	chmod +x /opt/sbin/start-varnishncsa.sh /opt/sbin/start-varnishd.sh

	create-symlink /opt/sbin/start-varnishncsa /opt/sbin/start-varnishncsa.sh
	create-symlink /opt/sbin/start-varnishd /opt/sbin/start-varnishd.sh

	log "INFO" "- Create Varnish secret file ..."

	if [[ ! -s /app/var/cache/varnish/secret ]]; then
		dd if=/dev/random of=/app/var/cache/varnish/secret count=1
	fi

else

	log "INFO" "- Varnish is not enabled.  No configuration must be done"

fi

true
