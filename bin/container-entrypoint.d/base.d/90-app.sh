#!/usr/bin/env bash

log "INFO" "Running Application configuration script(s) ... ..."

APP_INIT_DIR="/opt/bin/container-entrypoint.d"
APP_INIT_LOCK="/app/var/lock/appinit"
APP_INIT_LOCK_FILE="${APP_INIT_LOCK}.lock"

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

# The marker on its own says whether the hooks have run, not whether they are
# running. Replicas sharing /app/var -- an RWX claim, the usual way sessions and
# uploads are shared -- read it at the same time, all decide the hooks are
# pending, and all run them at once. Measured with two containers on one volume:
# a hook that takes three seconds ran twice.
#
# The lock is held across the check, the run and the write, so a second replica
# waits and then finds the marker already written. flock releases it when the
# process holding it goes away, so a container that dies mid-init does not wedge
# the others.
#
# The lock is a separate file: the marker is read and rewritten, and locking a
# file while truncating it is how this goes wrong.
exec {APP_INIT_LOCK_FD}>"$APP_INIT_LOCK_FILE"

# The flock here is BusyBox's, which takes -s, -x, -u and -n and nothing else --
# no -w, so the bounded wait is a retry around the non-blocking form.
APP_INIT_LOCK_WAITED=0

until flock -n "$APP_INIT_LOCK_FD"; do

	if [ "$APP_INIT_LOCK_WAITED" -ge "$APP_INIT_LOCK_TIMEOUT" ]; then
		log "ERROR" "! Timed out after ${APP_INIT_LOCK_TIMEOUT}s waiting for the application init lock."
		log "ERROR" "! Another container sharing /app/var is still running its init scripts, or one died holding it."
		exit 1
	fi

	[ "$APP_INIT_LOCK_WAITED" -eq 0 ] &&
		log "INFO" "- $0: another container is running the init scripts, waiting for it"

	sleep 1
	APP_INIT_LOCK_WAITED=$((APP_INIT_LOCK_WAITED + 1))

done

# Re-read inside the lock: whoever held it may have just finished the work.
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

else

	log "INFO" "- $0: already applied for these scripts, nothing to run"

fi

exec {APP_INIT_LOCK_FD}>&-

unset APP_INIT_DIR APP_INIT_LOCK APP_INIT_LOCK_FILE APP_INIT_LOCK_FD APP_INIT_LOCK_WAITED APP_INIT_FINGERPRINT

true
