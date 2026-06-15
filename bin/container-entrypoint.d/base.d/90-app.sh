#!/usr/bin/env bash

log "INFO" "Running Application configuration script(s) ... ..."

APP_INIT_DIR="/opt/bin/container-entrypoint.d"
APP_INIT_LOCK="/app/var/lock/appinit"

OUTDIR="/app/var/lock"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

# Fingerprint the app-init scripts (name + content) so that a new image with
# changed init scripts re-runs them even when the persistent /app/var volume is
# reused, while a plain restart with unchanged scripts still runs them only once.
APP_INIT_FINGERPRINT="$(
	find "$APP_INIT_DIR" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.php' \) |
		LC_ALL=C sort |
		xargs -r sha256sum |
		sha256sum |
		cut -d ' ' -f 1
)"

if [ "$(cat "$APP_INIT_LOCK" 2>/dev/null)" != "$APP_INIT_FINGERPRINT" ]; then

	for f in "$APP_INIT_DIR"/*; do
		case "$f" in
		*.sh)
			log "INFO" "- $0: running $f"
			. "$f"
			;;
		*.php)
			log "INFO" "- $0: running $f"
			php -f "$f"
			echo
			;;
		*) log "INFO" "- $0: ignoring $f" ;;
		esac
	done

	printf '%s\n' "$APP_INIT_FINGERPRINT" >"$APP_INIT_LOCK"

fi

unset APP_INIT_DIR APP_INIT_LOCK APP_INIT_FINGERPRINT

true
