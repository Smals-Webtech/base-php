<!-- markdownlint-configure-file { "MD024": { "siblings_only": true } } -->
<!-- Keep a Changelog repeats "### Added" and "### Fixed" under every version, which MD024 flags by
     default. siblings_only narrows it to duplicates under the SAME parent, which is the case that
     actually signals a mistake. Scoped to this file: a .markdownlint.yml at the root would replace
     super-linter's bundled defaults wholesale and re-enable rules the other documents rely on. -->

# Changelog

All notable changes to this image are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). A version here is the
PHP version the image ships: releasing `8.5.10` means "PHP 8.5.10, with these image changes". An image
change that carries no new PHP moves the existing tag rather than creating one, so a version can be
re-published — the entry says when, and what changed.

This file is the durable copy of what a release says. The GitHub release notes are regenerated from
the previous tag by `make retag` and `make notes`, which discards anything hand-written in them; what
is written here survives.

This file is **branch-specific**, like the `php.ini` files: `main` tracks PHP 8.5, the `8.4` branch
tracks PHP 8.4, and a backport rewrites its section rather than cherry-picking it.

## [Unreleased]

### Added

- **OCI labels.** The images carry the standard `org.opencontainers.image.*` keys — `created`,
  `title`, `description`, `url`, `source`, `revision`, `version`, `vendor` — next to the
  `be.smals.webtech.base.*` ones, which stay. Registries, scanners and Renovate read these to link an
  image back to this repository and its exact commit.

### Removed

- **The empty `/app/var/run/supervisord.pid` shipped in the image.** supervisord creates and
  rewrites its pidfile at every start; the copy baked into the image was never read.

## [8.5.11]

PHP 8.5.11. Most of the image changes below first reached users by moving the `8.5.10` tag, before
this PHP release gave them a version of their own.

Re-published twice on 2026-09-28 — boot hooks and the late-hook fingerprint, then the throttling
include for child vhosts and its documentation. Each moved the `8.5.11` tag to a newer commit, so an
image pulled before that date differs from one pulled after. **A persistent `/app/var` re-runs its
late hooks once** after the upgrade; see _Changed_ below.

### Added

- **A child image's vhost can be throttled.** The soft-throttling zones were declared for the whole
  of nginx but enforced in the image's default server only, so a vhost added by a child image was
  never throttled, whatever `NGINX_SOFT_THROTTLE_ENABLED` said (measured on elasticms: 0 of 30
  requests rejected, against 27 on the default server). A server block now opts in with
  `include /opt/etc/nginx/conf.d/throttling-server.conf;`, the file the default server uses too. It
  always exists and is empty of directives while throttling is off. Nothing changes for a vhost that
  does not include it.
- **What a child image's own vhost and pool must repeat.** `docs/child-vhosts-and-pools.md` lists what
  the image's settings reach on their own (nginx's `http` level, php-fpm's `[global]` section) and
  what they do not (the default server, the `[www]` pool), with a vhost and a pool to start from.
  Found through elasticms, whose pools had no `request_terminate_timeout` and whose vhosts were
  never throttled.
- **Boot hooks: `/opt/bin/container-entrypoint.d/boot.d/`.** A child image had nowhere to run code
  at every start after the image's own rendering: late hooks run once per `/app/var` volume, so a
  configuration a child rendered from one was lost whenever `/opt/etc` was emptied and `/app/var`
  was not, and the container served without it. Boot hooks run at every start, after the image's
  rendering and before the late hooks, exactly like late hooks otherwise, without their lock. An
  image with no `boot.d` directory starts exactly as before.
- **The image builds behind a corporate proxy and a TLS-inspecting CA.** `HTTP_PROXY`, `HTTPS_PROXY`
  and `NO_PROXY` (either case) are passed to the build as BuildKit arguments, and `CUSTOM_CA_BUNDLE`
  names a PEM file that is **added** to the trust store of the steps that download — mounted as a
  build secret, never written into a published layer. `CA_BUNDLE_SHA` ties the cached layer to the
  CA's content, `NO_CACHE=true` forces a cache-less build, and `ENABLE_ATTESTATIONS=false` skips the
  provenance and SBOM attestations a local registry may refuse. Without these variables the build is
  unchanged.
- **Late init hooks are told what the application will not see.** They receive `CLEANUP_VAR_LIST`,
  the colon-separated names the image unsets before the application starts — its ini directives,
  pool settings, extension switches, AWS settings and every `<NAME>_WCMTECH_DEFAULT` a child image
  declared. A hook that hands variables to the application on its own (php-fpm `env[]` entries, a
  dotenv file) leaves those out. The variable lives in the hook's environment only.

- **Findings the image cannot reach are declared, not hidden.** `.vex/gomplate.openvex.json` is an
  OpenVEX document stating, per advisory, that the ten `go-git`, `x/crypto` and `grpc` findings in
  `/usr/bin/gomplate` are `not_affected`: those modules arrive behind the `git://`, `gs://` and SSH
  datasource schemes, and this image invokes gomplate with `env:` datasources only. Trivy filters
  them out of the SARIF and prints what it suppressed in the build log. Measured on
  `8.5.10-fpm`: 5 HIGH before, 0 after, with the 20 OS-package findings untouched. `.vex/README.md`
  carries the reasoning and the conditions that invalidate it.
- **The published `prd` images are scanned for vulnerabilities** on every push that publishes, and
  the results land in the repository's Security tab — one category per variant, so `cli`, `fpm`,
  `apache` and `nginx` do not overwrite each other. `CRITICAL` and `HIGH` only, unfixed advisories
  filtered out. Nine findings on the `cli` image the day it was switched on, all in the bundled
  tooling rather than in PHP.
- **This file.** The GitHub release notes are regenerated from the previous tag by `make retag` and
  `make notes`, which discards anything written into them by hand; what is written here survives.

### Changed

- **The late hooks' fingerprint covers their subdirectories.** A late hook commonly sources its
  steps from a directory of its own (`limesurvey.d/`, `drupal.d/`, `elasticms.d/`), and only the
  top-level files were hashed: an image that changed a step and nothing else never ran it on a
  volume that had already run the hooks. Every file under a subdirectory now counts, except
  `entrypoint.d/` and `boot.d/`. **On upgrade, a persistent `/app/var` re-runs its late hooks once**,
  since the fingerprint changes; they are expected to be re-runnable. On an ephemeral `/app/var`
  (`emptyDir`, `tmpfs`) they already run at every start, and nothing changes.

### Fixed

- **Any uid can write `HOME`.** `/home/default` was `2755` to uid 1001, so an arbitrary OpenShift
  uid, a bare `-u 1000` or a `--user uid:gid` pair could not create `~/.npm`, `~/.cache` or
  `~/.config`: npm failed on its cache before doing anything. It is now world-writable and sticky,
  like the runtime directories, and keeps its setgid bit (`3777`).
- **The OpenSSL the image reports is the one it runs.** Node was brought in by copying the node
  image's `/usr/lib` over the Alpine one, which silently downgraded OpenSSL 3.5.8 to 3.5.7 and left
  the apk database describing packages that were no longer there, so a scanner reading it reported
  the wrong versions. Only the Node runtime is copied now, and its two runtime libraries come from apk.
- **The `cli` base layer stops on a failing command.** Its `RUN` read `set eux;` without the dash,
  which sets the positional parameters and no option.
- **The image scan uploads only the severities it says it does.** `aquasecurity/trivy-action`
  ignores its `severity` input when the output format is SARIF unless
  `limit-severities-for-sarif` is set, so the Security tab was filling with `MEDIUM` and `UNKNOWN`
  findings that the job's own table step never showed. Measured on `8.5.10-fpm`: 25 findings
  uploaded where the declared filter allows 5.
- **`make release` no longer tags a tree that has no release commit.** `git commit ... || echo "No
  changes to commit."` swallowed every failure, not just an empty tree: a locked GPG agent made the
  signature fail, the target printed that message and carried on to tag. Measured: the old form exits
  `0` on a signing failure, the new one `128`.
- **`make release` refuses to start with untracked files present.** `git commit -a` stages tracked
  files only, so a file that was never added would be released without being committed.

## [8.5.10]

Re-published three times after the initial release: 2026-09-09 (late-hook helpers, startup banner),
2026-09-10 (request time limits), 2026-09-11 (the ini machinery). Each moved the `8.5.10` tag to a
newer commit, so an image pulled before those dates differs from one pulled after.

### Changed

- **php.ini supplies the defaults.** The image used to render 190 directives at startup, most of them
  restating the value `php.ini` already had; it now renders **only what the operator sets** and lets
  `php.ini-production` / `php.ini-development` supply the rest. Two consequences: a `PHP_*` variable
  now carries what you asked for rather than the value in force — a hook or template reading
  `PHP_MEMORY_LIMIT` finds nothing unless someone set it, so ask PHP for the effective value — and
  `extension_dir` is PHP's own directory again, the `/opt/etc/php/extensions` symlink farm being gone.
  159 directives became settable that were not (`error_log`, `allow_url_fopen`,
  `display_startup_errors`, `assert.*`, `filter.*`, `session.*`), and the list the image accepts ships
  at `/usr/local/share/base-php/ini-directives.list`.
- **A `PHP_*` variable that matches no directive is named at `INFO`** on startup. A typo used to
  configure nothing _and_ reach the application, in silence.
- **`docker run --read-only` without mounts refuses to start.** The image no longer declares `VOLUME`,
  so `/opt/etc`, `/opt/sbin`, `/app/tmp` and `/app/var` are yours to provide; the entrypoint names each
  unusable path and prints the `--tmpfs` line to add. A container started without `--read-only` is
  unaffected.
- **Apache monitoring endpoints moved to port 9090**, as nginx already did. `/server-status`,
  `/status` and `/real-time-status` answer `404` on the application port.
- **The nginx monitoring port serves monitoring and nothing else.** It used to fall back to the
  application docroot with no PHP handler, returning PHP source and dotfile contents to anyone able to
  reach it. Dotfiles are denied on the application port too.
- **php-fpm drains in-flight requests on shutdown**, waiting up to 15s. Kubernetes and OpenShift need
  nothing; a plain `docker stop` wants `-t 30` and compose wants `stop_grace_period: 30s`.
- **Any exit of nginx, php-fpm or apache stops the container**, including exit code 0.
- **A variable set by a late init hook no longer reaches the application.** Late hooks run as child
  processes, so a hook ending in `exit 0` no longer kills the container silently and a failing one is
  reported with its name. Use an early hook to inject a variable — those are still sourced.
- **The php-fpm slowlog is `php-fpm-slow.log`**, no longer `php-fpm.log.slow`, which fell outside the
  rotation glob and was never rotated.

### Fixed

- **A web request is bounded in time again.** `max_execution_time` was rendered as `0` — the CLI
  SAPI's own value, picked up by the startup probe — and `request_terminate_timeout` was `0`, so
  nothing stopped a runaway or a blocked request. Measured: with a 5s limit set, a script in
  `sleep(20)` still answered `200` after 20.04s, and php-fpm still reported the worker as active 25s
  after the caller had been interrupted. They are now the `php.ini` values (30s, 60s) and 75s, above
  nginx's 65s and apache's 60s.
- **Late hooks get the entrypoint helper functions back.** A hook calling `log` failed with
  `log: command not found` and the boot was refused.
- **The startup banner survives a web console that collapses runs of spaces**, and `print-banner`
  became a helper a child image can use for its own art. A banner path that is a directory — what a
  bind mount leaves when its source is missing — is now an error that names the path instead of a
  silent no-op.
- **nginx worker count follows the container's CPU quota** instead of the host's core count.
- **The FastCGI buffer knobs are wired.** `NGINX_FASTCGI_BUFFER_SIZE` and friends were declared,
  documented, and read by no template; a response header above 4 KB answered `502`.
- **PHP requests are logged.** nginx had `access_log off` in the PHP location and the apache vhost
  logged to `/dev/null`.
- **`zend.exception_ignore_args` follows `php.ini-development`** in the dev image, so stack traces
  show the arguments a call was made with.
- **A reused `/opt/etc` no longer poisons the configuration.** The startup probe read back the
  previous run's rendered files, so a removed override kept applying and every extension symlink was
  recreated pointing at itself.

[Unreleased]: https://github.com/Smals-Webtech/base-php/compare/8.5.11...main
[8.5.11]: https://github.com/Smals-Webtech/base-php/compare/8.5.10...8.5.11
[8.5.10]: https://github.com/Smals-Webtech/base-php/compare/8.5.9...8.5.10
