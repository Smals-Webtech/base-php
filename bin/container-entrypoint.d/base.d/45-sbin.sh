#!/usr/bin/env bash

log "INFO" "Configure runtime scripts ..."

# /opt/config/sbin holds script templates, /opt/sbin the rendered executables.
# This is the extension point of the image: mount a .tmpl there -- from a child
# image or a compose file -- and it is rendered with the resolved environment and
# made executable, exactly like the scripts the image ships itself. Nothing wired
# it up until now; the two varnish scripts were rendered by name, so anything an
# operator added was ignored.
mkdir -p /opt/sbin

apply-template /opt/config/sbin /opt/sbin

# The directory form of apply-template does not set the execute bit, and these
# are scripts: supervisor execve's them directly.
for f in /opt/sbin/*; do
	[ -f "$f" ] && chmod +x "$f"
done

true
