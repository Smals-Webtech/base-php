# The release tooling

How a Smals-Webtech image repository writes its CHANGELOG, tags a release and publishes it. The
same four files do it in every repository, and base-php holds the reference copy of each:

| File | What it does |
| --- | --- |
| `.github/release.mk` | The release targets: `release-info`, `sync`, `lint`, `changelog`, `release-prepare`, `release`, `retag`, `release-refresh`, `tag-restore`, `notes`, `build-version` |
| `.github/release-prepare.sh` | Writes the CHANGELOG section of a release from the pull requests merged since the tag |
| `.github/changelog-deps.sh` | Lists the pinned dependencies that changed since the tag, as CHANGELOG lines |
| `.github/lint-local.sh` | Lints the whole tree with the CI's super-linter version and settings |

The files are copied, not fetched: a release needs nothing but the repository itself. They are
identical everywhere, byte for byte. What a repository does differently is set in its own
`Makefile`, before it includes `.github/release.mk`.

## A release

```bash
make sync                                   # the release branch, fast-forwarded
make release-prepare VERSION=x.y.z          # the CHANGELOG section, then the whole-tree lint
git diff CHANGELOG.md                       # read it; a sentence of prose if one helps
make release VERSION=x.y.z                  # commit, signed tag, push, GitHub release
```

A re-publication of an existing version (new base image, security fix, anything that does not
change the version) is `make release-prepare VERSION=x.y.z RETAG=1`, then `make retag
VERSION=x.y.z`: the tag moves to the new commit in a single push, which rebuilds and republishes
the image.

`release` refuses to run unless:

- the branch is one the repository releases from (`RELEASE_BRANCHES`, or `RELEASE_BRANCH` when the
  version decides it) and is the same commit as the remote's;
- the CHANGELOG has the version's section, written by `release-prepare`;
- `VERSION` is what the image builds, when the repository names it after a component
  (`VERSION_OF`);
- the tag exists neither locally nor on the remote, and no untracked file would be left out.

`retag` checks the branch and the version too, commits a prepared CHANGELOG (`chore: re-publish
x.y.z`), and refreshes the GitHub release. When that refresh cannot reach the API, the tag is
pushed all the same and `make release-refresh VERSION=x.y.z` finishes the job.

## What the CHANGELOG gets

`release-prepare.sh` writes, under the version:

- one line per pinned dependency that changed, from `changelog-deps.sh`: the `# syntax=`
  frontend, every `ARG *_VERSION_ARG` and every `docker-bake.hcl` `variable "*_VERSION"` (an ARG
  and the bake variable of the same name are one pin), and the base images pinned by digest;
- one line per pull request merged since the previous tag of the same major line, from its title:
  `feat` under Added, `fix` under Fixed, `perf`, `refactor` and `revert` under Changed. A squash
  merge has the title in its subject, a merge commit in its body. `chore`, `ci`, `docs`, `test` and
  `build` titles do not change the image and are left out;
- on its output, the commits it could not record (a rebase merge, a direct commit), for a line to
  be written by hand.

A pull request that changes only the tooling is titled `chore(release): ...`, so it stays out of
the image's CHANGELOG.

## What each repository sets

In its `Makefile`, before `include .github/release.mk`:

| Variable | Meaning | Default |
| --- | --- | --- |
| `RELEASE_BRANCHES` | The branches a release is made from | `main` |
| `RELEASE_BRANCH` | The one branch a version is released from, when the version decides it | any of `RELEASE_BRANCHES` |
| `VERSION_OF` | The `docker-bake.hcl` variable the version must equal (and the Dockerfile's `<VERSION_OF>_ARG` when it has a value) | none: the version is the image's own |
| `CHANGELOG_DEP_NAMES` | `X_VERSION_ARG=Name ...`: the name a dependency line gives to a pin without a `# renovate: depName=` annotation | the variable's name |
| `CHANGELOG_DEPS_TITLES` | `keep`: Renovate's `chore(deps)` titles are kept, for dependencies `changelog-deps.sh` cannot read | dropped: the dependency lines cover them |

| Repository | `RELEASE_BRANCHES` | `RELEASE_BRANCH` | `VERSION_OF` | Other |
| --- | --- | --- | --- | --- |
| base-php | `main 8.4` | | `PHP_VERSION` | |
| adminer | `main` | | `ADMINER_VERSION` | `CHANGELOG_DEP_NAMES` |
| base-nginx | `main` | | `NGINX_VERSION` | `CHANGELOG_DEP_NAMES` |
| limesurvey | `7.x 6.x` | `<major>.x` | `LIMESURVEY_VERSION` | `CHANGELOG_DEP_NAMES` |
| nginx-s3-gateway | `main` | | | |
| restic-backup | `main` | | | `CHANGELOG_DEP_NAMES` |
| prometheus-s3-exporter | `main` | | | `CHANGELOG_DEPS_TITLES = keep` (its dependencies are Python packages) |

## Changing a shared file

1. Change it in base-php, with its tests: `test/release-prepare.bats` and `test/release-mk.bats`
   run on throwaway repositories, with a fake `gh` and a fake `gpg`.
2. `make tooling-check` runs those tests, then compares the four files with the sibling checkouts
   (next to base-php and under `../../smals`; `TOOLING_SIBLINGS="dir ..."` to choose) and lists
   each copy that differs or is missing.
3. Copy the files into each repository, one pull request each, titled `chore(release): ...`.
   `make tooling-check` reports them in line once merged.

Never change a shared file in another repository first: the next copy from base-php would undo
it.
