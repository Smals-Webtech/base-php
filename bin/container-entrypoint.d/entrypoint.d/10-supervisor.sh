#!/usr/bin/env bash

SUPERVISOR_XMLRPC_UNIX_SOCKET_ENABLED_WCMTECH_DEFAULT="true"
SUPERVISOR_XMLRPC_UNIX_SOCKET_PATH_WCMTECH_DEFAULT="/app/var/run/supervisor.sock"
SUPERVISOR_XMLRPC_UNIX_SOCKET_CHMOD_WCMTECH_DEFAULT="0700"
SUPERVISOR_XMLRPC_UNIX_SOCKET_AUTH_ENABLED_WCMTECH_DEFAULT="true"
SUPERVISOR_XMLRPC_UNIX_SOCKET_USERNAME_WCMTECH_DEFAULT="admin"
SUPERVISOR_XMLRPC_UNIX_SOCKET_PASSWORD_WCMTECH_DEFAULT="pa55w0rd"

SUPERVISOR_XMLRPC_INET_ENABLED_WCMTECH_DEFAULT="false"
SUPERVISOR_XMLRPC_INET_HOST_WCMTECH_DEFAULT=""
SUPERVISOR_XMLRPC_INET_PORT_WCMTECH_DEFAULT="9744"
SUPERVISOR_XMLRPC_INET_USERNAME_WCMTECH_DEFAULT="admin"
SUPERVISOR_XMLRPC_INET_PASSWORD_WCMTECH_DEFAULT="pa55w0rd"

# Fail-fast: stop supervisord -- and therefore the container -- when one of the
# programs below leaves unexpectedly. They run with autorestart=false, so
# supervisor would otherwise just mark them EXITED and keep the container up,
# with the workers of a killed master still holding the listen sockets and
# answering requests unsupervised. Set to "false" to keep the old behaviour of
# staying up and relying on the health check alone.
SUPERVISOR_FAIL_FAST_ENABLED_WCMTECH_DEFAULT="true"

# Space-separated supervisor program names to watch. Each variant starts only
# some of these, and a program this image never starts is simply never seen, so
# one list covers them all. varnish is deliberately absent: it runs with
# autorestart=true and recovers on its own.
#
# These are supervisor *program* names, which are not always the file name:
# apache2.ini.tmpl declares [program:apache], the same name the healthcheck uses.
SUPERVISOR_FAIL_FAST_PROGRAMS_WCMTECH_DEFAULT="nginx php-fpm apache"

true
