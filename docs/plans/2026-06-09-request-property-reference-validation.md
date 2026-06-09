# Request Property Reference Validation

## Status

Completed

## Context

The OpenAPI validator already required required request-body fields to appear in
the Markdown endpoint reference. Optional top-level request properties could
still drift out of `spec.md`, leaving readers without documented controls such
as `temperature`, `headers`, `logit_bias`, or diagnostic `metadata`.

## Objectives

- Keep validation dependency-free using Ruby's standard library.
- Resolve each JSON request body to its component schema.
- Require every top-level request schema property, required or optional, to be
  named in the matching Markdown endpoint section.
- Document optional `/poe/query` and `/poe/report-error` properties in
  `spec.md`.
- Record the completed validation guard under `docs/plans/`.

## Work Completed

- Extended `scripts/validate-openapi.rb` to compare all top-level request
  schema properties against the matching `spec.md` endpoint section.
- Added Markdown request-body entries for optional Poe query controls and error
  report metadata.
- Updated README, VISION, SECURITY, and CHANGES notes for the request-property
  guard.

## Verification

- `scripts/validate-openapi.rb`
- `make check`
- `make verify`
- `git diff --check`
