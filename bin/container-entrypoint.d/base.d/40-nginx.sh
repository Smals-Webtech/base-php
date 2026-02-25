#!/usr/bin/env bash

log "INFO" "Configure Nginx ..."

if [[ "${NGINX_ENABLED}" == "true" ]]; then

	OUTDIR="/opt/etc/nginx/conf.d /opt/etc/nginx/sites-enabled /app/var/run/nginx ${NGINX_FASTCGI_CACHE_FOLDER_PATH} ${NGINX_PROXY_TEMP_FOLDER_PATH} ${NGINX_CLIENT_BODY_TEMP_PATH} ${NGINX_SCGI_TEMP_PATH} ${NGINX_FASTCGI_TEMP_FOLDER_PATH} ${NGINX_UWSGI_TEMP_PATH} /app/var/www/html"

	for dir in $OUTDIR; do
		mkdir -p "$dir"
	done

	log "INFO" "- Setup Configuration File(s) ..."

	apply-template /opt/config/nginx /opt/etc/nginx
	apply-template /opt/config/nginx/sites-enabled /opt/etc/nginx/sites-enabled
	apply-template /opt/config/supervisor.d/nginx.ini.tmpl /opt/etc/supervisor.d/nginx.ini

	create-symlink /opt/etc/nginx/fastcgi_params /etc/nginx/fastcgi_params

	if [[ "${NGINX_REAL_IP_ENABLED}" == "true" ]]; then

		for cidr in $NGINX_REAL_IP_TRUSTED_PROXIES; do
			CIDRS+=("$cidr")
		done

		mapfile -t CIDRS_UNIQ < <(
			printf '%s\n' "${CIDRS[@]}" | sort -u
		)

		CIDRS_JSON=$(printf '%s\n' "${CIDRS_UNIQ[@]}" | jq -R . | jq -s -c .)

		export CIDRS_JSON

		gomplate -f /opt/config/nginx/conf.d/fastcgi-cache.map.tmpl \
			-d cidrs=env:/CIDRS_JSON?type=application/json \
			-o /opt/etc/nginx/conf.d/fastcgi-cache.map

		unset CIDRS CIDRS_UNIQ CIDRS_JSON

	fi

	if [[ "${NGINX_FASTCGI_CACHE_ENABLED}" == "true" ]]; then

		for method in $NGINX_FASTCGI_NO_CACHE_METHODS; do
			METHODS+=("$method")
		done

		for cookie in $NGINX_FASTCGI_NO_CACHE_COOKIES; do
			COOKIES+=("$cookie")
		done

		mapfile -t METHODS_UNIQ < <(
			printf '%s\n' "${METHODS[@]}" | sort -u
		)

		mapfile -t COOKIES_UNIQ < <(
			printf '%s\n' "${COOKIES[@]}" | sort -u
		)

		METHODS_JSON=$(printf '%s\n' "${METHODS_UNIQ[@]}" | jq -R . | jq -s -c .)
		COOKIES_JSON=$(printf '%s\n' "${COOKIES_UNIQ[@]}" | jq -R . | jq -s -c .)

		export METHODS_JSON COOKIES_JSON

		gomplate -f /opt/config/nginx/conf.d/fastcgi-cache.map.tmpl \
			-d methods=env:/METHODS_JSON?type=application/json \
			-d cookies=env:/COOKIES_JSON?type=application/json \
			-o /opt/etc/nginx/conf.d/fastcgi-cache.map

		unset METHODS COOKIES METHODS_UNIQ COOKIES_UNIQ METHODS_JSON COOKIES_JSON

	fi

	apply-template /opt/config/nginx/conf.d/logging.conf.tmpl /opt/etc/nginx/conf.d/logging.conf

	log "INFO" "- Setup Module(s) ..."

	create-symlink /app/var/www/modules /usr/lib/nginx/modules

	log "INFO" "- Setup base static content ..."

	create-symlink /app/var/www/html /var/www/html

	if [[ "${NGINX_BASIC_AUTH_ENABLED}" == "true" ]]; then
		log "INFO" "Configure Basic Authentication ..."
		htpasswd -bcB "${NGINX_BASIC_AUTH_FILE_PATH}" "${NGINX_BASIC_AUTH_USERNAME}" "${NGINX_BASIC_AUTH_PASSWORD}"
	fi

else

	log "INFO" "- Nginx is not enabled.  No configuration must be done."

fi

true
