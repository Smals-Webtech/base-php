# Renovate

Renovate opens the dependency-update pull requests for this repository. It runs from
`.github/workflows/renovate.yml` every Monday at 03:30 UTC, and on demand from the Actions tab. Setting
the repository variable `RENOVATE_DRY_RUN` to `lookup` turns every run into a dry run that lists what it
would update without touching anything; delete the variable to go live.

## What it tracks

- **The versions pinned in the `Dockerfile` and `docker-bake.hcl`**: PHP, the PECL extensions, Composer,
  gomplate, install-php-extensions, the Alpine packages (aws-cli, nginx) and Alpine itself. Each one
  lives in both files, under a `# renovate:` annotation that names its source. One pull request updates
  both places. To track a new pin, add the same annotation above the `ARG` and above the bake variable.
  The four extensions built from PECL read PECL's own release list (`custom.pecl`): Packagist can publish
  a version that PECL does not have yet, and the build would fail on it.
- **The `FROM` images** written out in full (`golang`), and the **GitHub Actions**, which it pins by commit.
- **The bats libraries** used by the tests, in `test/Makefile` and in the CI.

## The rules

- **Nothing merges by itself.** Every update is a pull request, and the image builds and suites run on it.
- **Each branch keeps its PHP minor**: `main` stays on 8.5.x, `8.4` on 8.4.x. A new minor is a release
  decision.
- **A new Alpine release, and any major version, wait for an approval** on the Dependency Dashboard issue.
- **An update that ships in the image adds a line under `[Unreleased]`** in `CHANGELOG.md`
  (`changelog-entry.sh`). Rewrite it if the change deserves more than a version number.
- **Merging is not releasing.** As before, what is merged reaches users with the next release or retag.

## How it runs

The workflow acts as the organisation's Renovate GitHub App. It needs the variable `RENOVATE_CLIENT_ID` and
the secret `RENOVATE_APP_PRIVATE_KEY`. Pull requests opened with `GITHUB_TOKEN` would not trigger the
image builds, and commits made through the App are signed by GitHub. It runs from this public repository,
so its Actions minutes cost nothing.
