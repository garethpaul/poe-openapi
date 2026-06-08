# Response Status Reference Validation

## Status

Completed

## Context

`poe-openapi` keeps response status codes in both `spec.yaml` and `spec.md`.
The existing validator required common response codes in the OpenAPI contract,
but it did not detect when the Markdown endpoint reference omitted, duplicated,
or retained stale status codes.

## Objectives

- Keep validation dependency-free using Ruby's standard library.
- Parse each endpoint section's documented response status list from `spec.md`.
- Fail when YAML response status codes are missing from the Markdown reference.
- Fail when the Markdown reference documents duplicate or unknown response
  status codes.

## Work Completed

- Extended `scripts/validate-openapi.rb` to compare response status codes in
  `spec.yaml` with the matching endpoint section in `spec.md`.
- Generalized completed-plan checks so the validator records both canonical
  validation plans.
- Updated README, vision, and changelog notes for the response-status guard.

## Verification

- `make check`
- `scripts/validate-openapi.rb`
- `git diff --check`
