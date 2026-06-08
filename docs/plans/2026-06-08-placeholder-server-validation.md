# Placeholder Server Validation Plan

## Status

Completed

## Context

`poe-openapi` uses `example.com` hosts in `spec.yaml` and `spec.md` to document
the protocol shape without claiming a maintained production deployment. The
repository also had completed engineering plans under top-level `plans/`, but
it was missing the canonical `docs/plans` location used by the maintenance
inventory.

## Objectives

- Add a completed canonical engineering plan under `docs/plans`.
- Keep `make check` as the local verification gate.
- Require example servers to be labeled as placeholders in both the OpenAPI YAML
  and Markdown reference.
- Preserve the existing endpoint, request-field, security-scheme, and
  error-response drift checks.

## Work Completed

- Added `docs/plans/2026-06-08-placeholder-server-validation.md`.
- Updated `spec.yaml` and `spec.md` so the `example.com` server entries are
  explicitly described as placeholders.
- Extended `scripts/validate-openapi.rb` to fail when an `example.com` server is
  not labeled as a placeholder in either contract surface.
- Updated README, vision, and changelog notes for the new validation baseline.

## Verification

- `make check`
- `scripts/validate-openapi.rb`
- `git diff --check`

## Follow-Up Candidates

- Add CI for `make check`.
- Generate `spec.md` from `spec.yaml` to remove manual drift risk.
- Replace placeholder hosts only when a maintained deployment exists.
