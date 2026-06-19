# Supported Ruby Matrix

## Status

Completed

## Context

The dependency-free OpenAPI validator still treats end-of-life Ruby 2.7 as a
compatibility floor and pairs it with Ruby 3.3, which entered security-only
maintenance in April 2026. Ruby's official branch policy lists Ruby 3.4 and
Ruby 4.0 in normal maintenance, with Ruby 4.0 as the current stable line.

The validator uses only standard-library Ruby and portable shell, so obsolete
runtime coverage adds maintenance risk without protecting a dependency or
published library contract.

## Objectives

- Replace the Ruby 2.7/3.3 hosted matrix with supported Ruby 3.4/4.0 lanes.
- Prove the complete validator and mutation suite on both maintained runtimes.
- Make the baseline checker reject obsolete, missing, duplicated, or spoofed
  runtime lanes and incomplete plan evidence.
- Preserve immutable actions, credential-free checkout, read-only permissions,
  bounded concurrency, timeout, offline behavior, and the exact OpenAPI spec.
- Update operator and security documentation to state the supported runtime
  policy and official maintenance basis.

## Implementation Units

### Hosted Runtime Policy

Files: `.github/workflows/check.yml` and `scripts/check-baseline.sh`.

Use one exact Ruby 3.4/4.0 matrix and reject unsupported Ruby versions, matrix
duplicates, workflow sprawl, policy weakening, or missing completed evidence.

### Documentation

Files: `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, and
this plan.

Record the maintained runtime floor and retain the validator's dependency-free,
offline, self-contained contract.

## Work Completed

- Replaced the exact hosted matrix with Ruby 3.4 and Ruby 4.0 lanes while
  preserving the pinned actions, credential-free checkout, read-only
  permissions, bounded concurrency, timeout, and sole `make check` command.
- Registered this plan with both the validator and baseline required-file
  inventory.
- Added static policy checks for the maintained runtime documentation and the
  complete byte-for-byte workflow contract.
- Updated contributor, security, vision, README, and changelog documentation
  without changing the OpenAPI contract or validator semantics.

## Verification Completed

- Ruby 3.4.9 and Ruby 4.0.5: network-isolated `make check` passed.
- Ruby 3.4.9 and Ruby 4.0.5: direct validator, mutation suite, and
  `ruby -w -c scripts/validate-openapi.rb` passed.
- `sh -n scripts/check-baseline.sh scripts/test-validator.sh` passed.
- `dash -n scripts/check-baseline.sh scripts/test-validator.sh` passed.
- `git diff --check` passed.
- Base and working-tree SHA-256 hashes match for `spec.yaml` and `spec.md`.
- Hostile workflow, runtime, documentation, validator inventory, and plan
  mutations are exercised after the implementation is complete.
- Canonical hosted checks are recorded separately against the exact pushed
  successor head; they are not claimed by this local verification record.

## Boundaries

- Do not change `spec.yaml`, `spec.md`, validation semantics, response schemas,
  security schemes, or server URLs.
- Do not add gems, Bundler state, network calls, or live-service tests.
- Preserve the existing remediation PR and exact evidence.
