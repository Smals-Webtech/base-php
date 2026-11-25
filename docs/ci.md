# The image workflow

What `.github/workflows/docker.yml` builds, tests and publishes, depending on what started it. The
release commands are in the [`README.md`](../README.md#-releasing), and what to do about an advisory
in [cve-response.md](cve-response.md).

## What each run does

| Run | Started by | Platforms | Targets | Cache | Suites | Publishes |
| --- | --- | --- | --- | --- | --- | --- |
| Pull request | a pull request into `main` or `x.y` | amd64 | all 8 | read | prd: full; dev: tests tagged `dev` | no |
| Merge | a push to `main` or `x.y` | amd64 | the 4 `-prd` | read, then written | none | no |
| Refresh | `cache-refresh.yml`, Sundays 20:00 UTC, or by hand | amd64 + arm64 | all 8 | not read; written (amd64) | amd64: full; arm64: tests tagged `dev` | no |
| Release | a tag, or `make build-version` | amd64 + arm64 | all 8 | not read | amd64: full; arm64: tests tagged `dev` | yes, then the `scan` job |

- **One job per platform.** A single bake builds every target, so the stages they share (`fpm-prd`
  under nginx, apache and the dev images) are built once.
- **A merge only feeds the cache.** Its pull request built and tested the same content, so the merge
  builds the prd targets, writes their layers for the next pull requests, and stops there. Nothing
  unreleased is published.
- **arm64 is built by releases and the refresh only.** Its runner runs the tests tagged `dev`
  (versions, health, FastCGI) as a smoke test, so an arm64 image that builds but does not start is
  never published.
- **A release is built without the cache.** The layer cache is keyed on the instruction, not on what
  it installs: a cached `apk add` would publish last week's packages again. The suites run on the
  images just pushed by digest, and the tags are created only once both platforms pass. A failure
  publishes nothing.
- **Files that do not reach the image build nothing**: `docs/`, `*.md`, `Makefile`, `.vex/`, the
  repository settings and the other workflows (the list in the `prepare` job). The workflow still
  starts, skips `build`, and its `image` job passes: `image` is the check branch protection
  requires, since a skipped matrix job reports under its bare name. Tags always build.

## The cache

GitHub's Actions cache, one scope per target and branch (`nginx-prd-refs/heads/main-linux/amd64`).
A build reads its branch's scope and `main`'s, for its target and for its prd counterpart, since a
dev image is built from the prd one. Only merges and the refresh write, on amd64 only: nothing reads
the cache on arm64.

The refresh rebuilds `main` and every `x.y` branch from scratch each week, so the cache is never more
than a week behind the Alpine and PECL packages. To refresh a branch now:

```bash
gh workflow run docker.yml --ref main -f refresh=true
```

## The `dev` tag

Tests marked `# bats test_tags=dev` cover what the dev images add over prd, plus a start-up check:
PHP, npm, PECL, GitHub CLI and Composer versions, container health, PHP-FPM over FastCGI. They are
the whole dev suite of a pull request and the arm64 smoke test. Tag a new test only if it belongs
there; every test runs in full on amd64 for a release and a refresh.

A local run is not filtered: `bats tests.web.bats` runs everything, and `--filter-tags dev` gives
the subset. `make test-images` runs the three suites the way the CI does.

## When a run fails

- **A network error** while downloading (PECL, `proxy.golang.org`): re-run the failed job. On a
  release it rebuilds that platform from scratch, about 10 to 15 minutes.
- **A failing suite**: each suite's log is a group at the end of the "Test images" step, and an
  annotation names the suite. The three variants run side by side, each four tests at a time
  (`bats --jobs 4`), so the step prints nothing until they finish.

## The lint

`lint.yaml` runs super-linter on pull requests only, on the files the pull request changes; a merge
lints nothing, since its pull request did. A pull request that changes the lint configuration
(`lint.yaml`, `.markdown-lint.yml`, `.github/lint-local.sh`) lints the whole tree, and so does a
`workflow_dispatch`.

The whole tree is linted locally before every release: `make release-prepare` runs
`.github/lint-local.sh` and stops on a finding, before the tag. `make lint` runs it on demand. The
script reads the super-linter version and settings from `lint.yaml`, and lints the tracked files
as they are in the working copy, so the CHANGELOG `release-prepare` just wrote is linted too. The
script and the release targets are shared with the other image repositories:
[release-tooling.md](release-tooling.md).
