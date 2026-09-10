#!/usr/bin/env bash

# Extensions
#
# PHP_EXT_INSTALL is what the image built; PHP_EXT_INSTALL_CUSTOM is what a child
# image added with install-php-extensions in its own Dockerfile. Each name gets a
# PHP_<EXT>_ENABLED switch, and the colon-separated PHP_EXT_ENABLED is what
# base.d/01-php.sh walks to link the extension's .ini into the scan directory.

PHP_EXT_INSTALL_WCMTECH_DEFAULT="${PHP_EXT_INSTALL}"
PHP_EXT_INSTALL_CUSTOM_WCMTECH_DEFAULT="${PHP_EXT_INSTALL_CUSTOM}"

read -r -a EXTENSIONS <<<"$PHP_EXT_INSTALL $PHP_EXT_INSTALL_CUSTOM"
for EXT in "${EXTENSIONS[@]}"; do
	CLEAN_EXT="${EXT%%[-/]*}"
	VARNAME="PHP_${CLEAN_EXT^^}_ENABLED_WCMTECH_DEFAULT"
	eval "$VARNAME=true"

	PHP_EXT_ENABLED="${PHP_EXT_ENABLED:+$PHP_EXT_ENABLED:}$CLEAN_EXT"

done

PHP_EXT_ENABLED_WCMTECH_DEFAULT="${PHP_EXT_ENABLED}"

# php.ini directives
#
# Every directive PHP declares gets an empty default here, which is what makes it
# both overridable and safe: 99-export-vars.sh promotes each name it finds to
# PHP_<NAME> -- the operator's value winning over the empty one -- and registers
# it in CLEANUP_VAR_LIST, which base.d/99-cleanup-vars.sh unsets just before
# supervisord is exec'd. A directive with no declaration here would still be
# rendered, since the renderer reads the environment either way, but its variable
# would reach the application.
#
# The list is generated at build from ini_get_all() (see the Dockerfile), so it
# follows the PHP version and the installed extensions instead of being kept by
# hand. Reading it costs no process; the probe it replaced cost one `php` and
# about 30 ms.
#
# Nothing is rendered from an empty value: php.ini carries the defaults, and only
# what the operator actually sets is written. The exceptions are the eight
# directives below, where this image deliberately departs from PHP.

PHP_INI_DIRECTIVES_FILE="/usr/local/share/base-php/ini-directives.list"

if [ ! -r "$PHP_INI_DIRECTIVES_FILE" ]; then
	log "ERROR" "! ${PHP_INI_DIRECTIVES_FILE} is missing or unreadable."
	log "ERROR" "! No php.ini directive would be configurable, and none would be cleaned from the application environment."
	exit 1
fi

mapfile -t PHP_INI_DIRECTIVES <"$PHP_INI_DIRECTIVES_FILE"

# Directive -> variable, and the reverse, both used below and by base.d/01-php.sh.
# The rule is mechanical -- upper case, '.' becomes '_' -- and reproduces every
# name the hand-written map used to declare, so nothing is renamed.
declare -A PHP_INI_VAR_OF=()

for PHP_INI_DIRECTIVE in "${PHP_INI_DIRECTIVES[@]}"; do

	[ -n "$PHP_INI_DIRECTIVE" ] || continue

	PHP_INI_VAR="PHP_${PHP_INI_DIRECTIVE^^}"
	PHP_INI_VAR="${PHP_INI_VAR//./_}"

	PHP_INI_VAR_OF["$PHP_INI_DIRECTIVE"]="$PHP_INI_VAR"
	printf -v "${PHP_INI_VAR}_WCMTECH_DEFAULT" '%s' ''

done

# Where this image departs from PHP, and why. Everything else takes the value of
# php.ini-production or php.ini-development, which is what the image ships.

PHP_EXPOSE_PHP_WCMTECH_DEFAULT="Off"                          # hardening
PHP_FASTCGI_LOGGING_WCMTECH_DEFAULT="Off"                     # docker-library/php#1360
PHP_DATE_TIMEZONE_WCMTECH_DEFAULT="Europe/Brussels"           # business default
PHP_SOAP_WSDL_CACHE_DIR_WCMTECH_DEFAULT="/app/tmp"            # the writable runtime dir
PHP_XDEBUG_OUTPUT_DIR_WCMTECH_DEFAULT="/app/tmp"              # idem
PHP_XDEBUG_CLIENT_HOST_WCMTECH_DEFAULT="host.docker.internal" # reach the host from a container
PHP_XDEBUG_MODE_WCMTECH_DEFAULT="${XDEBUG_MODE:-off}"         # xdebug's own keyword for "no mode"
PHP_XDEBUG_START_WITH_REQUEST_WCMTECH_DEFAULT="yes"           # once a mode is set, use it

# Installed in every variant, off unless asked for: both cost real time per
# request, and the auto-instrumentation package warns at autoload when the
# extension is absent, which lands in the response body of a dev image.

PHP_OPENTELEMETRY_ENABLED_WCMTECH_DEFAULT="false"
PHP_XDEBUG_ENABLED_WCMTECH_DEFAULT="false"

# A directive named <ext>.enabled would derive the same variable as the switch of
# an extension called <ext>, and the switch would silently win. Nothing collides
# today -- apcu declares apc.*, and session.upload_progress.enabled belongs to no
# extension -- but a child image installing such an extension deserves to be told
# rather than to debug it.

for EXT in "${EXTENSIONS[@]}"; do

	CLEAN_EXT="${EXT%%[-/]*}"
	VARNAME="PHP_${CLEAN_EXT^^}_ENABLED"

	if [ -n "${PHP_INI_VAR_OF[${CLEAN_EXT}.enabled]:-}" ]; then
		log "WARN" "! ${VARNAME} is both the switch of extension ${CLEAN_EXT} and the variable of directive ${CLEAN_EXT}.enabled."
		log "WARN" "! The switch wins; set ${CLEAN_EXT}.enabled through a template in /opt/config/php/conf.d instead."
	fi

done

# Kept for backward compatibility, and inert: the semaphore existed because the
# startup probe was slow, and the probe is gone.
if [ -n "${PHP_BYPASS_INI_DEFAULT_VALUES}" ]; then
	log "WARN" "PHP_BYPASS_INI_DEFAULT_VALUES is deprecated and ignored; php.ini now carries the defaults directly."
fi

unset EXTENSIONS EXT CLEAN_EXT VARNAME
unset PHP_INI_DIRECTIVE PHP_INI_VAR

true
