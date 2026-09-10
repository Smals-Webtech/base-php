# PHP Configuration

## How a directive is configured

Every `php.ini` directive is settable through an environment variable on the container. The name is
mechanical: upper case, and `.` becomes `_`.

| directive | variable |
| --- | --- |
| `memory_limit` | `PHP_MEMORY_LIMIT` |
| `opcache.memory_consumption` | `PHP_OPCACHE_MEMORY_CONSUMPTION` |
| `apc.shm_size` | `PHP_APC_SHM_SIZE` |
| `zend.exception_ignore_args` | `PHP_ZEND_EXCEPTION_IGNORE_ARGS` |

There is no list to consult and none to maintain: the image enumerates PHP's own directives at build
time — every core one, plus every directive of every extension it installs — and ships the result at
`/usr/local/share/base-php/ini-directives.list`. `cat` it in a running container to see exactly what
the PHP version you are on accepts. The repository keeps a copy at
`test/fixtures/ini-directives.list`, which a test compares against the image, so a PHP release that
adds or removes a directive shows up as a diff rather than as a surprise.

**Defaults come from `php.ini`.** The image ships `php.ini-production` in the `prd` variants and
`php.ini-development` in the `dev` ones, and it renders **only the directives you actually set**.
A directive you leave alone keeps PHP's own documented value — there is no third layer of defaults
between you and PHP.

**Your variable does not reach the application.** Every recognised `PHP_*` is unset just before the
supervisor is started, so `getenv('PHP_MEMORY_LIMIT')` is empty inside the application while
`ini_get('memory_limit')` returns what you asked for. That is deliberate: the container is
configured through the environment, the application is not.

Two consequences worth knowing:

- a `PHP_*` variable is what you **asked for**, not what is in force. A hook or a template that reads
  `PHP_MEMORY_LIMIT` sees nothing unless someone set it; ask PHP for the effective value instead;
- a `PHP_*` variable that matches no directive, no pool setting and no extension is named in the
  startup log, at `INFO`. A typo is otherwise invisible — it configures nothing, and it is not
  removed from the application environment either.

The scan directory (`PHP_INI_SCAN_DIR`, `/opt/etc/php/conf.d`) is where the rendered files land. It
is image plumbing, not a knob: pointing it elsewhere means nothing this container renders is read.

## Where the image departs from PHP

Eight directives, and only these, are set by the image itself. Each is still overridable.

| directive | value | why |
| --- | --- | --- |
| `expose_php` | `Off` | `php.ini` says `On`; the version banner is not worth advertising |
| `fastcgi.logging` | `Off` | otherwise every PHP notice is duplicated into the web server's log ([docker-library/php#1360](https://github.com/docker-library/php/pull/1360)) |
| `date.timezone` | `Europe/Brussels` | PHP falls back to UTC |
| `soap.wsdl_cache_dir` | `/app/tmp` | the default `/tmp` is not the writable path in a read-only container |
| `xdebug.output_dir` | `/app/tmp` | same |
| `xdebug.client_host` | `host.docker.internal` | the debugger runs on the host, not in the container |
| `xdebug.mode` | `off` | xdebug ships in every variant and stays inert until asked for |
| `xdebug.start_with_request` | `yes` | once a mode is set, use it on every request |

## Extensions

`PHP_EXT_INSTALL` lists what the image installs. Each name gets a switch, `PHP_<EXT>_ENABLED`, on by
default except `PHP_XDEBUG_ENABLED` and `PHP_OPENTELEMETRY_ENABLED`, which both cost real time per
request. Setting a switch to `false` keeps the extension on disk and out of the process.

A child image adds its own the ordinary way — `install-php-extensions <name>` in its `Dockerfile` —
and enables it with `PHP_EXT_INSTALL_CUSTOM=<name>`. Its directives are then configurable like any
other, and it loads from PHP's own extension directory.

`PHP_EXTENSION_DIR` exists like every other directive, and setting it is a trap: PHP would look for
its modules somewhere they are not.

## Rendering your own configuration

`/opt/config/php/conf.d` is a mount point. A gomplate template dropped there is rendered into
`/opt/etc/php/conf.d` at startup, next to the files the entrypoint writes:

```bash
docker run -v ./zz-myapp.ini.tmpl:/opt/config/php/conf.d/zz-myapp.ini.tmpl:ro …
```

A scan directory is read in alphabetical order, so a name sorting after `base-php-` wins over what
the entrypoint rendered. That is the way to force a value the mechanism will not give you.

## Deprecated

| variable | replacement | notes |
| --- | --- | --- |
| `PHP_BYPASS_INI_DEFAULT_VALUES` | — | Accepted and ignored, with a warning at startup. It existed to skip a startup probe that no longer exists: `php.ini` now supplies the defaults directly. |
| `PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES` | `PHP_MEMORY_LIMIT` | Value is converted automatically (`16` → `16M`). A warning is emitted at startup. |
