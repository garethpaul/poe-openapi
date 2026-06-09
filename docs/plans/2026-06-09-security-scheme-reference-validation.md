# Security Scheme Reference Validation

## Status

Completed

## Context

`spec.yaml` defines reusable OpenAPI security schemes, but `spec.md` described
authentication in generic prose. That made it possible for the Markdown
reference to drift away from the concrete `ApiKeyAuth`, `BearerAuth`,
`X-API-Key`, and HTTP `bearer` names used by the contract.

## Objectives

- Keep validation dependency-free using Ruby's standard library.
- Parse the Markdown Security section from `spec.md`.
- Fail when a security scheme identifier is missing from the Markdown reference.
- Fail when an API key header or HTTP auth scheme is omitted from the Markdown
  reference.
- Record the completed validation guard under `docs/plans/`.

## Work Completed

- Extended `scripts/validate-openapi.rb` to compare OpenAPI security schemes
  against the Markdown Security section.
- Updated the Markdown Security section to name `ApiKeyAuth`, `BearerAuth`,
  `X-API-Key`, and `bearer` explicitly.
- Added README, VISION, and CHANGES notes for the security-scheme guard.

## Verification

- `scripts/validate-openapi.rb`
- `make check`
- `make verify`
- `git diff --check`
