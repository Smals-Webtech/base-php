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

### Fixed

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
  configure nothing *and* reach the application, in silence.
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

[Unreleased]: https://github.com/Smals-Webtech/base-php/compare/8.5.10...main
[8.5.10]: https://github.com/Smals-Webtech/base-php/compare/8.5.9...8.5.10
