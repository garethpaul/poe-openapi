# Component Schema Description Validation

## Status

Completed

## Context

`spec.yaml` already requires descriptions on schema properties, but shared
component schemas also need top-level descriptions. Without them, generated
documentation can explain individual fields while leaving the payload's purpose
ambiguous.

## Objectives

- Keep validation dependency-free using Ruby's standard library.
- Fail when an OpenAPI component schema lacks a non-empty `description`.
- Add descriptions for existing shared request, response, event, and error
  schemas without changing schema shapes.
- Record the completed validation guard under `docs/plans/`.

## Work Completed

- Extended `scripts/validate-openapi.rb` with a component-schema description
  check.
- Added top-level descriptions to existing component schemas in `spec.yaml`.
- Updated README, VISION, SECURITY, and CHANGES notes for the component-schema
  description guard.

## Verification

- `scripts/validate-openapi.rb`
- `make check`
- `make verify`
- `git diff --check`
