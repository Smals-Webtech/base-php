#!/usr/bin/env bash

log "INFO" "Running Application configuration script(s) ... ..."

if [ ! -f "/app/var/lock/appinit" ]; then

	for f in /opt/bin/container-entrypoint.d/*; do
		case "$f" in
		*.sh)
			log "INFO" "$0: running $f"
			. "$f"
			;;
		*.php)
			log "INFO" "$0: running $f"
			php -f "$f"
			echo
			;;
		*) log "INFO" "$0: ignoring $f" ;;
		esac
	done

	touch /app/var/lock/appinit

fi

true
