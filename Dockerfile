# syntax=docker/dockerfile:1.15
ARG ALPINE_VERSION_ARG=3.22
ARG PHP_VERSION_ARG=8.4.12
ARG PHP_EXT_INSTALLER_VERSION_ARG=2.9.6
ARG NODE_VERSION_ARG=22
ARG COMPOSER_VERSION_ARG=2.8.10
ARG GOMPLATE_VERSION_ARG=4.3.3
ARG WAIT4X_VERSION_ARG=3.5.0

FROM mlocati/php-extension-installer:${PHP_EXT_INSTALLER_VERSION_ARG} AS php-ext-installer
FROM hairyhenderson/gomplate:v${GOMPLATE_VERSION_ARG}-alpine AS gomplate
FROM wait4x/wait4x:${WAIT4X_VERSION_ARG} AS wait-for-it
FROM node:${NODE_VERSION_ARG}-alpine${ALPINE_VERSION_ARG} AS node

FROM alpine:${ALPINE_VERSION_ARG} AS builder

USER root

COPY config/ /rootfs/opt/config
COPY bin/ /rootfs/usr/local/bin

RUN mkdir -p /rootfs/opt/bin/container-entrypoint.d \
             /rootfs/opt/sbin \
             /rootfs/opt/etc \
             /rootfs/app/var/lock \
             /rootfs/app/var/log \
             /rootfs/app/var/www \
             /rootfs/app/var/run/varnish \
             /rootfs/app/var/run/php-fpm \
             /rootfs/app/var/run/apache2 \
             /rootfs/app/var/run/nginx \
             /rootfs/app/var/cache/apache2/mod_ssl \
             /rootfs/app/var/cache/varnish/varnishd \
             /rootfs/app/var/cache/nginx/fcgi \
             /rootfs/app/src \
             /rootfs/app/tmp \
             /rootfs/app/var/tmp/client \
             /rootfs/app/var/tmp/scgi \
             /rootfs/app/var/tmp/fastcgi \
             /rootfs/app/var/tmp/uwsgi \
             /rootfs/app/var/tmp/scgi  ; \
    touch /rootfs/app/var/log/supervisord.log \
          /rootfs/app/var/run/supervisord.pid \
          /rootfs/app/var/cache/varnish/secret ;

#
# PHP-FPM / PRD
#

FROM php:${PHP_VERSION_ARG}-fpm-alpine3.22 AS fpm-prd

ARG AWS_CLI_VERSION_ARG=2.27.25

USER root

ENV PHP_EXT_INSTALL="apcu bcmath bz2 calendar exif gd gettext intl ldap mysqli opcache opentelemetry pcntl pdo_mysql pdo_pgsql pgsql redis soap sodium tidy xdebug xsl zip"

COPY --from=php-ext-installer --chmod=775 --chown=root:root /usr/bin/install-php-extensions /usr/local/bin/install-php-extensions
COPY --from=wait-for-it --chmod=775 --chown=root:root /usr/bin/wait4x /usr/bin/wait4x
COPY --from=gomplate --chmod=775 --chown=root:root /bin/gomplate /usr/bin/gomplate

RUN set -eux ; \
    mkdir -p /home/default ; \
    echo "include=/opt/etc/php/php-fpm.d/*.conf" >> /usr/local/etc/php-fpm.conf ; \
    apk add --update --upgrade --no-cache --virtual .base-php-rundeps tzdata bash gettext ssmtp \
                                      postgresql-client postgresql-libs mailx coreutils mysql-client \
                                      jq groff supervisor varnish dumb-init aws-cli=~${AWS_CLI_VERSION_ARG} ; \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" ; \
    cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime ; \
    echo "Europe/Brussels" > /etc/timezone ; \
    adduser -D -u 1001 -g default -G root -s /sbin/nologin default ; \
    rm -rf /var/cache/apk/*

RUN install-php-extensions ${PHP_EXT_INSTALL}

COPY --from=builder --chmod=777 --chown=1001:0 /rootfs/opt/ /opt/
COPY --from=builder --chmod=777 --chown=1001:0 /rootfs/app/ /app/
COPY --from=builder --chmod=775 --chown=root:root /rootfs/usr/local/bin/ /usr/local/bin/

ENV PYTHONWARNINGS="ignore" \
    PHP_INI_SCAN_DIR="/opt/etc/php/conf.d" \
    HOME=/home/default \
    TMPDIR=/app/tmp \
    PATH=/opt/bin:/opt/sbin:/usr/local/bin:/usr/bin:$PATH

WORKDIR /app

VOLUME /opt/sbin
VOLUME /opt/etc
VOLUME /app/var
VOLUME /app/tmp

USER 1001

ENTRYPOINT ["dumb-init","--","container-entrypoint"]

EXPOSE 6081/tcp 6082/tcp

HEALTHCHECK --start-period=2s --interval=30s --timeout=5s --retries=3 \
  CMD supervisorctl -c /opt/etc/supervisord.conf status php-fpm | \
      grep -q 'RUNNING' || exit 1

CMD ["/usr/bin/supervisord", "-c", "/opt/etc/supervisord.conf"]

#
# PHP-FPM / DEV
#

FROM fpm-prd AS fpm-dev

ARG COMPOSER_VERSION_ARG=2.8.10
ARG NODE_VERSION_ARG=22

ENV PHP_XDEBUG_ENABLED="true"

LABEL be.smals.webtech.base.node-version="${NODE_VERSION_ARG}" \
      be.smals.webtech.base.composer-version="${COMPOSER_VERSION_ARG}"

USER root

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN install-php-extensions @composer-${COMPOSER_VERSION_ARG} ; \
    apk add --no-cache --virtual .base-php-dev-rundeps git patch ; \
    cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" ; \
    mkdir /home/default/.composer ; \
    chown 1001:0 /home/default/.composer ; \
    chmod -R ugo+rw /home/default/.composer ; \
    rm -rf /var/cache/apk/* ;

EXPOSE 9003/tcp

USER 1001

#
# APACHE / PRD
#

FROM fpm-prd AS apache-prd

USER root

ENV APACHE_ENABLED=true

COPY --chmod=755 --chown=1001:0 src/ /var/www/html/

RUN apk add --update --no-cache --virtual .base-php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl ; \
    adduser default apache ; \
    rm -rf /var/cache/apk/*

USER 1001

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

#
# APACHE / DEV
#

FROM fpm-dev AS apache-dev

USER root

ENV APACHE_ENABLED=true

COPY --chmod=755 --chown=1001:0 src/ /var/www/html/

RUN apk add --update --no-cache --virtual .base-php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl ; \
    adduser default apache ; \
    rm -rf /var/cache/apk/*

USER 1001

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

#
# NGINX / PRD
#

FROM fpm-prd AS nginx-prd

USER root

ENV NGINX_ENABLED=true

COPY --chmod=755 --chown=1001:0 src/ /var/www/html/

RUN apk add --update --no-cache --virtual .base-php-nginx-rundeps nginx nginx-mod-http-headers-more nginx-mod-http-vts ; \
    adduser default nginx ; \
    rm -rf /var/cache/apk/*

USER 1001

EXPOSE 9090/tcp

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

#
# NGINX / DEV
#

FROM fpm-dev AS nginx-dev

USER root

ENV NGINX_ENABLED=true

COPY --chmod=755 --chown=1001:0 src/ /var/www/html/

RUN apk add --update --no-cache --virtual .base-php-nginx-rundeps nginx nginx-mod-http-headers-more nginx-mod-http-vts ; \
    adduser default nginx ; \
    rm -rf /var/cache/apk/*

USER 1001

EXPOSE 9090/tcp

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

#
# PHP-CLI / PRD
#

FROM php:${PHP_VERSION_ARG}-cli-alpine3.22 AS cli-prd

ARG AWS_CLI_VERSION_ARG=2.27.25

USER root

ENV PHP_EXT_INSTALL="apcu bcmath bz2 calendar exif gd gettext intl ldap mysqli opcache opentelemetry pcntl pdo_mysql pdo_pgsql pgsql redis soap sodium tidy xdebug xsl zip"

COPY --from=php-ext-installer --chmod=775 --chown=root:root /usr/bin/install-php-extensions /usr/local/bin/install-php-extensions
COPY --from=wait-for-it --chmod=775 --chown=root:root /usr/bin/wait4x /usr/bin/wait4x
COPY --from=gomplate --chmod=775 --chown=root:root /bin/gomplate /usr/bin/gomplate

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN set eux; \
    mkdir -p /home/default ; \
    apk add --update --upgrade --no-cache --virtual .base-php-rundeps tzdata bash gettext ssmtp \
                                      postgresql-client postgresql-libs mailx coreutils mysql-client \
                                      jq groff supervisor varnish dumb-init aws-cli=~${AWS_CLI_VERSION_ARG} ; \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" ; \
    cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime ; \
    echo "Europe/Brussels" > /etc/timezone ; \
    adduser -D -u 1001 -g default -G root -s /sbin/nologin default ; \
    rm -rf /var/cache/apk/*

RUN install-php-extensions ${PHP_EXT_INSTALL}

COPY --from=builder --chmod=777 --chown=1001:0 /rootfs/opt/ /opt/
COPY --from=builder --chmod=777 --chown=1001:0 /rootfs/app/ /app/
COPY --from=builder --chmod=775 --chown=root:root /rootfs/usr/local/bin/ /usr/local/bin/

ENV PYTHONWARNINGS="ignore" \
    PHP_INI_SCAN_DIR="/opt/etc/php/conf.d" \
    HOME=/home/default \
    TMPDIR=/app/tmp \
    PATH=/opt/bin:/opt/sbin:/usr/local/bin:/usr/bin:$PATH

USER 1001

ENTRYPOINT ["dumb-init","--","container-entrypoint-cli"]

#
# PHP-CLI / DEV
#

FROM cli-prd AS cli-dev

ARG COMPOSER_VERSION_ARG=2.8.10

LABEL be.smals.webtech.base.composer-version="${COMPOSER_VERSION_ARG}"

ENV PHP_XDEBUG_ENABLED="true"

USER root

RUN install-php-extensions @composer-${COMPOSER_VERSION_ARG} ; \
    apk add --no-cache --virtual .base-php-dev-rundeps git patch make g++ ; \
    cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" ; \
    mkdir /home/default/.composer ; \
    chown 1001:0 /home/default/.composer ; \
    chmod -R ugo+rw /home/default/.composer ; \
    rm -rf /var/cache/apk/*

USER 1001

EXPOSE 9003/tcp
