#!/usr/bin/env bash

APACHE_ENABLED_WCMTECH_DEFAULT="false"

APACHE_SERVER_TOKENS_WCMTECH_DEFAULT="Prod"
APACHE_LISTEN_WCMTECH_DEFAULT="9000"

# The monitoring endpoints live on their own port, the way the nginx variant
# already serves them. On the application port they sat behind the same route
# as the site, and the CIDR allow-list could not help: what it saw was the
# router's address, which is private and therefore allowed. Publish only the
# application port and the endpoints are simply not reachable from outside.
APACHE_MONITORING_LISTEN_WCMTECH_DEFAULT="9090"

# An empty directory: the monitoring vhost must not inherit the application
# document root, or it would serve the site on this port too.
APACHE_MONITORING_DOCUMENT_ROOT_WCMTECH_DEFAULT="/app/var/www/monitoring"

APACHE_SERVER_ROOT_WCMTECH_DEFAULT="/app/var/www"
APACHE_SERVER_ADMIN_WCMTECH_DEFAULT="you@example.com"
APACHE_SERVER_NAME_WCMTECH_DEFAULT="default.localhost"

# Off to match ServerTokens Prod above: the signature puts the server version
# and port in the footer of every error page.
APACHE_SERVER_SIGNATURE_WCMTECH_DEFAULT="Off"

APACHE_TIMEOUT_WCMTECH_DEFAULT="60"
APACHE_KEEP_ALIVE_WCMTECH_DEFAULT="On"
APACHE_MAX_KEEP_ALIVE_REQUESTS_WCMTECH_DEFAULT="100"
APACHE_KEEP_ALIVE_TIMEOUT_WCMTECH_DEFAULT="5"
APACHE_USE_CANONICAL_NAME_WCMTECH_DEFAULT="Off"
APACHE_ACCESS_FILE_NAME_WCMTECH_DEFAULT=".htaccess"
APACHE_HOSTNAME_LOOKUPS_WCMTECH_DEFAULT="Off"

APACHE_MPM_WORKER_START_SERVERS_WCMTECH_DEFAULT="3"
APACHE_MPM_WORKER_MIN_SPARE_THREADS_WCMTECH_DEFAULT="75"
APACHE_MPM_WORKER_MAX_SPARE_THREADS_WCMTECH_DEFAULT="250"
APACHE_MPM_WORKER_THREADS_PER_CHILD_WCMTECH_DEFAULT="25"
APACHE_MPM_WORKER_MAX_REQUEST_WORKERS_WCMTECH_DEFAULT="400"
APACHE_MPM_WORKER_MAX_CONNECTIONS_PER_CHILD_WCMTECH_DEFAULT="0"
APACHE_MPM_WORKER_MAX_MEM_FREE_WCMTECH_DEFAULT="2048"

# A vhost-level ErrorLog or CustomLog replaces the server-level one rather than
# adding to it, so pointing these at /dev/null discarded the traffic of the only
# vhost the image ships -- including its 4xx and 5xx, and the PHP errors
# mod_proxy_fcgi relays. DEBUG changes the level and the daemon log below, not
# whether anything is logged at all.
APACHE_DEFAULT_VHOST_ERROR_LOG_TARGET_WCMTECH_DEFAULT="/dev/stderr"
APACHE_DEFAULT_VHOST_CUSTOM_LOG_TARGET_WCMTECH_DEFAULT="/dev/stdout"

APACHE_DEFAULT_VHOST_EXTENDED_STATUS_WCMTECH_DEFAULT="On"

APACHE_DAEMON_LOG_WCMTECH_DEFAULT="info"

[[ "${DEBUG}" == "true" ]] && APACHE_DAEMON_LOG_WCMTECH_DEFAULT="debug"

APACHE_LOG_FORMAT_COMBINED_WCMTECH_DEFAULT="%h %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\""
APACHE_LOG_FORMAT_COMMON_WCMTECH_DEFAULT="%h %l %u %t \\\"%r\\\" %>s %b"

# TLS settings for a vhost this image does not open itself -- nothing here
# listens on 443. They are configured anyway because the image can be used as a
# reverse proxy, and in that case the defaults applied: "all -SSLv3" still
# permits TLSv1 and TLSv1.1, and the MEDIUM cipher class pulls in suites nobody
# wants any more. Both are knobs, so a deployment that has to talk to a legacy
# peer can widen them deliberately rather than inherit the width by accident.
APACHE_SSL_PROTOCOL_WCMTECH_DEFAULT="all -SSLv3 -TLSv1 -TLSv1.1"
APACHE_SSL_CIPHER_SUITE_WCMTECH_DEFAULT="HIGH:!aNULL:!MD5:!RC4:!3DES"

true
