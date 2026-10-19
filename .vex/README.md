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
ever opened. The one flagged module is linked in, but not the vulnerable part of it:

| module | reached through | used here |
| --- | --- | --- |
| `golang.org/x/crypto` (`openpgp`) | nothing: gomplate imports only `bcrypt`, and no dependency links `openpgp` | no |

gomplate 5.3.0 fixed the go-git, gRPC and `x/crypto/ssh` findings that gomplate 5.2.0 carried
upstream, so their statements were dropped rather than carried over.

## How it is applied

The `scan` job in `.github/workflows/docker.yml` passes it to Trivy as `TRIVY_VEX`, so the SARIF
uploaded to the Security tab is already filtered, and prints the suppressed findings in the build log
with `TRIVY_SHOW_SUPPRESSED`. Locally:

```bash
trivy image --vex .vex/gomplate.openvex.json --show-suppressed <image>
```

## When to revisit it

- **A new gomplate release.** Subcomponents are pinned to the module versions gomplate 5.3.0 ships,
  so a bump makes the statements stop matching and the findings reappear — which is the intended
  failure mode, not a bug. Re-derive them against the new binary.
- **A new datasource scheme, or a template that fetches anything.** The moment a call site uses
  something other than `env:`, the table above is wrong and the document must be narrowed or dropped.
- **An advisory that is not listed.** Statements are per-CVE on purpose: a new finding in the same
  module surfaces normally.

Nothing here covers OS packages. Those are upstream's to fix and are left visible.
