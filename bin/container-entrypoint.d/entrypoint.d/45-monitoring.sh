#!/usr/bin/env bash

# Access control for the monitoring/status endpoints exposed over HTTP by the
# web server: php-fpm /status & /ping, nginx /metrics /stub-status /vts-status
# /real-time-status, apache /server-status /server-info /status.
#
# Space-separated allow-list of CIDRs allowed to reach them over TCP. Defaults
# to loopback + RFC1918/ULA private ranges, so the endpoints are no longer open
# to the world but typical in-cluster / overlay scrapers keep working.
#
# Unix-socket access stays allowed regardless (it is already a private,
# host-local channel — e.g. an OpenShift sidecar reading the socket on a shared
# emptyDir). Set MONITORING_ALLOW="0.0.0.0/0 ::/0" to restore the previous
# fully-open behaviour, or to a narrower list to lock things down further.
MONITORING_ALLOW_WCMTECH_DEFAULT="127.0.0.1/32 ::1/128 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 fc00::/7"

true
