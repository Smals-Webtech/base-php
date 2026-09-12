# VEX

`gomplate.openvex.json` is an [OpenVEX](https://github.com/openvex/spec) document. It records, per
advisory, that a vulnerability Trivy reports in `/usr/bin/gomplate` is **not reachable in this
image**, so the scan stops raising it.

It is not a mute button. Each statement names the feature that pulls the vulnerable module in, and
why this image never exercises it. Read them before trusting them.

## What the statements rest on

`gomplate` is invoked in exactly one shape here — seven call sites in
`bin/container-entrypoint.d/`, all of the form:

```bash
gomplate -f <template> -d <name>=env:/<VAR>?type=application/json -o <output>
```

`env:` is the only datasource scheme used, and the templates use `if`, `range`, `{{ . }}` and
`strings.ToLower`. Nothing reaches the network, and no repository, object store or secret store is
ever opened. The three flagged modules arrive transitively behind datasource schemes that are not
used:

| module | reached through | used here |
| --- | --- | --- |
| `github.com/go-git/go-git/v5` | the `git://`, `git+https://`, `git+ssh://` datasources | no |
| `golang.org/x/crypto` (ssh, openpgp) | go-git's SSH transport; `bcrypt` is the only part gomplate imports directly | no |
| `google.golang.org/grpc` | the Google Cloud client libraries behind the `gs://` datasource | no |

## How it is applied

The `scan` job in `.github/workflows/docker.yml` passes it to Trivy as `TRIVY_VEX`, so the SARIF
uploaded to the Security tab is already filtered, and prints the suppressed findings in the build log
with `TRIVY_SHOW_SUPPRESSED`. Locally:

```bash
trivy image --vex .vex/gomplate.openvex.json --show-suppressed <image>
```

## When to revisit it

- **A new gomplate release.** Subcomponents are pinned to the module versions gomplate 5.2.0 ships,
  so a bump makes the statements stop matching and the findings reappear — which is the intended
  failure mode, not a bug. Re-derive them against the new binary.
- **A new datasource scheme, or a template that fetches anything.** The moment a call site uses
  something other than `env:`, the table above is wrong and the document must be narrowed or dropped.
- **An advisory that is not listed.** Statements are per-CVE on purpose: a new finding in the same
  module surfaces normally.

Nothing here covers OS packages. Those are upstream's to fix and are left visible.
