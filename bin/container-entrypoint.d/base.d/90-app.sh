#!/usr/bin/env bash

log "INFO" "Running Application configuration script(s) ... ..."

APP_INIT_DIR="/opt/bin/container-entrypoint.d"
APP_INIT_LOCK="/app/var/lock/appinit"
APP_INIT_LOCK_FILE="${APP_INIT_LOCK}.lock"
APP_INIT_FUNCTIONS="/usr/local/bin/container-entrypoint.d/entrypoint.d/00-functions.sh"

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

	# Hooks run as child processes. Sourcing them put them in this shell, which
	# had two consequences worth spelling out. A hook ending in `exit 0` -- a
	# common habit -- terminated the entrypoint before it could exec supervisord,
	# so the container stopped with exit code 0: no error, and restart-on-failure
	# never fired. And a hook shared this script's variables, so assigning
	# APP_INIT_LOCK sent the fingerprint somewhere else and left the real marker
	# unwritten, which re-ran every hook on every start.
	#
	# `bash -e -o pipefail` keeps the strictness sourcing gave them: any failing
	# command in a hook already aborted the boot, and still does. What changes is
	# that the failure is now reported with the hook's name and its exit code.
	for APP_INIT_HOOK in "$APP_INIT_DIR"/*; do

		# An array, not `set --`: this file is sourced, and container-entrypoint
		# reads its own positional parameters after the base.d phase to build the
		# command it execs.
		case "$APP_INIT_HOOK" in
		*.sh) APP_INIT_CMD=(bash -e -o pipefail "$APP_INIT_HOOK") ;;
		*.php) APP_INIT_CMD=(php -f "$APP_INIT_HOOK") ;;
		*)
			log "INFO" "- $0: ignoring $APP_INIT_HOOK"
			continue
			;;
		esac

		log "INFO" "- $0: running $APP_INIT_HOOK"

		# Sourcing used to hand the hooks this shell's functions along with
		# everything else. Running them as children took `log` and its siblings
		# away with the rest, which broke child images that had come to rely on
		# them -- silently, on upgrade, and only at boot.
		#
		# BASH_ENV is read by bash before it runs a non-interactive script, so
		# the child loads the helpers itself: no fork, no `source` line to write
		# in every hook, and $0 stays the hook's own path. The assignment is a
		# command prefix, so it lives only in that command's environment --
		# neither supervisord nor the application ever sees BASH_ENV. `php -f`
		# ignores it.
		#
		# This gives back the functions, not the scope: the hook is still a
		# separate process, so `exit 0` still ends the hook rather than the boot
		# and what it sets still dies with it.
		#
		# CLEANUP_VAR_LIST is the colon-separated list of the variables this image
		# owns -- its php.ini directives, pool settings, extension switches, AWS
		# settings, and whatever a child image declared as a <NAME>_WCMTECH_DEFAULT
		# -- which base.d/99-cleanup-vars.sh unsets before the application starts.
		# Hooks run before that cleanup and still see those variables, so a hook
		# that hands variables to the application on its own -- rendering php-fpm
		# env[] entries, a dotenv file -- needs the list to leave them out, or it
		# brings back what the cleanup removes. Handed over the same way as
		# BASH_ENV: the hook's environment only, never the application's.
		if BASH_ENV="$APP_INIT_FUNCTIONS" CLEANUP_VAR_LIST="$CLEANUP_VAR_LIST" "${APP_INIT_CMD[@]}"; then
			log "INFO" "- $0: $APP_INIT_HOOK done"
		else
			APP_INIT_STATUS=$?
			log "ERROR" "! $APP_INIT_HOOK exited with ${APP_INIT_STATUS}."
			log "ERROR" "! The application init scripts did not complete; refusing to start."
			exit "$APP_INIT_STATUS"
		fi

	done

	printf '%s\n' "$APP_INIT_FINGERPRINT" >"$APP_INIT_LOCK"

else

	log "INFO" "- $0: already applied for these scripts, nothing to run"

fi

exec {APP_INIT_LOCK_FD}>&-

unset APP_INIT_DIR APP_INIT_LOCK APP_INIT_LOCK_FILE APP_INIT_LOCK_FD APP_INIT_LOCK_WAITED APP_INIT_FINGERPRINT
unset APP_INIT_FUNCTIONS
unset APP_INIT_HOOK APP_INIT_CMD APP_INIT_STATUS

true
