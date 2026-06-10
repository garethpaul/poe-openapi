# Security Scheme Description Validation

## Status

Completed

## Context

The validator already required `spec.md` to name each OpenAPI security scheme
and its concrete header or HTTP auth scheme. The YAML security scheme objects
themselves did not need descriptions, so generated OpenAPI docs could show
credential mechanics without explaining their intended use.

## Objectives

- Add non-empty descriptions to the configured security schemes.
- Extend `scripts/validate-openapi.rb` to fail when a security scheme is missing
  a description.
- Keep the existing Markdown security reference checks intact.
- Document the guard in README, SECURITY, VISION, and CHANGES.

## Work Completed

- Added descriptions for `ApiKeyAuth` and `BearerAuth` in `spec.yaml`.
- Added security-scheme description validation to the dependency-free Ruby
  validator.
- Recorded the completed validation guard under `docs/plans/`.

## Verification

- `scripts/validate-openapi.rb`
- `make check`
- `make verify`
- `git diff --check`
