#!/usr/bin/env bash

# A PHP_* variable the image does not recognise is ignored in silence today.
# Nothing renders it, and -- the part that matters -- nothing cleans it: it
# reaches the application, while every recognised one is unset just before
# supervisord is exec'd. A typo in a directive name therefore fails twice, quietly.
#
# "Recognised" needs no list of its own. Everything this image accepts is declared
# as <NAME>_WCMTECH_DEFAULT by one of the files sourced before this one: the ini
# directives from the generated list, the php-fpm pool settings, the extension
# switches. What remains is either one of PHP's own build-time variables, which the
# image inherits and must leave alone, or a mistake.
#
# Sourced after 90-app.sh, so a variable an early hook declares counts as known.

PHP_PASSTHROUGH_VARS=" PHP_ASC_URL PHP_BYPASS_INI_DEFAULT_VALUES PHP_CFLAGS PHP_CPPFLAGS PHP_INI_DIR PHP_INI_SCAN_DIR PHP_LDFLAGS PHP_SHA256 PHP_URL PHP_VERSION "

PHP_UNKNOWN_VARS=()

mapfile -t PHP_EXPORTED_VARS < <(compgen -e PHP_ | sort)

for VAR in "${PHP_EXPORTED_VARS[@]}"; do

	[ -v "${VAR}_WCMTECH_DEFAULT" ] && continue

	case "$PHP_PASSTHROUGH_VARS" in
	*" $VAR "*) continue ;;
	esac

	PHP_UNKNOWN_VARS+=("$VAR")

done

if [ ${#PHP_UNKNOWN_VARS[@]} -gt 0 ]; then
	log "INFO" "- ${#PHP_UNKNOWN_VARS[@]} PHP_* variable(s) match no php.ini directive, no pool setting and no extension: ${PHP_UNKNOWN_VARS[*]}"
	log "INFO" "- They are ignored by the entrypoint, and they are not removed from the application environment."
fi

unset PHP_PASSTHROUGH_VARS PHP_UNKNOWN_VARS PHP_EXPORTED_VARS VAR

true
