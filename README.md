# 🐘 PHP Base Image – smalswebtech/base-php

This repository provides a **production-ready, multi-variant PHP base image** built on Alpine and PHP 8.4.10, ideal for extending with any PHP application or framework (Laravel, Symfony, WordPress, etc.).

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

## 🐘 PHP Configuration

The PHP image ships with all required extensions pre-installed, but it’s designed to run in read-only mode at runtime.  
To enable dynamic configuration, a writable volume is mounted and used as the active PHP configuration directory. During container startup, the entrypoint generates configuration files via gomplate and sets `PHP_INI_SCAN_DIR` to point to this writable path.  

All installed extensions are symlinked by default from their actual `.so` locations into this writable directory. Each extension’s activation can be controlled via a corresponding environment variable (e.g., `PHP_APC_ENABLED=false` disables `apcu`). When enabled, the entrypoint also generates the appropriate `.ini` configuration file for the extension within the writable volume.

This mechanism provides full flexibility at startup while keeping the base image immutable and compatible with read-only filesystem deployments.

| Extension | Environment Variable | Default Enabled | Configuration | Documentation |
| --------- | -------------------- | --------------- | ------------- | ------------- |
| `apcu` | PHP_APC_ENABLED | "true" | [Link](docs/php.md#apcu) | [Link](https://www.php.net/manual/en/book.apcu.php) |
| `bcmath` | PHP_BCMATH_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/book.bc.php) |
| `bz2` | PHP_BZ2_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/book.bzip2.php) |
| `calendar` | PHP_CALENDAR_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/book.calendar.php) |
| `exif` | PHP_EXIF_ENABLED | "true" | [Link](docs/php.md#exif) | [Link](https://www.php.net/manual/en/book.exif.php) |
| `gd` | PHP_GD_ENABLED | "true" | [Link](docs/php.md#gd) | [Link](https://www.php.net/manual/en/book.image.php) |
| `gettext` | PHP_GETTEXT_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/book.gettext.php) |
| `intl` | PHP_INTL_ENABLED | "true" | [Link](docs/php.md#intl) | [Link](https://www.php.net/manual/en/book.intl.php) |
| `ldap` | PHP_LDAP_ENABLED | "true" | [Link](docs/php.md#ldap) | [Link](https://www.php.net/manual/en/book.ldap.php) |
| `mysqli` | PHP_MYSQLI_ENABLED | "true" | [Link](docs/php.md#mysqli) | [Link](https://www.php.net/manual/en/book.mysqli.php) |
| `opcache` | PHP_OPCACHE_ENABLED | "true" | [Link](docs/php.md#opcache) | [Link](https://www.php.net/manual/en/book.opcache.php) |
| `opentelemetry` | PHP_OPENTELEMETRY_ENABLED | "false" | [Link](docs/php.md#opentelemetry) | [Link](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| `pcntl` | PHP_PCNTL_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/book.pcntl.php) |
| `pdo_mysql` | PHP_PDO_MYSQL_ENABLED | "true" | [Link](docs/php.md#mysql-pdo-driver) | [Link](https://www.php.net/manual/en/ref.pdo-mysql.php) |
| `pdo_pgsql` | PHP_PDO_PGSQL_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/ref.pdo-pgsql.php) |
| `pgsql` | PHP_PGSQL_ENABLED | "true" | [Link](docs/php.md#postgresql) | [Link](https://www.php.net/manual/en/book.pgsql.php) |
| `redis` | PHP_REDIS_ENABLED | "true" | [Link](docs/php.md#redis) | [Link](https://github.com/phpredis/phpredis/) |
| `soap` | PHP_SOAP_ENABLED | "true" | [Link](docs/php.md#soap) | [Link](https://www.php.net/manual/en/book.soap.php) |
| `sodium` | PHP_SODIUM_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/book.sodium.php) |
| `tidy` | PHP_TIDY_ENABLED | "true" | [Link](docs/php.md#tidy) | [Link](https://www.php.net/manual/en/book.tidy.php) |
| `xdebug` | PHP_XDEBUG_ENABLED | "false" | [Link](docs/php.md#xdebug) | [Link](https://xdebug.org/) |
| `xsl` | PHP_XSL_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/book.xsl.php) |
| `zip` | PHP_ZIP_ENABLED | "true" | No Configuration Yet | [Link](https://www.php.net/manual/en/book.zip.php) ||

## 📦 Available Variants

| Tag                                            |  Description              | Platform(s)            |
|------------------------------------------------|---------------------------|------------------------|
| `smalswebtech/base-php:${PHP_VERSION}$-cli`    | PHP CLI only              | `amd64`, `arm64`       |
| `smalswebtech/base-php:${PHP_VERSION}$-fpm`    | PHP-FPM engine            | `amd64`, `arm64`       |
| `smalswebtech/base-php:${PHP_VERSION}$-apache` | Apache + PHP-FPM setup    | `amd64`, `arm64`       |
| `smalswebtech/base-php:${PHP_VERSION}$-nginx`  | Nginx + PHP-FPM setup     | `amd64`, `arm64`       |

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
FROM smalswebtech/base-php:8.4.10-fpm

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

> Optionally with `-dev` suffix (e.g. `:8.4.10-cli-dev`)

## 📬 Contact

Questions or improvements? [Open an issue](https://github.com/Smals-Webtech/base-php/issues) or reach out directly.
