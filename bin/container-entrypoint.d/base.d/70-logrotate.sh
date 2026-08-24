#!/usr/bin/env bash

log "INFO" "Configure logrotate ..."

OUTDIR="/opt/etc/logrotate.d"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup Configuration File(s) ..."

apply-template /opt/config/supervisor.d/logrotate.ini.tmpl /opt/etc/supervisor.d/logrotate.ini
apply-template /opt/config/logrotate/logrotate.conf.tmpl /opt/etc/logrotate.conf

for opt in $LOGROTATE_DEFAULT_OPTIONS; do
	OPTIONS+=("$opt")
done

mapfile -t OPTIONS_UNIQ < <(
	printf '%s\n' "${OPTIONS[@]}" | sort -u
)

OPTIONS_JSON=$(printf '%s\n' "${OPTIONS_UNIQ[@]}" | jq -R . | jq -s -c .)

export OPTIONS_JSON

gomplate -f /opt/config/logrotate/logrotate.d/default.conf.tmpl \
	-d options=env:/OPTIONS_JSON?type=application/json \
	-o /opt/etc/logrotate.d/default.conf

unset OPTIONS OPTIONS_UNIQ OPTIONS_JSON

true
