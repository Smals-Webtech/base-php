#!/usr/bin/env bash

LOGROTATE_DEFAULT_PATH_WCMTECH_DEFAULT="/app/var/log/*.log"
LOGROTATE_DEFAULT_SIZE_LIMIT_WCMTECH_DEFAULT="50M"
LOGROTATE_DEFAULT_RETENTION_WCMTECH_DEFAULT="5"

# Semicolon-separated, which is the form that survives a directive taking an
# argument. The whitespace form still parses -- these four take none -- but the
# default is what people copy and extend, so it has to show the separator that
# keeps "maxage 7" in one piece.
LOGROTATE_DEFAULT_OPTIONS_WCMTECH_DEFAULT="compress;copytruncate;missingok;notifempty"

true
