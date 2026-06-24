# 🐘 PHP Base Image – smalswebtech/base-php

This repository provides a **production-ready, multi-variant PHP base image** built on Alpine and PHP 8.5.x, ideal for extending with any PHP application or framework (Laravel, Symfony, WordPress, etc.).

✅ Hosted on Docker Hub: [smalswebtech/base-php](https://hub.docker.com/r/smalswebtech/base-php)

## ✨ Features

- ✅ PHP 8 – consistent and up-to-date
- 📦 Multiple runtime variants: `cli`, `fpm`, `nginx`, `apache`
- ⚡ Lightweight Alpine Linux base
- 📂 Composer pre-installed
- 🚀 Multi-platform builds (`linux/amd64`, `linux/arm64`)
- 🔁 Advanced build tool using `docker buildx bake`
- ⚙️ Mature Container startup design

## 🧱 Filesystem layout and read-only design

The container is designed to run safely in **read-only mode**.
All immutable application code and static assets are baked into the image at build time, while writable paths are isolated into dedicated runtime volumes.

```text
/app        → Symfony application (build-time)
/opt/bin    → Entrypoint & setup scripts (build-time)
/opt/config → Static configuration templates (build-time)
```

Runtime-writable directories:

```text
/app/var    → Application runtime data (cache, logs, sessions, PIDs)
/app/tmp    → Temporary files
/opt/sbin   → Auto-generated executable scripts created at startup
/opt/etc    → Middleware configuration (Apache, PHP-FPM, Supervisor, etc.)
```

This layout cleanly separates static and dynamic concerns:
- the **base image remains immutable**,
- all runtime configuration and state are confined to mounted volumes,
- allowing the container to run entirely in **read-only mode** with predictable behavior.

## ⚙️ Container startup design

The container implements a deterministic initialization flow to ensure consistent runtime configuration.  
A Bash entrypoint script prepares the environment by exporting all required variables, resolving user-defined values or falling back to predefined defaults.  
Configuration files (e.g., PHP and Supervisor .ini, Apache .conf, Varnish .vcl) and dynamic scripts (e.g. Varnish statup scripts) are rendered from gomplate templates using these variables.  
After successful generation, the script sanitizes the environment by unsetting all non-essential variables (except a defined whitelist required by runtime services).  
Supervisor is then launched as PID 1 to manage all application processes.  

A debug mode (`DEBUG=true`) enables shell tracing (`set -x`) and extended logging to facilitate startup diagnostics.  
This approach ensures idempotent initialization, predictable config state, and no residual secrets or transient data in the container’s environment.  

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `DEBUG` | `false` | Set to `true` to enable `set -x` shell tracing throughout the entire startup sequence. Useful for diagnosing template rendering failures or unexpected variable values. |

## 👷 Supervisor Configuration

| Environment Variable                         | Default (prd)                  | Default (dev)                  | Documentation                                                                        |
|----------------------------------------------|--------------------------------|--------------------------------|--------------------------------------------------------------------------------------|
| `SUPERVISOR_XMLRPC_UNIX_SOCKET_ENABLED`      | "true"                         | "true"                         | [Link](https://supervisord.org/api.html#xml-rpc-api-documentation)                   |
| `SUPERVISOR_XMLRPC_UNIX_SOCKET_PATH`         | "/app/var/run/supervisor.sock" | "/app/var/run/supervisor.sock" | [Link](https://supervisord.org/configuration.html#supervisorctl-section-values)      |
| `SUPERVISOR_XMLRPC_UNIX_SOCKET_CHMOD`        | "0700"                         | "0700"                         | [Link](https://supervisord.org/configuration.html#unix-http-server-section-settings) |
| `SUPERVISOR_XMLRPC_UNIX_SOCKET_CHOWN`        | "default:root"                 | "default:root"                 | [Link](https://supervisord.org/configuration.html#unix-http-server-section-settings) |
| `SUPERVISOR_XMLRPC_UNIX_SOCKET_AUTH_ENABLED` | "true"                         | "true"                         | [Link](https://supervisord.org/configuration.html#supervisorctl-section-values)      |
| `SUPERVISOR_XMLRPC_UNIX_SOCKET_USERNAME`     | "admin"                        | "admin"                        | [Link](https://supervisord.org/configuration.html#supervisorctl-section-values)      |
| `SUPERVISOR_XMLRPC_UNIX_SOCKET_PASSWORD`     | "pa55w0rd"                     | "pa55w0rd"                     | [Link](https://supervisord.org/configuration.html#supervisorctl-section-values)      |
| `SUPERVISOR_XMLRPC_INET_ENABLED`             | "false"                        | "false"                        | [Link](https://supervisord.org/configuration.html#inet-http-server-section-settings) |
| `SUPERVISOR_XMLRPC_INET_HOST`                | ""                             | ""                             | [Link](https://supervisord.org/configuration.html#inet-http-server-section-settings) |
| `SUPERVISOR_XMLRPC_INET_PORT`                | "9744"                         | "9744"                         | [Link](https://supervisord.org/configuration.html#inet-http-server-section-settings) |
| `SUPERVISOR_XMLRPC_INET_USERNAME`            | "admin"                        | "admin"                        | [Link](https://supervisord.org/configuration.html#inet-http-server-section-settings) |
| `SUPERVISOR_XMLRPC_INET_PASSWORD`            | "pa55w0rd"                     | "pa55w0rd"                     | [Link](https://supervisord.org/configuration.html#inet-http-server-section-settings) |

## 🐘 PHP Configuration

The PHP image ships with all required extensions pre-installed, but it’s designed to run in read-only mode at runtime.  
To enable dynamic configuration, a writable volume is mounted and used as the active PHP configuration directory. During container startup, the entrypoint generates configuration files
via gomplate and sets `PHP_INI_SCAN_DIR` to point to this writable path.  The default php.ini file ( `/usr/local/etc/php/php.ini` ) — which may differ depending on the image variant — is still loaded first, and the configuration files in `PHP_INI_SCAN_DIR` override any settings defined there.

This mechanism provides full flexibility at startup while keeping the base image immutable and compatible with read-only filesystem deployments.

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `PHP_BYPASS_INI_DEFAULT_VALUES` | `false` | Set to `true` to skip reading the active `php.ini` file for default values. All directives will fall back to the fixed built-in defaults defined in the image. Useful for fully predictable startup behavior regardless of the base `php.ini` variant. |

### Core

The table below lists the most commonly overridden PHP core directives. For the full reference including all directives, see [docs/php.md](docs/php.md).

| Directive | Environment Variable | Default (prd) | Default (dev) | Documentation |
|-----------|----------------------|---------------|---------------|---------------|
| `memory_limit` | `PHP_MEMORY_LIMIT` | `128M` | `128M` | [Link](https://www.php.net/manual/en/ini.core.php#ini.memory-limit) |
| `max_execution_time` | `PHP_MAX_EXECUTION_TIME` | `30` | `30` | [Link](https://www.php.net/manual/en/info.configuration.php#ini.max-execution-time) |
| `max_input_time` | `PHP_MAX_INPUT_TIME` | `60` | `60` | [Link](https://www.php.net/manual/en/info.configuration.php#ini.max-input-time) |
| `post_max_size` | `PHP_POST_MAX_SIZE` | `8M` | `8M` | [Link](https://www.php.net/manual/en/ini.core.php#ini.post-max-size) |
| `upload_max_filesize` | `PHP_UPLOAD_MAX_FILESIZE` | `2M` | `2M` | [Link](https://www.php.net/manual/en/ini.core.php#ini.upload-max-filesize) |
| `display_errors` | `PHP_DISPLAY_ERRORS` | `Off` | `On` | [Link](https://www.php.net/manual/en/errorfunc.configuration.php#ini.display-errors) |
| `error_reporting` | `PHP_ERROR_REPORTING` | `E_ALL & ~E_DEPRECATED` | `E_ALL` | [Link](https://www.php.net/manual/en/function.error-reporting.php) |
| `expose_php` | `PHP_EXPOSE_PHP` | `Off` | `Off` | [Link](https://www.php.net/manual/en/ini.core.php#ini.expose-php) |
| `date.timezone` | `PHP_DATE_TIMEZONE` | `Europe/Brussels` | `Europe/Brussels` | [Link](https://www.php.net/manual/en/datetime.configuration.php#ini.date.timezone) |
| `open_basedir` | `PHP_OPEN_BASEDIR` | `""` | `""` | [Link](https://www.php.net/manual/en/ini.core.php#ini.open-basedir) |
| `disable_functions` | `PHP_DISABLE_FUNCTIONS` | `""` | `""` | [Link](https://www.php.net/manual/en/ini.core.php#ini.disable-functions) |
| `realpath_cache_size` | `PHP_REALPATH_CACHE_SIZE` | `4M` | `4M` | [Link](https://www.php.net/manual/en/ini.core.php#ini.realpath-cache-size) |
| `zend.assertions` | `PHP_ZEND_ASSERTIONS` | `-1` | `1` | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.assertions) |
| `zend.exception_ignore_args` | `PHP_ZEND_EXCEPTION_IGNORE_ARGS` | `On` | `Off` | [Link](https://www.php.net/manual/en/ini.core.php#ini.zend.exception-ignore-args) |

### PHP Extensions

All installed extensions are symlinked by default from their actual `.so` locations into this writable directory. Each extension’s activation can be controlled via a corresponding environment variable (e.g., `PHP_APC_ENABLED=false` disables `apcu`). When enabled, the entrypoint also generates the appropriate `.ini` configuration file for the extension within the writable volume.

| Environment Variable        | Extension       | Enabled (prd) | Enabled (dev) | Configuration                        | Documentation                                                               |
|-----------------------------|-----------------|---------------|---------------|--------------------------------------|-----------------------------------------------------------------------------|
| `PHP_APC_ENABLED`           | `apcu`          | `true`        | `true`        | [Link](docs/php.md#apcu)             | [Link](https://www.php.net/manual/en/book.apcu.php)                         |
| `PHP_BCMATH_ENABLED`        | `bcmath`        | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/book.bc.php)                           |
| `PHP_BZ2_ENABLED`           | `bz2`           | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/book.bzip2.php)                        |
| `PHP_CALENDAR_ENABLED`      | `calendar`      | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/book.calendar.php)                     |
| `PHP_EXIF_ENABLED`          | `exif`          | `true`        | `true`        | [Link](docs/php.md#exif)             | [Link](https://www.php.net/manual/en/book.exif.php)                         |
| `PHP_GD_ENABLED`            | `gd`            | `true`        | `true`        | [Link](docs/php.md#gd)               | [Link](https://www.php.net/manual/en/book.image.php)                        |
| `PHP_GETTEXT_ENABLED`       | `gettext`       | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/book.gettext.php)                      |
| `PHP_INTL_ENABLED`          | `intl`          | `true`        | `true`        | [Link](docs/php.md#intl)             | [Link](https://www.php.net/manual/en/book.intl.php)                         |
| `PHP_LDAP_ENABLED`          | `ldap`          | `true`        | `true`        | [Link](docs/php.md#ldap)             | [Link](https://www.php.net/manual/en/book.ldap.php)                         |
| `PHP_MYSQLI_ENABLED`        | `mysqli`        | `true`        | `true`        | [Link](docs/php.md#mysqli)           | [Link](https://www.php.net/manual/en/book.mysqli.php)                       |
| `PHP_OPCACHE_ENABLED`       | `opcache`       | `true`        | `true`        | [Link](docs/php.md#opcache)          | [Link](https://www.php.net/manual/en/book.opcache.php)                      |
| `PHP_OPENTELEMETRY_ENABLED` | `opentelemetry` | `false`       | `false`       | [Link](docs/php.md#opentelemetry)    | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| `PHP_PCNTL_ENABLED`         | `pcntl`         | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/book.pcntl.php)                        |
| `PHP_PDO_MYSQL_ENABLED`     | `pdo_mysql`     | `true`        | `true`        | [Link](docs/php.md#mysql-pdo-driver) | [Link](https://www.php.net/manual/en/ref.pdo-mysql.php)                     |
| `PHP_PDO_PGSQL_ENABLED`     | `pdo_pgsql`     | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/ref.pdo-pgsql.php)                     |
| `PHP_PGSQL_ENABLED`         | `pgsql`         | `true`        | `true`        | [Link](docs/php.md#postgresql)       | [Link](https://www.php.net/manual/en/book.pgsql.php)                        |
| `PHP_REDIS_ENABLED`         | `redis`         | `true`        | `true`        | [Link](docs/php.md#redis)            | [Link](https://github.com/phpredis/phpredis/)                               |
| `PHP_SOAP_ENABLED`          | `soap`          | `true`        | `true`        | [Link](docs/php.md#soap)             | [Link](https://www.php.net/manual/en/book.soap.php)                         |
| `PHP_SODIUM_ENABLED`        | `sodium`        | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/book.sodium.php)                       |
| `PHP_TIDY_ENABLED`          | `tidy`          | `true`        | `true`        | [Link](docs/php.md#tidy)             | [Link](https://www.php.net/manual/en/book.tidy.php)                         |
| `PHP_XDEBUG_ENABLED`        | `xdebug`        | `false`       | `true`        | [Link](docs/php.md#xdebug)           | [Link](https://xdebug.org/)                                                 |
| `PHP_XSL_ENABLED`           | `xsl`           | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/book.xsl.php)                          |
| `PHP_ZIP_ENABLED`           | `zip`           | `true`        | `true`        | No Configuration Yet                 | [Link](https://www.php.net/manual/en/book.zip.php)                          |

### Adding Custom Extensions from a Child Image

The parent image uses the `PHP_EXT_INSTALL` variable to define the default list of extensions to install.
To allow child images to add their own extensions without modifying the parent image, an additional variable is provided: **`PHP_EXT_INSTALL_CUSTOM`**.

This variable can be defined or overridden directly in the child image’s `Dockerfile`. Its content will be merged with `PHP_EXT_INSTALL` during the installation process, making it easy to include extra extensions without affecting the base configuration.

This image uses **[mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer)** to install PHP extensions in a simple and reliable way.  

**Example in a child image:**

```Dockerfile
ENV PHP_EXT_INSTALL_CUSTOM="xdebug-^3.5 redis-stable apcu gd"

RUN install-php-extensions ${PHP_EXT_INSTALL_CUSTOM}
```

These extensions will automatically be processed and installed along with the default ones defined in the parent image.

### FastCGI Process Manager (FPM)

[Configuration](docs/php-fpm.md)  

## 🪶 Apache Configuration

Apache is only active in the `apache-prd` and `apache-dev` variants. The flag below is set automatically by the image — override it only if you build a custom variant.

| Environment Variable | Default (prd) | Default (dev) | Description |
|----------------------|---------------|---------------|-------------|
| `APACHE_ENABLED` | `true` | `true` | Controls whether the entrypoint renders Apache configuration files and registers Apache as a supervised process. Set to `false` to disable Apache entirely (e.g. in a custom variant where only PHP-FPM is needed). |

| Environment Variable                          | Default (prd)                                                  | Default (dev)                                                  | Documentation                                                                        |
|-----------------------------------------------|----------------------------------------------------------------|----------------------------------------------------------------|--------------------------------------------------------------------------------------|
| `APACHE_SERVER_TOKENS`                        | `Prod`                                                         | `Prod`                                                         | [Link](https://httpd.apache.org/docs/2.4/mod/core.html#servertokens)                 |
| `APACHE_SERVER_ROOT`                          | `/app/var/www`                                                 | `/app/var/www`                                                 | [Link](https://httpd.apache.org/docs/2.4/mod/core.html#serverroot)                   |
| `APACHE_LISTEN`                               | `9000`                                                         | `9000`                                                         | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#listen)                 |
| `APACHE_SERVER_ADMIN`                         | `you@example.com`                                              | `you@example.com`                                              | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#serveradmin)            |
| `APACHE_SERVER_SIGNATURE`                     | `On`                                                           | `On`                                                           | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#serversignature)        |
| `APACHE_LOG_FORMAT_COMBINED`                  | `%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"` | `%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"` | [Link](https://httpd.apache.org/docs/2.4/mod/mod_log_config.html)                    |
| `APACHE_LOG_FORMAT_COMMON`                    | `%h %l %u %t \"%r\" %>s %b`                                    | `%h %l %u %t \"%r\" %>s %b`                                    | [Link](https://httpd.apache.org/docs/2.4/mod/mod_log_config.html)                    |
| `APACHE_DAEMON_LOG`                           | `info`                                                         | `info`                                                         | [Link](https://httpd.apache.org/docs/2.4/en/mod/core.html#loglevel)                  |
| `APACHE_TIMEOUT`                              | `60`                                                           | `60`                                                           | [Link](https://httpd.apache.org/docs/2.4/en/mod/core.html#timeout)                   |
| `APACHE_KEEP_ALIVE`                           | `On`                                                           | `On`                                                           | [Link](https://httpd.apache.org/docs/2.4/en/mod/core.html#keepalive)                 |
| `APACHE_KEEP_ALIVE_TIMEOUT`                   | `5`                                                            | `5`                                                            | [Link](https://httpd.apache.org/docs/2.4/en/mod/core.html#maxkeepaliverequests)      |
| `APACHE_USE_CANONICAL_NAME`                   | `Off`                                                          | `Off`                                                          | [Link](https://httpd.apache.org/docs/2.4/en/mod/core.html#usecanonicalname)          |
| `APACHE_ACCESS_FILE_NAME`                     | `.htaccess`                                                    | `.htaccess`                                                    | [Link](https://httpd.apache.org/docs/2.4/en/mod/core.html#accessfilename)            |
| `APACHE_HOSTNAME_LOOKUPS`                     | `Off`                                                          | `Off`                                                          | [Link](https://httpd.apache.org/docs/2.4/en/mod/core.html#hostnamelookups)           |
| `APACHE_MPM_WORKER_START_SERVERS`             | `3`                                                            | `3`                                                            | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#startservers)           |
| `APACHE_MPM_WORKER_MIN_SPARE_THREADS`         | `75`                                                           | `75`                                                           | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#minsparethreads)        |
| `APACHE_MPM_WORKER_MAX_SPARE_THREADS`         | `250`                                                          | `250`                                                          | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#maxsparethreads)        |
| `APACHE_MPM_WORKER_THREADS_PER_CHILD`         | `25`                                                           | `25`                                                           | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#threadsperchild)        |
| `APACHE_MPM_WORKER_MAX_REQUEST_WORKERS`       | `400`                                                          | `400`                                                          | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#maxrequestworkers)      |
| `APACHE_MPM_WORKER_MAX_CONNECTIONS_PER_CHILD` | `0`                                                            | `0`                                                            | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#maxconnectionsperchild) |
| `APACHE_MPM_WORKER_MAX_MEM_FREE`              | `2048`                                                         | `2048`                                                         | [Link](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#maxmemfree)             |

## 🟩 Nginx Configuration

Nginx is only active in the `nginx-prd` and `nginx-dev` variants. It acts as a reverse proxy in front of PHP-FPM, communicating via a Unix socket.

### Activation

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_ENABLED` | `false` | Controls whether Nginx config files are rendered and Nginx is registered as a supervised process. Set automatically by the image in the `nginx` variants. |
| `NGINX_LUA_ENABLED` | `false` | Load Lua modules (`ndk_http_module`, `ngx_http_lua_module`, `ngx_http_lua_upstream_module`). |
| `NGINX_NJS_ENABLED` | `false` | Load the NJS JavaScript module (`ngx_http_js_module`). |
| `NGINX_DEBUG_ENABLED` | `false` | Use the `nginx-debug` binary with verbose logging. Inherits `$DEBUG` if set. |

### Logging

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_DEFAULT_ACCESS_LOG_PATH` | `/dev/stdout` | Access log destination. |
| `NGINX_DEFAULT_ACCESS_LOG_FORMAT_NAME` | `combined_extended` | Log format name. Available: `main`, `main_timed`, `combined_extended`, `json_extended`, `ecs_json`. |
| `NGINX_DEFAULT_ERROR_LOG_PATH` | `/dev/stdout` | Error log destination. |
| `NGINX_DEFAULT_ERROR_LOG_LEVEL` | `warn` | Error log level (`debug`, `info`, `notice`, `warn`, `error`, `crit`). |

### Performance & Timeouts

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_KEEPALIVE_TIMEOUT` | `65s` | Keepalive connection timeout. |
| `NGINX_KEEPALIVE_REQUESTS` | `1000` | Maximum requests per keepalive connection. |
| `NGINX_SEND_TIMEOUT` | `60s` | Timeout for transmitting a response to the client. |
| `NGINX_SENDFILE` | `off` | Enable kernel `sendfile()`. Set to `on` for static file serving on bare-metal. |
| `NGINX_TCP_NOPUSH` | `on` | Send response headers in one packet. |
| `NGINX_TCP_NODELAY` | `on` | Disable Nagle's algorithm for keepalive connections. |
| `NGINX_IGNORE_INVALID_HEADERS` | `on` | Ignore headers with invalid names. |
| `NGINX_CLIENT_MAX_BODY_SIZE` | `1m` | Maximum allowed request body size. |
| `NGINX_CLIENT_HEADER_BUFFER_SIZE` | `1k` | Buffer size for reading client request headers. |
| `NGINX_CLIENT_HEADER_TIMEOUT` | `60s` | Timeout for reading client request headers. |
| `NGINX_CLIENT_BODY_TIMEOUT` | `60s` | Timeout for reading client request body. |
| `NGINX_CLIENT_BODY_IN_SINGLE_BUFFER` | `off` | Store client body in a single buffer. |
| `NGINX_CLIENT_BODY_IN_FILE_ONLY` | `off` | Always store client body in a temporary file. |
| `NGINX_LARGE_CLIENT_HEADER_BUFFERS_COUNT` | `4` | Number of large client header buffers. |
| `NGINX_LARGE_CLIENT_HEADER_BUFFERS_SIZE` | `8k` | Size of each large client header buffer. |
| `NGINX_SERVER_NAMES_HASH_BUCKET_SIZE` | `128` | `server_names_hash_bucket_size` directive. |
| `NGINX_SERVER_NAMES_HASH_MAX_SIZE` | `512` | `server_names_hash_max_size` directive. |

### Proxy

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_PROXY_CONNECT_TIMEOUT` | `65s` | Timeout for establishing a connection to the upstream. |
| `NGINX_PROXY_SEND_TIMEOUT` | `65s` | Timeout for transmitting a request to the upstream. |
| `NGINX_PROXY_READ_TIMEOUT` | `65s` | Timeout for reading a response from the upstream. |
| `NGINX_PROXY_REQUEST_BUFFERING` | `on` | Buffer the full client request body before proxying. |

### Compression (Gzip)

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_GZIP_ENABLED` | `on` | Enable gzip compression. |
| `NGINX_GZIP_COMP_LEVEL` | `6` | Compression level (1–9). |
| `NGINX_GZIP_MIN_LENGTH` | `256` | Minimum response length to compress (bytes). |
| `NGINX_GZIP_PROXIED` | `any` | Compress responses for proxied requests. |
| `NGINX_GZIP_VARY` | `on` | Add `Vary: Accept-Encoding` header. |
| `NGINX_GZIP_HTTP_VERSION` | `1.1` | Minimum HTTP version to compress. |
| `NGINX_GZIP_DISABLE` | `msie6` | Disable gzip for matching User-Agents. |
| `NGINX_GZIP_TYPES` | `text/plain text/css application/json ...` | MIME types to compress (space-separated). |
| `NGINX_GZIP_BUFFERS_COUNT` | `16` | Number of gzip buffers. |
| `NGINX_GZIP_BUFFERS_SIZE` | `8k` | Size of each gzip buffer. |

### Real IP

Enables trusted proxy configuration so Nginx uses the original client IP from a forwarded header instead of the proxy IP.

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_REAL_IP_ENABLED` | `false` | Enable real IP resolution. |
| `NGINX_REAL_IP_TRUSTED_PROXIES` | `10.0.0.0/8 172.16.0.0/12 192.168.0.0/16` | Space-separated list of trusted proxy CIDR ranges. |
| `NGINX_REAL_IP_HEADER_NAME` | `X-Forwarded-For` | Header containing the real client IP. |
| `NGINX_REAL_IP_RECURSIVE` | `on` | Walk the full IP chain to find the original client IP. |

### Rate Limiting (Soft Throttle)

Two-zone rate limiting: a global limit for all traffic, and a stricter bot-specific limit based on User-Agent matching. Trusted IPs bypass both limits.

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_SOFT_THROTTLE_ENABLED` | `false` | Enable rate limiting. |
| `NGINX_SOFT_THROTTLE_DRY_RUN_ENABLED` | `on` | Log rate-limit events without rejecting requests (calibration mode). Disable once limits are tuned. |
| `NGINX_SOFT_THROTTLE_STATUS_CODE` | `429` | HTTP status code returned when the rate limit is exceeded. |
| `NGINX_SOFT_THROTTLE_WHITELIST` | _(empty)_ | Space-separated CIDR ranges that bypass all rate limits (e.g. VPN, monitoring). |
| `NGINX_SOFT_THROTTLE_GLOBAL_ZONE_SIZE` | `20m` | Shared memory for the global limit zone (~320k IPs per 20m). |
| `NGINX_SOFT_THROTTLE_GLOBAL_ZONE_RATE` | `20r/s` | Global request rate limit. |
| `NGINX_SOFT_THROTTLE_GLOBAL_ZONE_BURST` | `30` | Burst allowance for the global limit. |
| `NGINX_SOFT_THROTTLE_BOTS_ZONE_SIZE` | `20m` | Shared memory for the bot limit zone. |
| `NGINX_SOFT_THROTTLE_BOTS_ZONE_RATE` | `1r/m` | Rate limit applied to detected bots. |
| `NGINX_SOFT_THROTTLE_BOTS_ZONE_BURST` | `5` | Burst allowance for the bot limit. |
| `NGINX_SOFT_THROTTLE_BOTS_USER_AGENT` | _(see below)_ | Space-separated list of User-Agent regular expression patterns identifying bots. |

Default bot patterns: `googlebot`, `bingbot`, `baiduspider`, `yandexbot`, `duckduckbot`, `semrushbot`, `ahrefsbot`, `python-requests`, `curl`, `wget`, `adsbot-google`, and others.

### Basic Authentication

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_BASIC_AUTH_ENABLED` | `false` | Generate an `.htpasswd` file at startup. |
| `NGINX_BASIC_AUTH_USERNAME` | `default` | Username. |
| `NGINX_BASIC_AUTH_PASSWORD` | `pa55w0rd` | Password — **change in production**. |
| `NGINX_BASIC_AUTH_FILE_PATH` | `/opt/etc/nginx/.htpasswd` | Path to the generated `.htpasswd` file. |

Reference in your site config:
```nginx
auth_basic "Restricted";
auth_basic_user_file /opt/etc/nginx/.htpasswd;
```

### FastCGI Cache

Caches PHP-FPM responses on disk. Cache bypass is automatically configured for mutating HTTP methods and session cookies.

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `NGINX_FASTCGI_CACHE_ENABLED` | `false` | Enable FastCGI response caching. |
| `NGINX_FASTCGI_CACHE_NAME` | `microcache` | Cache zone name. Reference as `fastcgi_cache microcache;` in your site config. |
| `NGINX_FASTCGI_CACHE_KEY` | `$scheme$request_method$host$request_uri` | Cache key. |
| `NGINX_FASTCGI_CACHE_MEM_SIZE` | `10m` | Shared memory for cache metadata. |
| `NGINX_FASTCGI_CACHE_DISK_SIZE` | `1024m` | Maximum disk space for cached responses. |
| `NGINX_FASTCGI_CACHE_LEVELS` | `1:2` | Cache directory structure levels. |
| `NGINX_FASTCGI_CACHE_INACTIVE` | `1h` | Evict entries not accessed within this duration. |
| `NGINX_FASTCGI_CACHE_VALID_OK_CODE` | `200 301 302` | Status codes to cache. |
| `NGINX_FASTCGI_CACHE_VALID_OK_DURATION` | `10m` | Cache TTL for successful responses. |
| `NGINX_FASTCGI_CACHE_VALID_NOK_CODE` | `404` | Error status codes to cache. |
| `NGINX_FASTCGI_CACHE_VALID_NOK_DURATION` | `1m` | Cache TTL for error responses. |
| `NGINX_FASTCGI_NO_CACHE_METHODS` | `POST PUT DELETE PATCH` | HTTP methods that bypass the cache. |
| `NGINX_FASTCGI_NO_CACHE_COOKIES` | `~*PHPSESSID ~*symfony` | Cookie name patterns that bypass the cache. |
| `NGINX_FASTCGI_SEND_TIMEOUT` | `65s` | Timeout for sending a request to the FastCGI upstream. |
| `NGINX_FASTCGI_READ_TIMEOUT` | `65s` | Timeout for reading a response from the FastCGI upstream. |
| `NGINX_FASTCGI_BUFFER_SIZE` | `32k` | Buffer size for reading FastCGI response headers. |
| `NGINX_FASTCGI_BUFFERS_COUNT` | `8` | Number of FastCGI response buffers. |
| `NGINX_FASTCGI_BUFFERS_SIZE` | `32k` | Size of each FastCGI response buffer. |
| `NGINX_FASTCGI_REQUEST_BUFFERING` | `on` | Buffer the full client request body before forwarding to FastCGI. |

## 🔒 Monitoring Access Control

The web server exposes monitoring/status endpoints over HTTP — php-fpm `/status` & `/ping`, the Nginx VTS `/metrics`, `/stub-status`, `/vts-status`, `/real-time-status`, and the Apache `/server-status` / `/server-info` / `/status`. Access to these is restricted to an allow-list of client CIDRs (applies to both the Nginx and Apache variants).

Requests arriving over a **Unix socket** are always allowed — reaching the socket already implies a host-local / same-pod peer (e.g. a Prometheus exporter sidecar reading the socket from a shared OpenShift `emptyDir`). The CIDR allow-list only gates **TCP** access (e.g. an exporter running as a separate service over a Swarm overlay).

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `MONITORING_ALLOW` | `127.0.0.1/32 ::1/128 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 fc00::/7` | Space-separated list of CIDRs allowed to reach the monitoring/status endpoints over TCP. Defaults to loopback + private (RFC1918 / IPv6 ULA) ranges. Set to `0.0.0.0/0 ::/0` to expose them to everyone, or to a narrower list to lock them down. Unix-socket access is unaffected. |

> **Security note**: php-fpm `/status` and the Apache/Nginx status pages disclose internal runtime details. Do **not** widen this list to public ranges, and never publish the monitoring port (Nginx `9090`, Apache shares the app port) on an untrusted network.

## ☁️ AWS CLI Configuration

AWS CLI v2 is pre-installed in all variants. The entrypoint generates `~/.aws/config` and `~/.aws/credentials` from the variables below, making the CLI immediately usable inside the container without mounting external credential files.

> **Security note**: Do not pass `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` as plain environment variables in production. Prefer IAM instance roles, OIDC federation, or secrets management solutions.

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `AWS_ACCESS_KEY_ID` | `""` | AWS access key ID. |
| `AWS_SECRET_ACCESS_KEY` | `""` | AWS secret access key. |
| `AWS_DEFAULT_REGION` | `us-east-1` | Default AWS region for CLI commands. |
| `AWS_PROFILE` | `default` | Active AWS profile name. |
| `AWS_DEFAULT_OUTPUT` | `json` | Default output format (`json`, `text`, `table`). |
| `AWS_CONFIG_FILE` | `/opt/etc/aws/config` | Path to the generated AWS config file. |
| `AWS_SHARED_CREDENTIALS_FILE` | `/opt/etc/aws/credentials` | Path to the generated AWS credentials file. |
| `AWS_S3_ENDPOINT_URL` | `https://s3.amazonaws.com` | S3 endpoint URL. Override to use a compatible store (MinIO, LocalStack, etc.). |

## 📦 Available Docker Image Variants

| Tag                                            | Description            | Platform(s)      |
|------------------------------------------------|------------------------|------------------|
| `smalswebtech/base-php:${PHP_VERSION}$-cli`    | PHP CLI only           | `amd64`, `arm64` |
| `smalswebtech/base-php:${PHP_VERSION}$-fpm`    | PHP-FPM engine         | `amd64`, `arm64` |
| `smalswebtech/base-php:${PHP_VERSION}$-apache` | Apache + PHP-FPM setup | `amd64`, `arm64` |
| `smalswebtech/base-php:${PHP_VERSION}$-nginx`  | Nginx + PHP-FPM setup  | `amd64`, `arm64` |

> Variants are defined in the `docker-bake.hcl` using the `VARIANTS` list.

## 🛠️ How to Build

### 1. Setup Buildx

```bash
docker buildx create --use
```

### 2. Build a Specific Variant

```bash
docker buildx bake cli
```

### 3. Build All Variants

```bash
docker buildx bake default
```

## 🧪 Example Usage

Extend from this image in your own `Dockerfile`:

```dockerfile
FROM smalswebtech/base-php:8.5-fpm

COPY . /app
WORKDIR /app

RUN composer install

CMD ["php-fpm"]
```

## 🏷️ Tags Generated

These are generated dynamically based on Git metadata and bake target.

- `smalswebtech/base-php:${PHP_VERSION}$-cli`
- `smalswebtech/base-php:${PHP_VERSION}$-fpm`
- `smalswebtech/base-php:${PHP_VERSION}$-apache`
- `smalswebtech/base-php:${PHP_VERSION}$-nginx`

> Optionally with `-dev` suffix (e.g. `:8.5.7-cli-dev`)

## 🚀 Releasing

Releases are semver and tied to **signed git tags**. Pushing a tag triggers `.github/workflows/docker.yml`, which bakes and pushes the multi-arch images (with SBOM + provenance attestation). All release/tag operations are driven from the `Makefile` and must be run from `main` or an `x.y` branch. The canonical remote is auto-detected (`origin`, or `upstream` when working from a fork), so the same commands work everywhere — run `make release-info` to see what was detected.

| Command | Purpose |
| --- | --- |
| `make release VERSION=x.y.z` | New version: signed `chore: prepare release` commit + signed tag + push + GitHub release with generated notes. |
| `make retag VERSION=x.y.z [REF=HEAD]` | Move an existing tag to a new commit (re-point a patch version), fire a fresh tag build, and refresh the release notes. |
| `make sync` | Fast-forward `main` + `8.4` from the canonical remote. |
| `make tag-restore VERSION=x.y.z` | Force-push the local tag to fix one that was moved to the wrong commit remotely. |
| `make notes VERSION=x.y.z [SINCE=x.y.z]` | Regenerate a release's notes from the previous tag. |
| `make build-version VERSION=x.y.z` | Trigger a build via `workflow_dispatch` without moving a tag. |

Destructive targets prompt for confirmation; pass `YES=1` to skip. Requires `git` and `gh`.

## 📬 Contact

Questions or improvements? [Open an issue](https://github.com/Smals-Webtech/base-php/issues) or reach out directly.
