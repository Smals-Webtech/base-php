# syntax=docker/dockerfile:1.15
ARG PHP_VERSION_ARG
ARG NODE_VERSION_ARG
ARG COMPOSER_VERSION_ARG
ARG GOMPLATE_VERSION_ARG
ARG WAIT4X_VERSION_ARG

FROM hairyhenderson/gomplate:v${GOMPLATE_VERSION_ARG:-4.3.3}-alpine AS gomplate
FROM wait4x/wait4x:${WAIT4X_VERSION_ARG:-3.5.0} AS wait-for-it
FROM composer:${COMPOSER_VERSION_ARG:-2.8.4} AS composer
FROM node:${NODE_VERSION_ARG:-22}-alpine3.22 AS node

FROM alpine:3.22 AS builder

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

FROM php:${PHP_VERSION_ARG:-8.4.11}-fpm-alpine3.22 AS fpm-prd

ARG AWS_CLI_VERSION_ARG
ARG PHP_EXT_REDIS_VERSION_ARG
ARG PHP_EXT_APCU_VERSION_ARG

USER root

ENV PYTHONWARNINGS="ignore" \
    PHP_INI_SCAN_DIR="/usr/local/etc/php/conf.d:/opt/etc/php/conf.d" \
    AWS_CLI_VERSION=${AWS_CLI_VERSION_ARG:-2.22.10} \
    PHP_EXT_REDIS_VERSION=${PHP_EXT_REDIS_VERSION_ARG:-6.1.0} \
    PHP_EXT_APCU_VERSION=${PHP_EXT_APCU_VERSION_ARG:-5.1.24} \
    HOME=/home/default \
    TMPDIR=/app/tmp \
    PATH=/opt/bin:/opt/sbin:/usr/local/bin:/usr/bin:$PATH

WORKDIR /app

VOLUME /opt/sbin
VOLUME /opt/etc
VOLUME /app/var
VOLUME /app/tmp

COPY --from=wait-for-it --chmod=775 --chown=root:root /usr/bin/wait4x /usr/bin/wait4x
COPY --from=gomplate --chmod=775 --chown=root:root /bin/gomplate /usr/bin/gomplate

RUN mkdir -p /home/default ; \
    echo "include=/opt/etc/php/php-fpm.d/*.conf" >> /usr/local/etc/php-fpm.conf ; \
    apk upgrade --available ; \
    apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf freetype-dev icu-dev \
                                                libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev \
                                                libzip-dev openldap-dev pcre-dev gnupg git bzip2-dev \
                                                musl-libintl postgresql-dev libxml2-dev tidyhtml-dev \
                                                libxslt-dev ; \
    docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg ; \
    docker-php-ext-configure tidy --with-tidy ; \
    docker-php-ext-install -j "$(nproc)" soap bz2 fileinfo gettext intl pcntl pgsql \
                                         pdo_pgsql ldap gd mysqli pdo_mysql \
                                         zip bcmath exif tidy xsl calendar ; \
    pecl install APCu-${PHP_EXT_APCU_VERSION} ; \
    pecl install redis-${PHP_EXT_REDIS_VERSION} ; \
    docker-php-ext-enable apcu redis opcache ; \
    runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" && \
    apk add --update --no-cache --virtual .ems-phpext-rundeps $runDeps ; \
    apk add --update --upgrade --no-cache --virtual .ems-rundeps tzdata \
                                      bash gettext ssmtp postgresql-client postgresql-libs \
                                      libjpeg-turbo freetype libpng libwebp libxpm mailx libxslt coreutils \
                                      mysql-client jq icu-libs libxml2 python3 py3-pip groff supervisor \
                                      varnish tidyhtml dumb-init \
                                      aws-cli=~${AWS_CLI_VERSION} ; \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" ; \
    cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime ; \
    echo "Europe/Brussels" > /etc/timezone ; \
    adduser -D -u 1001 -g default -G root -s /sbin/nologin default ; \
    apk del .build-deps ; \
    rm -rf /var/cache/apk/* 

COPY --from=builder --chmod=777 --chown=1001:0 /rootfs/opt/ /opt/
COPY --from=builder --chmod=777 --chown=1001:0 /rootfs/app/ /app/
COPY --from=builder --chmod=775 --chown=root:root /rootfs/usr/local/bin/ /usr/local/bin/

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

ARG COMPOSER_VERSION_ARG
ARG NODE_VERSION_ARG
ARG PHP_EXT_XDEBUG_VERSION_ARG

ENV PHP_EXT_XDEBUG_VERSION=${PHP_EXT_XDEBUG_VERSION_ARG:-3.4.1}

ENV XDEBUG_MODE="develop"

LABEL be.smals.webtech.base.node-version="${NODE_VERSION_ARG:-20}" \
      be.smals.webtech.base.composer-version="${COMPOSER_VERSION_ARG:-2.8.4}"

USER root

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf coreutils linux-headers ; \
    pecl install xdebug-${PHP_EXT_XDEBUG_VERSION} ; \
    docker-php-ext-enable xdebug ; \
    runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" && \
    apk add --no-cache --virtual .php-dev-phpext-rundeps $runDeps ; \
    apk add --no-cache --virtual .php-dev-rundeps git patch ; \
    cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" ; \
    mkdir /home/default/.composer ; \
    chown 1001:0 /home/default/.composer ; \
    chmod -R ugo+rw /home/default/.composer ; \
    apk del .build-deps ; \
    rm -rf /var/cache/apk/* ;

EXPOSE 9003/tcp

USER 1001

#
# APACHE / PRD
#

FROM fpm-prd AS apache-prd

USER root

ENV APACHE_ENABLED=true

COPY --chmod=755 --chown=1001:0 src/ /app/var/www/html/

RUN apk add --update --no-cache --virtual .php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl ; \
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

COPY --chmod=755 --chown=1001:0 src/ /app/var/www/html/

RUN apk add --update --no-cache --virtual .php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl ; \
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

COPY --chmod=755 --chown=1001:0 src/ /app/var/www/html/

RUN apk add --update --no-cache --virtual .php-nginx-rundeps nginx nginx-mod-http-headers-more nginx-mod-http-vts ; \
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

COPY --chmod=755 --chown=1001:0 src/ /app/var/www/html/

RUN apk add --update --no-cache --virtual .php-nginx-rundeps nginx nginx-mod-http-headers-more nginx-mod-http-vts ; \
    adduser default nginx ; \
    rm -rf /var/cache/apk/* 

USER 1001

EXPOSE 9090/tcp

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

#
# PHP-CLI / PRD
#

FROM php:${PHP_VERSION_ARG:-8.4.11}-cli-alpine3.22 AS cli-prd

ARG AWS_CLI_VERSION_ARG
ARG PHP_EXT_REDIS_VERSION_ARG
ARG PHP_EXT_APCU_VERSION_ARG

USER root

ENV PYTHONWARNINGS="ignore" \
    PHP_INI_SCAN_DIR="/usr/local/etc/php/conf.d:/opt/etc/php/conf.d" \
    AWS_CLI_VERSION=${AWS_CLI_VERSION_ARG:-2.22.10} \
    PHP_EXT_REDIS_VERSION=${PHP_EXT_REDIS_VERSION_ARG:-6.1.0} \
    PHP_EXT_APCU_VERSION=${PHP_EXT_APCU_VERSION_ARG:-5.1.24} \
    HOME=/home/default \
    TMPDIR=/app/tmp \
    PATH=/opt/bin:/opt/sbin:/usr/local/bin:/usr/bin:$PATH

COPY --from=wait-for-it --chmod=775 --chown=root:root /usr/bin/wait4x /usr/bin/wait4x
COPY --from=gomplate --chmod=775 --chown=root:root /bin/gomplate /usr/bin/gomplate

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN mkdir -p /home/default ; \
    apk upgrade --available ; \
    apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf freetype-dev icu-dev \
                                                libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev \
                                                libzip-dev openldap-dev pcre-dev gnupg git bzip2-dev \
                                                musl-libintl postgresql-dev libxml2-dev tidyhtml-dev \
                                                libxslt-dev ; \
    docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg ; \
    docker-php-ext-configure tidy --with-tidy ; \
    docker-php-ext-install -j "$(nproc)" soap bz2 fileinfo gettext intl pcntl pgsql \
                                         pdo_pgsql simplexml ldap gd mysqli pdo_mysql \
                                         zip bcmath exif tidy xsl calendar ; \
    pecl install APCu-${PHP_EXT_APCU_VERSION} ; \
    pecl install redis-${PHP_EXT_REDIS_VERSION} ; \
    docker-php-ext-enable apcu redis opcache ; \
    runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" && \
    apk add --update --no-cache --virtual .ems-phpext-rundeps $runDeps ; \
    apk add --update --upgrade --no-cache --virtual .ems-rundeps tzdata \
                                      bash gettext ssmtp postgresql-client postgresql-libs \
                                      libjpeg-turbo freetype libpng libwebp libxpm mailx coreutils libxslt \
                                      mysql-client jq icu-libs libxml2 python3 py3-pip groff tidyhtml dumb-init \
                                      aws-cli=~${AWS_CLI_VERSION} ; \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" ; \
    cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime ; \
    echo "Europe/Brussels" > /etc/timezone ; \
    adduser -D -u 1001 -g default -G root -s /sbin/nologin default ; \
    apk del .build-deps ; \
    rm -rf /var/cache/apk/*

COPY --from=builder --chmod=777 --chown=1001:0 /rootfs/opt/ /opt/
COPY --from=builder --chmod=777 --chown=1001:0 /rootfs/app/ /app/
COPY --from=builder --chmod=775 --chown=root:root /rootfs/usr/local/bin/ /usr/local/bin/

USER 1001

ENTRYPOINT ["dumb-init","--","container-entrypoint-cli"]

#
# PHP-CLI / DEV
#

FROM cli-prd AS cli-dev

ARG COMPOSER_VERSION_ARG
ARG PHP_EXT_XDEBUG_VERSION_ARG

LABEL be.smals.webtech.base.composer-version="${COMPOSER_VERSION_ARG:-2.8.4}"

ENV PHP_EXT_XDEBUG_VERSION=${PHP_EXT_XDEBUG_VERSION_ARG:-3.4.1}

ENV XDEBUG_MODE="develop"

USER root

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf linux-headers ; \
    pecl install xdebug-${PHP_EXT_XDEBUG_VERSION} ; \
    docker-php-ext-enable xdebug ; \
    runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" && \
    apk add --no-cache --virtual .php-dev-phpext-rundeps $runDeps ; \
    apk add --no-cache --virtual .php-dev-rundeps git patch make g++ ; \
    cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" ; \
    mkdir /home/default/.composer ; \
    chown 1001:0 /home/default/.composer ; \
    chmod -R ugo+rw /home/default/.composer ; \
    apk del .build-deps ; \
    rm -rf /var/cache/apk/*

USER 1001

EXPOSE 9003/tcp
