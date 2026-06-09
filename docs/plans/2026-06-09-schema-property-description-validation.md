# Schema Property Description Validation

## Status

Completed

## Context

`spec.yaml` is the source API contract, and several checks already keep the
Markdown reference aligned with endpoints, responses, security schemes, and
shared errors. Schema properties also need explicit descriptions so generated
clients and readers understand field semantics without guessing from names.

## Objectives

- Keep validation dependency-free using Ruby's standard library.
- Fail when an OpenAPI schema property lacks a non-empty `description`.
- Add descriptions for existing inline response fields, identifier refs,
  feedback entries, and attachment fields.
- Record the completed validation guard under `docs/plans/`.

## Work Completed

- Extended `scripts/validate-openapi.rb` with a recursive schema-property
  description check across the full OpenAPI document.
- Added missing descriptions to `spec.yaml` without changing schema shapes.
- Updated README, VISION, SECURITY, and CHANGES notes for the description
  guard.

## Verification

- `scripts/validate-openapi.rb`
- `make check`
- `make verify`
- `git diff --check`
