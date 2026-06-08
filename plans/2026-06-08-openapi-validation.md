# OpenAPI Validation Gate

## Status

Completed

## Context

`poe-openapi` contains an OpenAPI YAML contract and a Markdown reference, but it
had no local command to detect drift between them. The Markdown reference listed
endpoints and methods but did not expose the operation IDs from `spec.yaml`.

## Objectives

- Parse `spec.yaml` with Ruby's standard YAML library.
- Confirm documented endpoints and operation IDs stay aligned with `spec.md`.
- Check that referenced security schemes exist.
- Check that common non-2xx responses use the shared `Error` schema.
- Provide `make verify` as a single local gate.

## Verification

- `make verify`
- `scripts/validate-openapi.rb`
- `git diff --check`

## Follow-Up Candidates

- Add CI for `make verify`.
- Add example request and response fixtures for each operation.
- Generate `spec.md` from `spec.yaml` instead of hand-maintaining both files.
