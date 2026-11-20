# Security policy

## Supported versions

Two PHP lines are maintained, each from its own branch, and only their latest release is
supported:

| Line | Branch | Tags |
| --- | --- | --- |
| PHP 8.5 | `main` | `8.5-<variant>`, `8.5.x-<variant>` |
| PHP 8.4 | `8.4` | `8.4-<variant>`, `8.4.x-<variant>` |

A fix ships as a new release or as a re-publication of the current one: pull the floating tag
again, or bump your digest pin.

## Reporting a vulnerability

Use **Security → Report a vulnerability** on this repository (GitHub private vulnerability
reporting). Do not open a public issue for it.

In scope: what this repository adds to the image -- the Dockerfile, the entrypoint scripts, the
configuration templates and the way they are rendered. A flaw in PHP, Alpine, nginx, Apache or
another upstream component belongs to that project; tell us anyway if the image makes it easier to
reach.

[docs/cve-response.md](docs/cve-response.md) describes how an advisory is triaged and how the fix
reaches the published images.
