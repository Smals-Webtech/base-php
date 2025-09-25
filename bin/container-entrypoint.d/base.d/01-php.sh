#!/usr/bin/env bash

log "INFO" "Configure PHP ..."

OUTDIR="/opt/etc/php/conf.d"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup PHP Modules Configuration File(s) ..."

read -r -a EXTENSIONS <<<"$PHP_EXT_INSTALL"

for EXT in "${EXTENSIONS[@]}"; do

	VARNAME="PHP_${EXT^^}_ENABLED"

	if [[ -v $VARNAME && "${!VARNAME,,}" == "true" ]]; then

		SRC="/usr/local/etc/php/conf.d/docker-php-ext-${EXT}.ini"
		TGT="/opt/etc/php/conf.d/_docker-php-ext-${EXT}.ini"

		if [ -f "${SRC}" ]; then
			create-symlink "${TGT}" "${SRC}"
		else
			log "WARN" "  The module ${EXT} is installed, but the corresponding .ini configuration file could not be found at ${SRC}."
		fi

	fi

done

apply-template /opt/config/php/conf.d /opt/etc/php/conf.d

true
