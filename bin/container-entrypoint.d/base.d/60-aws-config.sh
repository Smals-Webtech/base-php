#!/usr/bin/env bash

log "INFO" "Configure AWS CLI ..."

OUTDIR="/opt/etc/aws"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup AWS Configuration File ..."

apply-template /opt/config/aws/config.tmpl /opt/etc/aws/config

# Only render a credentials file when both keys are actually provided. The file
# is written to the persistent /opt/etc volume, so writing it unconditionally
# would (a) leave secrets in cleartext on disk and (b) shadow the default
# credential chain (IAM role, env, ...) with an empty [default] section. When no
# keys are given we remove any stale file left over from a previous run.
if [ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ]; then

	log "INFO" "- Setup AWS Credentials File ..."

	apply-template /opt/config/aws/credentials.tmpl /opt/etc/aws/credentials
	chmod 600 /opt/etc/aws/credentials

else

	log "INFO" "- No AWS credentials provided; relying on the default credential chain (IAM role, env, ...)."

	rm -f /opt/etc/aws/credentials

fi

log "INFO" "- Setup AWS Wrapper Script ..."

apply-template /opt/config/sbin/aws.tmpl /opt/sbin/aws.sh

chmod +x /opt/sbin/aws.sh

create-symlink /opt/sbin/aws /opt/sbin/aws.sh

true
