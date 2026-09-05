#!/usr/bin/env bash

log "INFO" "Configure PHP ..."

OUTDIR="/opt/etc/php/conf.d /opt/etc/php/extensions"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup PHP Modules Configuration File(s) ..."

# Ask PHP where its extensions really live, with the scan directory neutralised.
# /opt/etc/php/conf.d is the *output* of this script, and the base-php-core.ini
# it renders sets extension_dir to /opt/etc/php/extensions -- the symlink farm
# built below. Where /opt/etc outlives the container (docker restart reuses the
# anonymous volume behind VOLUME /opt/etc; a persistent claim keeps it across
# pods), a plain probe reads that rendered value back, every source path below
# becomes the farm itself, and each symlink is recreated pointing at itself. PHP
# then loads no dynamic extension at all -- "Symbolic link loop" for each one,
# on stderr only, while the container still starts and serves. Clearing
# PHP_INI_SCAN_DIR keeps php.ini and drops the rendered files, which is exactly
# what this probe sees on a first boot.
EXTENSIONS_DIR=$(PHP_INI_SCAN_DIR='' php -r 'echo ini_get("extension_dir");')

# Everything below is regenerated on every boot, so drop the previous run's
# output first: on a reused /opt/etc, a module taken out of PHP_EXT_ENABLED or a
# template removed from a newer image would otherwise stay loaded for the life
# of the volume. Only image-owned names are removed -- the symlinks this script
# creates and the base-php-*.ini files apply-template renders. Anything an
# application dropped into /opt/etc/php/conf.d is left alone.
find /opt/etc/php/conf.d -maxdepth 1 -type l -name '_docker-php-ext-*.ini' -delete
find /opt/etc/php/extensions -maxdepth 1 -type l -name '*.so' -delete
find /opt/etc/php/conf.d -maxdepth 1 -type f -name 'base-php-*.ini' -delete

IFS=':' read -r -a EXTENSIONS <<<"$PHP_EXT_ENABLED"

for EXT in "${EXTENSIONS[@]}"; do

	VARNAME="PHP_${EXT^^}_ENABLED"

	if [[ -v $VARNAME && "${!VARNAME,,}" == "true" ]]; then

		INI_SRC="/usr/local/etc/php/conf.d/docker-php-ext-${EXT}.ini"
		SO_SRC="${EXTENSIONS_DIR}/${EXT}.so"

		# Neither file present means the extension is compiled into the PHP
		# binary and needs no wiring -- opcache is built in from PHP 8.5, while
		# 8.4 still ships it as a shared module. Reporting that as two warnings
		# on every boot teaches readers to ignore the warnings that do matter.
		if [ ! -f "${INI_SRC}" ] && [ ! -f "${SO_SRC}" ]; then
			log "INFO" "  The module ${EXT} is built into the PHP binary; nothing to link."
			continue
		fi

		if [ -f "${INI_SRC}" ]; then
			create-symlink "/opt/etc/php/conf.d/_docker-php-ext-${EXT}.ini" "${INI_SRC}"
		else
			log "WARN" "  The module ${EXT} is installed, but the corresponding .ini configuration file could not be found at ${INI_SRC}."
		fi

		if [ -f "${SO_SRC}" ]; then
			create-symlink "/opt/etc/php/extensions/${EXT}.so" "${SO_SRC}"
		else
			log "WARN" "  The module ${EXT} is installed, but the corresponding .so configuration file could not be found at ${SO_SRC}."
		fi

	fi

done

apply-template /opt/config/php/conf.d /opt/etc/php/conf.d

true
