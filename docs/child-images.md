# Building on this image

What an image built `FROM smalswebtech/base-php` can rely on, where it plugs its own configuration
in, and what it should leave alone. Each point links to the section that covers it in detail.

## What the image guarantees

- **Any uid.** The processes run as uid 1001 in group 0 by default, and under any other uid as
  well, including an arbitrary OpenShift uid or a `--user $(id -u):$(id -g)` build.
- **No root, no capability, no setuid binary.** Every variant runs under `--cap-drop=ALL` and
  `--security-opt no-new-privileges`, which is what OpenShift's `restricted-v2` SCC and the Pod
  Security `restricted` profile impose. The test suites assert it.
- **A read-only root filesystem.** Four runtime paths have to be writable: `/app/var`, `/app/tmp`,
  `/opt/sbin` (mounted `exec`) and `/opt/etc`. The `cli` variant needs only `/opt/etc` and `/app/tmp`.
  The image declares no `VOLUME`, so a child image may write there at build time. A missing or
  unusable mount stops the boot with the path named. See
  [Filesystem layout](../README.md#-filesystem-layout-and-read-only-design).
- **Configuration rendered at every start.** Everything under `/opt/etc` is regenerated from
  templates and environment variables on each start, and the environment is cleaned before the
  application runs: an image setting never reaches PHP as a variable.

## Where your own configuration goes

**`/opt/config` is the extension point.** Mount a gomplate template there, or add it in your image,
and it is rendered at every start next to the image's own files. A file without `{{ }}` is copied as
is.

| What | Put it in | Rendered to |
| --- | --- | --- |
| An nginx vhost | `/opt/config/nginx/sites-enabled/<name>.conf.tmpl` | `/opt/etc/nginx/sites-enabled/` |
| nginx `http`-level directives (`map`, `limit_req_zone`, `upstream`) | `/opt/config/nginx/http.d/<name>.conf.tmpl` | `/opt/etc/nginx/http.d/` |
| An apache vhost | `/opt/config/apache2/sites-enabled/<name>.conf.tmpl` | `/opt/etc/apache2/sites-enabled/` |
| apache server-level directives | `/opt/config/apache2/conf.d/<name>.conf.tmpl` | `/opt/etc/apache2/conf.d/` |
| A php-fpm pool | `/opt/config/php/php-fpm.d/<name>.conf.tmpl` | `/opt/etc/php/php-fpm.d/` |
| PHP ini directives the variables do not cover | `/opt/config/php/conf.d/<name>.ini.tmpl` | `/opt/etc/php/conf.d/` |
| A logrotate stanza | `/opt/config/logrotate/logrotate.d/<name>.conf.tmpl` | `/opt/etc/logrotate.d/` |
| A script supervisor runs | `/opt/config/sbin/<name>.sh.tmpl` | `/opt/sbin/` (executable) |
| The startup banner | `/opt/config/motd` | printed as is |

Only the first level of each directory is rendered: a template in a subdirectory of your own is not.
Read-only files that need no rendering, such as nginx snippets, can be mounted anywhere and included
from your vhost.

What the image's own vhost and pool set, and what yours has to repeat, is in
[child-vhosts-and-pools.md](child-vhosts-and-pools.md).

## Running your own code at startup

Files in `/opt/bin/container-entrypoint.d` run at three moments:

- **early hooks** (`entrypoint.d/*.sh`): before the environment is resolved, for
  `<VARIABLE>_WCMTECH_DEFAULT` defaults of your own;
- **boot hooks** (`boot.d/*.sh`, `boot.d/*.php`): at every start, after the image's rendering. Use
  them for anything you render into `/opt/etc`, for checks, and for idempotent migrations;
- **late hooks** (`*.sh`, `*.php`): once per `/app/var` volume.

Anything that must hold on every start belongs in a boot hook. A late hook is skipped whenever
`/app/var` outlives `/opt/etc`, and the container then runs without what it rendered. See
[Application startup hooks](../README.md#application-startup-hooks).

**Extensions.** Install them with `install-php-extensions`, name them in `PHP_EXT_INSTALL_CUSTOM`,
then run `update-ini-directives`, so their directives become settable through `PHP_*` variables like
the image's own. See [Adding custom extensions](../README.md#adding-custom-extensions-from-a-child-image).

## What to leave alone

- **Do not mount a file into `/opt/etc`.** It is the output of the rendering. To mount a single file,
  the runtime creates its parent directories as root, and an arbitrary uid can then no longer render
  the rest: the boot stops and names the cause. Mount the template under `/opt/config` instead. See
  [Mounting them from a ConfigMap](child-vhosts-and-pools.md#mounting-them-from-a-configmap).
- **Do not add templates to nginx's `conf.d`.** It belongs to the image: its files are rendered one by
  one and included by name, so a template added there is never loaded. Use `http.d`.
- **Do not override `nginx.conf` or `httpd.conf`.** The image changes them between releases. The
  extension points above cover what a child image needs. If one is missing, open an issue.
- **Do not expect image settings in the application's environment.** The entrypoint unsets them,
  AWS credentials included. The AWS configuration is file-based: see the AWS CLI section of the
  [`README.md`](../README.md).

## Pinning and updates

- **Tags move.** `8.5-nginx`, `8.5.12-nginx` and the other floating tags are re-published when the
  image is rebuilt for a fix with the same PHP version (a retag). Pin by digest
  (`smalswebtech/base-php:8.5-nginx@sha256:…`) to build reproducibly, and update the digest when the
  image publishes a fix.
- **A fix reaches you only when you rebuild.** Your published image keeps the base layers it was built
  with. The release notes say what a new build changes, at the top when operators must act. The
  steps on the image's side are in [cve-response.md](cve-response.md).

## Labels

The image sets `be.smals.webtech.base.version` (the PHP version) and `be.smals.webtech.base.release`
(the commit it was built from), among other labels. A child image inherits them. **Do not overwrite
them**: they are how anyone can tell, from the image alone, which base a child image was built on and
whether it lags behind a fix. Put your own image's metadata under your own prefix and in the
`org.opencontainers.image.*` keys.

## Testing a child image like the platform will run it

```bash
docker run --rm --read-only --user 12345:0 --cap-drop=ALL --security-opt no-new-privileges \
  --tmpfs /opt/etc --tmpfs /opt/sbin:exec --tmpfs /app/var --tmpfs /app/tmp \
  <your-image>
```

If it is healthy like this, it is healthy under an arbitrary uid with a read-only root and no
capability.
