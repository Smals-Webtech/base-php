#!/usr/bin/env bash

VARNISH_ENABLED_WCMTECH_DEFAULT="false"
VARNISH_STORAGE_MALLOC_SIZE_WCMTECH_DEFAULT="200M"
VARNISH_NCSA_LOG_FORMAT_WCMTECH_DEFAULT="%%h %%l %%u %%t %%D \"%%r\" %%s %%b %%{Varnish:hitmiss}x \"%%{User-agent}i\"" # Supervisord uses the % character for its own format strings in the config file. You can still use the % character but you must escape it like %%.
VARNISH_TTL_WCMTECH_DEFAULT="120"
VARNISH_MIN_THREADS_WCMTECH_DEFAULT="5"
VARNISH_MAX_THREADS_WCMTECH_DEFAULT="1000"
VARNISH_THREAD_TIMEOUT_WCMTECH_DEFAULT="120"
VARNISH_VCL_CONF_WCMTECH_DEFAULT="/opt/etc/varnish/default.vcl"

true
