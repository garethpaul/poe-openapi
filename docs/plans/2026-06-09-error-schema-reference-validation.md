# Error Schema Reference Validation

## Status

Completed

## Context

`spec.yaml` defines a shared `Error` schema and the validator already requires
non-success operation responses to use it. The Markdown reference also has an
Error Handling section, but that section was not checked against the schema's
documented payload fields.

## Objectives

- Keep validation dependency-free using Ruby's standard library.
- Parse the Error Handling section from `spec.md`.
- Fail when a shared `Error` schema property is missing from that section.
- Update README, VISION, and CHANGES with the new validation guard.

## Work Completed

- Extended `scripts/validate-openapi.rb` to compare `Error` schema properties
  against the Markdown Error Handling section.
- Added this completed canonical engineering plan under `docs/plans/`.
- Preserved the existing operation, response-status, placeholder-server,
  security-scheme, and request-field checks.

## Verification

- `scripts/validate-openapi.rb`
- `make check`
- `make verify`
- `git diff --check`
