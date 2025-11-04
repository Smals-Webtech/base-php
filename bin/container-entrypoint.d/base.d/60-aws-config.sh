#!/usr/bin/env bash

log "INFO" "Configure AWS CLI ..."

OUTDIR="/opt/etc/aws"

for dir in $OUTDIR; do
	mkdir -p "$dir"
done

log "INFO" "- Setup AWS Configuration File ..."

apply-template /opt/config/aws/config.tmpl /opt/etc/aws/config

log "INFO" "- Setup AWS Credentials File ..."

apply-template /opt/config/aws/credentials.tmpl /opt/etc/aws/credentials

log "INFO" "- Setup AWS Wrapper Script ..."

apply-template /opt/config/sbin/aws.sh.tmpl /opt/sbin/aws.sh

chmod +x /opt/sbin/aws.sh

create-symlink /opt/sbin/aws /opt/sbin/aws.sh

true
