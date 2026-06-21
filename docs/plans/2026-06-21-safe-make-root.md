# Safe Makefile Root Resolution

## Status Completed

## Context

The Makefile ignored `REPO_ROOT` overrides but trusted caller-controlled
`MAKEFILE_LIST`. Replacing that automatic variable redirected validation and
Markdown generation outside the reviewed OpenAPI checkout.

## Scope Boundaries

- Do not change `spec.yaml`, generated `spec.md`, paths, operations, schemas,
  examples, security requirements, or generator behavior.
- Preserve Ruby 3.4 and Ruby 4.0 hosted validation.
- Keep the regression suite independent of Ruby gems and live services.

## Work Completed

- Reject command-line and environment replacement of `MAKEFILE_LIST`.
- Canonicalize the checked-in Makefile directory through quoted POSIX tools.
- Add dependency-free shell coverage for all seven public Make targets.
- Include the root policy in `make verify` and `make check`.

## Verification Completed

- `make lint`, `make test`, `make build`, `make root-test`, `make verify`, and
  `make check` passed.
- All 21 target and `REPO_ROOT` override cases passed from a temporary checkout
  path containing spaces and an apostrophe.
- Command-line and environment `MAKEFILE_LIST` overrides failed closed.
- `spec.yaml` and `spec.md` remained byte-identical.
