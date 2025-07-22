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
FROM php:${PHP_VERSION_ARG:-8.4.10}-fpm-alpine3.22 AS fpm-prd

ARG AWS_CLI_VERSION_ARG
ARG PHP_EXT_REDIS_VERSION_ARG
ARG PHP_EXT_APCU_VERSION_ARG

USER root

ENV PHP_INI_SCAN_DIR="/usr/local/etc/php/conf.d:/app/etc/php/conf.d" \
    AWS_CLI_VERSION=${AWS_CLI_VERSION_ARG:-2.22.10} \
    PHP_EXT_REDIS_VERSION=${PHP_EXT_REDIS_VERSION_ARG:-6.1.0} \
    PHP_EXT_APCU_VERSION=${PHP_EXT_APCU_VERSION_ARG:-5.1.24} \
    HOME=/home/default \
    TMPDIR=/app/tmp \
    PATH=/app/bin:/app/sbin:/usr/local/bin:/usr/bin:$PATH

COPY --from=wait-for-it --chmod=775 --chown=root:root /usr/bin/wait4x /usr/bin/wait4x
COPY --from=gomplate --chmod=775 --chown=root:root /bin/gomplate /usr/bin/gomplate

COPY --chmod=664 --chown=1001:0 config/php/ /app/config/php/
COPY --chmod=664 --chown=1001:0 config/supervisor.d/ /app/config/supervisor.d/

COPY --chmod=775 --chown=root:root bin/ /usr/local/bin/

RUN mkdir -p /home/default \
             /app/var/lock \
             /app/var/log \
             /app/var/run/varnish \
             /app/var/run/php-fpm \
             /app/var/cache/varnish/varnishd \
             /app/etc/php/conf.d \
             /app/etc/php/php-fpm.d \
             /app/etc/supervisor.d \
             /app/bin/container-entrypoint.d \
             /app/src \
             /app/tmp \
             /app/sbin \
    && echo "include=/app/etc/php/php-fpm.d/*.conf" >> /usr/local/etc/php-fpm.conf \
    && chmod +x /usr/local/bin/container-entrypoint \
    && echo "Upgrade all already installed packages ..." \
    && apk upgrade --available \
    && echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf freetype-dev icu-dev \
                                                libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev \
                                                libzip-dev openldap-dev pcre-dev gnupg git bzip2-dev \
                                                musl-libintl postgresql-dev libxml2-dev tidyhtml-dev \
                                                libxslt-dev \
    && docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg \
    && docker-php-ext-configure tidy --with-tidy \
    && docker-php-ext-install -j "$(nproc)" soap bz2 fileinfo gettext intl pcntl pgsql \
                                            pdo_pgsql ldap gd ldap mysqli pdo_mysql \
                                            zip bcmath exif tidy xsl calendar \
    && pecl install APCu-${PHP_EXT_APCU_VERSION} \
    && pecl install redis-${PHP_EXT_REDIS_VERSION} \
    && docker-php-ext-enable apcu redis opcache \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --update --no-cache --virtual .ems-phpext-rundeps $runDeps \
    && apk add --update --upgrade --no-cache --virtual .ems-rundeps tzdata \
                                      bash gettext ssmtp postgresql-client postgresql-libs \
                                      libjpeg-turbo freetype libpng libwebp libxpm mailx libxslt coreutils \
                                      mysql-client jq icu-libs libxml2 python3 py3-pip groff supervisor \
                                      varnish tidyhtml \
                                      aws-cli=~${AWS_CLI_VERSION} \
    && mv /etc/supervisord.conf /etc/supervisord.conf.orig \
    && touch /app/var/log/supervisord.log \
             /app/var/run/supervisord.pid \
             /app/var/cache/varnish/secret \
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && echo "Setup timezone ..." \
    && cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime \
    && echo "Europe/Brussels" > /etc/timezone \
    && echo "Add non-privileged user ..." \
    && adduser -D -u 1001 -g default -G root -s /sbin/nologin default \
    && echo "Configure OpCache ..." \
    && echo 'opcache.memory_consumption=128' > /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.interned_strings_buffer=8' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.max_accelerated_files=4000' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.revalidate_freq=2' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && cd /opt \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /home/default /app \
    && chmod -R ugo+rw /home/default /app \
    && find /app -type d -exec chmod ugo+x {} \;

USER 1001

ENTRYPOINT ["container-entrypoint"]

EXPOSE 6081/tcp 6082/tcp

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD bash -c '[ -S /app/var/run/php-fpm/php-fpm.sock ]'

CMD ["php-fpm", "-F", "-R"]

FROM fpm-prd AS fpm-dev

ARG COMPOSER_VERSION_ARG
ARG NODE_VERSION_ARG
ARG PHP_EXT_XDEBUG_VERSION_ARG

ENV PHP_EXT_XDEBUG_VERSION=${PHP_EXT_XDEBUG_VERSION_ARG:-3.4.1}

LABEL be.zebbox.base.node-version="${NODE_VERSION_ARG:-20}" \
      be.zebbox.base.composer-version="${COMPOSER_VERSION_ARG:-2.8.4}"

USER root

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf coreutils linux-headers \
    && pecl install xdebug-${PHP_EXT_XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --no-cache --virtual .php-dev-phpext-rundeps $runDeps \
    && apk add --no-cache --virtual .php-dev-rundeps git patch \
    && echo "Configure Xdebug ..." \
    && echo '[xdebug]' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.mode=debug' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.start_with_request=yes' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.client_port=9003' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.client_host=host.docker.internal' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && rm -rf /var/cache/apk/* \
    && echo "Configure Composer ..." \
    && mkdir /home/default/.composer \
    && chown 1001:0 /home/default/.composer \
    && chmod -R ugo+rw /home/default/.composer \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

EXPOSE 9003

USER 1001

FROM fpm-prd AS apache-prd

LABEL be.zebbox.base.variant="apache"

USER root

ENV APACHE_ENABLED=true

COPY --chmod=775 --chown=root:root etc/apache2/ /etc/apache2/
COPY --chmod=664 --chown=root:root etc/supervisord.apache/supervisord.conf /etc/supervisord.conf

# Bug : Improper permissions handling on directories using –chmod in COPY command 
# https://github.com/moby/buildkit/issues/5943
COPY --chmod=755 --chown=1001:0 src/ /var/www/localhost/htdocs/

COPY --chmod=775 --chown=1001:0 config/apache2/ /app/config/apache2/

RUN mkdir -p /app/var/cache/apache2/mod_ssl \
             /app/etc/apache2/conf.d \
             /app/var/run/apache2 \
    && apk add --update --no-cache --virtual .php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl \
    && sed -i 's/^\([[:space:]]*\)Listen /\1#Listen /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)LoadModule mpm_prefork_module /\1#LoadModule mpm_prefork_module /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)LogLevel /\1#LogLevel /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)ErrorLog /\1#ErrorLog /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)CustomLog /\1#CustomLog /' /etc/apache2/httpd.conf \
    && rm -rf /var/cache/apk/* \
    && chown -Rf 1001:0 /app/var/cache/apache2 \
                        /app/etc/apache2 \
                        /app/var/run/apache2 \
    && chmod -R ugo+rw /app/var/cache/apache2 \
                       /app/etc/apache2 \
                       /app/var/run/apache2

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

FROM fpm-dev AS apache-dev

USER root

ENV APACHE_ENABLED=true

COPY --chmod=775 --chown=root:root etc/apache2/ /etc/apache2/
COPY --chmod=664 --chown=root:root etc/supervisord.apache/supervisord.conf /etc/supervisord.conf

# Bug : Improper permissions handling on directories using –chmod in COPY command 
# https://github.com/moby/buildkit/issues/5943
COPY --chmod=755 --chown=1001:0 src/ /var/www/localhost/htdocs/

COPY --chmod=775 --chown=1001:0 config/apache2/ /app/config/apache2/

RUN mkdir -p /app/var/cache/apache2/mod_ssl \
             /app/etc/apache2/conf.d \
             /app/var/run/apache2 \
    && apk add --update --no-cache --virtual .php-apache-rundeps apache2 apache2-utils apache2-proxy apache2-ssl \
    && sed -i 's/^\([[:space:]]*\)Listen /\1#Listen /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)LoadModule mpm_prefork_module /\1#LoadModule mpm_prefork_module /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)LogLevel /\1#LogLevel /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)ErrorLog /\1#ErrorLog /' /etc/apache2/httpd.conf \
    && sed -i 's/^\([[:space:]]*\)CustomLog /\1#CustomLog /' /etc/apache2/httpd.conf \
    && rm -rf /var/cache/apk/* \
    && chown -Rf 1001:0 /app/var/cache/apache2 \
                        /app/etc/apache2 \
                        /app/var/run/apache2 \
    && chmod -R ugo+rw /app/var/cache/apache2 \
                       /app/etc/apache2 \
                       /app/var/run/apache2

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

FROM fpm-prd AS nginx-prd

USER root

ENV NGINX_ENABLED=true

COPY --chmod=775 --chown=root:root etc/nginx/ /etc/nginx/
COPY --chmod=775 --chown=root:root etc/supervisord.nginx/supervisord.conf /etc/supervisord.conf

# Bug : Improper permissions handling on directories using –chmod in COPY command 
# https://github.com/moby/buildkit/issues/5943
COPY --chmod=755 --chown=1001:0 src/ /usr/share/nginx/html/

COPY --chmod=775 --chown=1001:0 config/nginx/ /app/config/nginx/

RUN mkdir -p /app/etc/nginx/sites-enabled \
             /app/var/run/nginx \
             /app/var/cache/nginx/fcgi \
             /app/var/tmp/client \
             /app/var/tmp/scgi \
             /app/var/tmp/fastcgi \
             /app/var/tmp/uwsgi \
             /app/var/tmp/scgi  \
    && apk add --update --no-cache --virtual .php-nginx-rundeps nginx \
                                                                nginx-mod-http-headers-more \
                                                                nginx-mod-http-vts \
    && rm -rf /etc/nginx/conf.d/default.conf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && find /var/lib/nginx -type d -exec chmod ugo+rx {} \; \
    && chown -Rf 1001:0 /app/etc/nginx \
                        /app/var/run/nginx \
                        /app/var/cache/nginx \
                        /app/var/tmp \
    && chmod -R ugo+rw /app/etc/nginx \
                       /app/var/run/nginx \
                       /app/var/cache/nginx \
                       /app/var/tmp

USER 1001

EXPOSE 9090/tcp

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

FROM fpm-dev AS nginx-dev

USER root

ENV NGINX_ENABLED=true

COPY --chmod=775 --chown=root:root etc/nginx/ /etc/nginx/
COPY --chmod=775 --chown=root:root etc/supervisord.nginx/supervisord.conf /etc/supervisord.conf

# Bug : Improper permissions handling on directories using –chmod in COPY command 
# https://github.com/moby/buildkit/issues/5943
COPY --chmod=755 --chown=1001:0 src/ /usr/share/nginx/html/

COPY --chmod=775 --chown=1001:0 config/nginx/ /app/config/nginx/

RUN mkdir -p /app/etc/nginx/sites-enabled \
             /app/var/run/nginx \
             /app/var/cache/nginx/fcgi \
             /app/var/tmp/client \
             /app/var/tmp/scgi \
             /app/var/tmp/fastcgi \
             /app/var/tmp/uwsgi \
             /app/var/tmp/scgi  \
    && apk add --update --no-cache --virtual .php-nginx-rundeps nginx \
                                                                nginx-mod-http-headers-more \
                                                                nginx-mod-http-vts \
    && rm -rf /etc/nginx/conf.d/default.conf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && find /var/lib/nginx -type d -exec chmod ugo+rx {} \; \
    && chown -Rf 1001:0 /app/etc/nginx \
                        /app/var/run/nginx \
                        /app/var/cache/nginx \
                        /app/var/tmp \
    && chmod -R ugo+rw /app/etc/nginx \
                       /app/var/run/nginx \
                       /app/var/cache/nginx \
                       /app/var/tmp

USER 1001

EXPOSE 9090/tcp

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=2s --interval=10s --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

FROM php:${PHP_VERSION_ARG:-8.4.10}-cli-alpine3.22 AS cli-prd

ARG AWS_CLI_VERSION_ARG
ARG PHP_EXT_REDIS_VERSION_ARG
ARG PHP_EXT_APCU_VERSION_ARG

USER root

ENV PHP_INI_SCAN_DIR="/usr/local/etc/php/conf.d:/app/etc/php/conf.d" \
    AWS_CLI_VERSION=${AWS_CLI_VERSION_ARG:-2.22.10} \
    PHP_EXT_REDIS_VERSION=${PHP_EXT_REDIS_VERSION_ARG:-6.1.0} \
    PHP_EXT_APCU_VERSION=${PHP_EXT_APCU_VERSION_ARG:-5.1.24} \
    HOME=/home/default \
    TMPDIR=/app/tmp \
    PATH=/app/bin:/app/sbin:/usr/local/bin:/usr/bin:$PATH

COPY --from=wait-for-it --chmod=775 --chown=root:root /usr/bin/wait4x /usr/bin/wait4x
COPY --from=gomplate --chmod=775 --chown=root:root /bin/gomplate /usr/bin/gomplate

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

COPY --chmod=775 --chown=1001:0 bin/ /usr/local/bin/

COPY --chmod=664 --chown=1001:0 config/php/conf.d/ /app/config/php/conf.d/

RUN mkdir -p /home/default \
             /app/src \
             /app/etc \
             /app/tmp \
             /app/bin \
             /app/sbin \
    && chmod +x /usr/local/bin/container-entrypoint-cli \
    && echo "Upgrade all already installed packages ..." \
    && apk upgrade --available \
    && echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf freetype-dev icu-dev \
                                                libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev \
                                                libzip-dev openldap-dev pcre-dev gnupg git bzip2-dev \
                                                musl-libintl postgresql-dev libxml2-dev tidyhtml-dev \
                                                libxslt-dev \
    && docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg \
    && docker-php-ext-configure tidy --with-tidy \
    && docker-php-ext-install -j "$(nproc)" soap bz2 fileinfo gettext intl pcntl pgsql \
                                            pdo_pgsql simplexml ldap gd ldap mysqli pdo_mysql \
                                            zip bcmath exif tidy xsl calendar \
    && pecl install APCu-${PHP_EXT_APCU_VERSION} \
    && pecl install redis-${PHP_EXT_REDIS_VERSION} \
    && docker-php-ext-enable apcu redis opcache \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --update --no-cache --virtual .ems-phpext-rundeps $runDeps \
    && apk add --update --upgrade --no-cache --virtual .ems-rundeps tzdata \
                                      bash gettext ssmtp postgresql-client postgresql-libs \
                                      libjpeg-turbo freetype libpng libwebp libxpm mailx coreutils libxslt \
                                      mysql-client jq icu-libs libxml2 python3 py3-pip groff tidyhtml \
                                      aws-cli=~${AWS_CLI_VERSION} \
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && echo "Setup timezone ..." \
    && cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime \
    && echo "Europe/Brussels" > /etc/timezone \
    && echo "Add non-privileged user ..." \
    && adduser -D -u 1001 -g default -G root -s /sbin/nologin default \
    && echo "Configure OpCache ..." \
    && echo 'opcache.memory_consumption=128' > /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.interned_strings_buffer=8' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.max_accelerated_files=4000' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.revalidate_freq=2' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache-recommended.ini \
    && cd /opt \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /home/default /app \
    && chmod -R ugo+rw /home/default /app \
    && find /app -type d -exec chmod ugo+x {} \;

ENTRYPOINT ["container-entrypoint-cli"]

USER 1001

FROM cli-prd AS cli-dev

ARG COMPOSER_VERSION_ARG
ARG PHP_EXT_XDEBUG_VERSION_ARG

LABEL be.zebbox.base.composer-version="${COMPOSER_VERSION_ARG:-2.8.4}"

ENV PHP_EXT_XDEBUG_VERSION=${PHP_EXT_XDEBUG_VERSION_ARG:-3.4.1}

USER root

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf linux-headers \
    && pecl install xdebug-${PHP_EXT_XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --no-cache --virtual .php-dev-phpext-rundeps $runDeps \
    && apk add --no-cache --virtual .php-dev-rundeps git patch make g++ \
    && apk del .build-deps \
    && echo "Configure Xdebug ..." \
    && echo '[xdebug]' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.mode=debug' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.start_with_request=yes' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.client_port=9003' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && echo 'xdebug.client_host=host.docker.internal' >> /usr/local/etc/php/conf.d/xdebug-default.ini \
    && cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && rm -rf /var/cache/apk/* \
    && echo "Configure Composer ..." \
    && mkdir /home/default/.composer \
    && chown 1001:0 /home/default/.composer \
    && chmod -R ugo+rw /home/default/.composer \
    && rm -rf /var/cache/apk/* \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /home/default \
    && chmod -R ugo+rw /home/default \
    && find /home/default -type d -exec chmod ugo+x {} \;

EXPOSE 9003

ENTRYPOINT ["container-entrypoint-cli"]

USER 1001
