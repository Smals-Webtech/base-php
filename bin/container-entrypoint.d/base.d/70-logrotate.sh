#!/usr/bin/env bash

log "INFO" "Configure logrotate ..."

OUTDIR="/opt/etc/logrotate.d"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup Configuration File(s) ..."

apply-template /opt/config/supervisor.d/logrotate.ini.tmpl /opt/etc/supervisor.d/logrotate.ini
apply-template /opt/config/logrotate/logrotate.conf.tmpl /opt/etc/logrotate.conf

# LOGROTATE_DEFAULT_OPTIONS holds logrotate directives, and a directive may take
# an argument -- "maxage 7", "olddir /app/var/log/old", "dateformat -%Y%m%d". The
# list is therefore split on ';' or a newline, never on whitespace, which would
# tear "maxage 7" into two lines that logrotate rejects.
#
# A value containing neither separator keeps the historical whitespace split.
# That is exactly the set of values that could ever have worked: argument-less
# directives only.
if [[ "$LOGROTATE_DEFAULT_OPTIONS" == *";"* || "$LOGROTATE_DEFAULT_OPTIONS" == *$'\n'* ]]; then
	mapfile -t OPTIONS < <(printf '%s' "$LOGROTATE_DEFAULT_OPTIONS" | tr ';' '\n')
else
	read -r -a OPTIONS <<<"$LOGROTATE_DEFAULT_OPTIONS"
fi

# Trim, drop the empties a trailing separator leaves behind, and deduplicate
# without reordering: logrotate reads directives in order and a later one
# overrides an earlier one, so sorting them changes what the stanza means.
mapfile -t OPTIONS_UNIQ < <(
	printf '%s\n' "${OPTIONS[@]}" |
		sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
		awk 'NF && !seen[$0]++'
)

OPTIONS_JSON=$(printf '%s\n' "${OPTIONS_UNIQ[@]}" | jq -R . | jq -s -c .)

export OPTIONS_JSON

gomplate -f /opt/config/logrotate/logrotate.d/default.conf.tmpl \
	-d options=env:/OPTIONS_JSON?type=application/json \
	-o /opt/etc/logrotate.d/default.conf

unset OPTIONS OPTIONS_UNIQ OPTIONS_JSON

# A directive logrotate rejects makes it skip the whole stanza, so no file is
# rotated at all -- and the only trace is a line in the event listener's output
# once a minute, buried in the tick noise. The volume then fills until the pod is
# evicted. Fail here instead, while someone is looking.
if ! LOGROTATE_CHECK="$(logrotate --debug --state /app/var/run/logrotate.status /opt/etc/logrotate.conf 2>&1)"; then
	log "ERROR" "! The rendered logrotate configuration is invalid:"
	printf '%s\n' "$LOGROTATE_CHECK" >&2
	log "ERROR" "! Check LOGROTATE_DEFAULT_OPTIONS -- directives are separated by ';', arguments stay with their directive."
	return 1
fi

unset LOGROTATE_CHECK

true
