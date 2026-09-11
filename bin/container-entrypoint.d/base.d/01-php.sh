#!/usr/bin/env bash

log "INFO" "Configure PHP ..."

mkdir -p /opt/etc/php/conf.d

log "INFO" "- Setup PHP Modules Configuration File(s) ..."

# Everything below is regenerated on every boot, so drop the previous run's
# output first: on a reused /opt/etc, a module taken out of PHP_EXT_ENABLED or a
# directive removed from the environment would otherwise stay in force for the
# life of the volume. Only image-owned names are removed -- the symlinks this
# script creates and the base-php-*.ini files it writes. Anything an application
# dropped into /opt/etc/php/conf.d is left alone.
find /opt/etc/php/conf.d -maxdepth 1 -type l -name '_docker-php-ext-*.ini' -delete
find /opt/etc/php/conf.d -maxdepth 1 -type f -name 'base-php-*.ini' -delete

# The one directory PHP was built with. Globbed rather than probed: `php -r` here
# would cost a process, and asking PHP for extension_dir is what #69 was about --
# it is a directive, so it reads back whatever the previous boot rendered. This
# is only used to tell "built into the binary" from "installed but broken" in the
# message below; the extensions themselves load through PHP's own extension_dir.
EXTENSIONS_DIR=(/usr/local/lib/php/extensions/*/)

IFS=':' read -r -a EXTENSIONS <<<"$PHP_EXT_ENABLED"

for EXT in "${EXTENSIONS[@]}"; do

	VARNAME="PHP_${EXT^^}_ENABLED"

	if [[ -v $VARNAME && "${!VARNAME,,}" == "true" ]]; then

		INI_SRC="/usr/local/etc/php/conf.d/docker-php-ext-${EXT}.ini"

		# Linking the .ini into the scan directory is what loads the extension,
		# and not linking it is what PHP_<EXT>_ENABLED=false means. The .ini
		# names the module as `extension=<ext>.so`, resolved by PHP against its
		# own extension_dir, so there is nothing else to wire.
		if [ -f "${INI_SRC}" ]; then
			create-symlink "/opt/etc/php/conf.d/_docker-php-ext-${EXT}.ini" "${INI_SRC}"
		elif [ -f "${EXTENSIONS_DIR[0]}${EXT}.so" ]; then
			log "WARN" "  The module ${EXT} is installed, but ${INI_SRC} is missing, so it cannot be loaded."
		else
			# Neither file present means the extension is compiled into the PHP
			# binary and needs no wiring -- opcache is built in from PHP 8.5,
			# while 8.4 still ships it as a shared module. Reporting that as a
			# warning on every boot teaches readers to ignore the ones that matter.
			log "INFO" "  The module ${EXT} is built into the PHP binary; nothing to link."
		fi

	fi

done

log "INFO" "- Rendering PHP configuration file(s) ..."

# Only what the operator actually set is written; php.ini carries the rest. The
# nine directives where this image departs from PHP are set as defaults in
# entrypoint.d/01-php.sh and therefore land here like any other value.
#
# Values are quoted, because unquoted PHP reads `yes`, `no`, `on`, `off`, `true`,
# `false` and `none` as booleans and a string directive set to one of them loses
# its value. Two kinds of value have to stay bare instead:
#
#  - a boolean keyword. A boolean directive is read back through ini_get, and a
#    quoted "Off" is a non-empty string: `ini_get("expose_php")` would answer
#    truthy while the header it controls stays hidden. Bare is also what php.ini
#    itself writes. The string directives that take such a keyword are unharmed:
#    measured on xdebug.start_with_request, which receives the resulting `1` and
#    reports it back as `yes`.
#  - a constant expression. Quoted, `error_reporting = "E_ALL & ~E_DEPRECATED"`
#    is a string, and PHP evaluates it to 0.
#
# The file a directive lands in follows its prefix, so the layout is the one the
# templates produced: base-php-core.ini, plus base-php-ext-<extension>.ini for a
# prefix that names an enabled extension.
declare -A PHP_INI_FILE_OF=()

for EXT in "${EXTENSIONS[@]}"; do
	PHP_INI_FILE_OF["$EXT"]="base-php-ext-${EXT}.ini"
done

# apcu is the extension; its directives are apc.*.
[ -n "${PHP_INI_FILE_OF[apcu]:-}" ] && PHP_INI_FILE_OF[apc]="${PHP_INI_FILE_OF[apcu]}"

declare -A PHP_INI_CONTENT=()

# PHP_INI_DIRECTIVES and PHP_INI_VAR_OF are built by entrypoint.d/01-php.sh, in
# this same shell: both phases are sourced by the entrypoint, the way
# PHP_EXT_ENABLED already crosses from one to the other.
# shellcheck disable=SC2153  # not a misspelling of PHP_INI_DIRECTIVE
for PHP_INI_DIRECTIVE in "${PHP_INI_DIRECTIVES[@]}"; do

	[ -n "$PHP_INI_DIRECTIVE" ] || continue

	PHP_INI_VAR="${PHP_INI_VAR_OF[$PHP_INI_DIRECTIVE]}"
	PHP_INI_VALUE="${!PHP_INI_VAR}"

	[ -n "$PHP_INI_VALUE" ] || continue

	PHP_INI_PREFIX="${PHP_INI_DIRECTIVE%%.*}"
	PHP_INI_FILE="base-php-core.ini"

	[ "$PHP_INI_PREFIX" != "$PHP_INI_DIRECTIVE" ] &&
		PHP_INI_FILE="${PHP_INI_FILE_OF[$PHP_INI_PREFIX]:-base-php-core.ini}"

	PHP_INI_QUOTE='"'

	case "${PHP_INI_VALUE,,}" in
	on | off | true | false | yes | no | none) PHP_INI_QUOTE='' ;;
	esac

	case "$PHP_INI_VALUE" in
	*[\&\|~]* | E_*) PHP_INI_QUOTE='' ;;
	esac

	PHP_INI_CONTENT["$PHP_INI_FILE"]+="${PHP_INI_DIRECTIVE} = ${PHP_INI_QUOTE}${PHP_INI_VALUE}${PHP_INI_QUOTE}"$'\n'

done

for PHP_INI_FILE in "${!PHP_INI_CONTENT[@]}"; do

	{
		printf '%s\n' \
			"; Written by the base-php entrypoint from the environment, at every boot." \
			"; Set the matching PHP_* variable instead of editing this file." \
			""
		printf '%s' "${PHP_INI_CONTENT[$PHP_INI_FILE]}"
	} >"/opt/etc/php/conf.d/${PHP_INI_FILE}"

	log "INFO" "  Rendered: /opt/etc/php/conf.d/${PHP_INI_FILE}"

done

# The operator's own templates, rendered after the generated files. A scan
# directory is read in alphabetical order, so a template named to sort after
# `base-php-` -- `zz-myapp.ini.tmpl`, say -- overrides what this script wrote.
apply-template /opt/config/php/conf.d /opt/etc/php/conf.d

unset EXTENSIONS EXTENSIONS_DIR EXT VARNAME INI_SRC
unset PHP_INI_DIRECTIVES PHP_INI_VAR_OF PHP_INI_FILE_OF PHP_INI_CONTENT
unset PHP_INI_DIRECTIVE PHP_INI_VAR PHP_INI_VALUE PHP_INI_PREFIX PHP_INI_FILE PHP_INI_QUOTE

true
