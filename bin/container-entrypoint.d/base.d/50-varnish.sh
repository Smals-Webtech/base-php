#!/usr/bin/env bash

log "INFO" "Configure Varnish ..."

if [[ "${VARNISH_ENABLED}" == "true" ]]; then

	log "INFO" "- Setup Varnish Configuration File(s) ..."

	OUTDIR="/opt/etc/supervisor.d /app/var/varnish /app/var/cache/varnish/varnishd /app/var/run/varnish"

	for dir in $OUTDIR; do
		mkdir -p "$dir"
	done

	apply-template /opt/config/supervisor.d/varnish.ini.tmpl /opt/etc/supervisor.d/varnish.ini

	# The start scripts are rendered by 45-sbin.sh, which now applies every
	# template in /opt/config/sbin and makes the result executable. It produces
	# /opt/sbin/start-varnishd and /opt/sbin/start-varnishncsa directly -- the
	# names varnish.ini invokes -- so the .sh copies and the symlinks that used
	# to bridge the two are gone.

	log "INFO" "- Create Varnish secret file ..."

	if [[ ! -s /app/var/cache/varnish/secret ]]; then
		dd if=/dev/random of=/app/var/cache/varnish/secret count=1
	fi

else

	log "INFO" "- Varnish is not enabled.  No configuration must be done"

fi

true
