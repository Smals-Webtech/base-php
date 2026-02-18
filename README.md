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

### Core


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

| Environment Variable                      | Default (prd) | Default (dev) | Documentation                                                       |
|-------------------------------------------|---------------|---------------|---------------------------------------------------------------------|
| `PHP_FPM_MAX_CHILDREN`                    | `40`          | `40`          | [Link](https://www.php.net/manual/en/install.fpm.configuration.php) |
| `PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES` | `16`          | `16`          | [Link](https://www.php.net/manual/en/install.fpm.configuration.php) |

## 🪶 Apache Configuration

### Todo: Add explain about : `APACHE_ENABLED="true"`

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

> TODO

## 💨 Varnish Configuration

> TODO

## ☁️ AWS CLI Configuration

> TODO

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

> Optionally with `-dev` suffix (e.g. `:8.5.3-cli-dev`)

## 📬 Contact

Questions or improvements? [Open an issue](https://github.com/Smals-Webtech/base-php/issues) or reach out directly.
