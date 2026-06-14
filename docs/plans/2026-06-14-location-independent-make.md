---
title: Location-Independent Make Gates
type: fix
date: 2026-06-14
---

# Location-Independent Make Gates

## Status Completed

## Summary

Make OpenAPI validation, Markdown generation, and mutation suites target the
repository that owns the Makefile from any caller directory.

## Problem Frame

Every Make recipe currently launches a caller-relative script, and the
`generate` target also declares caller-relative file prerequisites. Absolute
Makefile invocation therefore fails before the portable tools can validate or
generate the specification.

## Requirements

- R1. Derive an override-protected absolute repository root from the loaded
  Makefile.
- R2. Root check, generate, lint, and both mutation-test recipes while
  preserving target dependencies.
- R3. Root the generator's script and `spec.yaml` prerequisites so Make can
  resolve them before running the recipe.
- R4. Extend the baseline checker with exact contracts for root derivation,
  rooted prerequisites, and every rooted recipe.
- R5. Preserve `spec.yaml`, generated `spec.md`, workflows, dependencies, Ruby
  compatibility, and OpenAPI behavior.

## Assumptions

- GNU Make in the hosted Ubuntu lanes supports the established loaded-Makefile
  root pattern.
- Ruby scripts and POSIX test/checker scripts keep their own independent root
  resolution; Make only supplies a reliable invocation context.

## Implementation Units

### U1. Root generation and verification

**Files:** `Makefile`

Use one override-protected root for generator prerequisites and all script
recipes without changing alias ordering or generated output.

**Test scenarios:**

- Run all aliases from the repository root and through the absolute Makefile
  path from `/tmp` with a conflicting root override.
- Run `make generate` externally and prove `spec.md` remains byte-identical.
- Validate on Ruby 2.7 and Ruby 3.3.

### U2. Enforce and record the contract

**Files:** `scripts/check-baseline.sh`,
`docs/plans/2026-06-14-location-independent-make.md`

Require the exact root, prerequisites, and recipes, reject isolated mutations,
and record completed evidence after final validation.

**Test scenarios:**

- Mutate root derivation, generator prerequisites, and each script recipe.
- Run Ruby and shell syntax, validator and generator mutation suites, YAML
  parsing, and full baseline checks.
- Confirm specification files, workflow, prior plans, dependencies, artifacts,
  and credential patterns are unchanged.

## Scope Boundaries

- No OpenAPI operation, schema, example, security, or documentation-content
  changes.
- No dependency, workflow, supported-Ruby, or generator-format changes.
- No live service or network validation.

## Verification

Completion requires root and external gates on Ruby 2.7 and 3.3, byte-identical
external generation, seven isolated hostile Make mutations, syntax and YAML
checks, and exact protected-specification audits.

## Work Completed

- Added an override-protected repository root and used it for generator
  prerequisites plus check, generate, lint, and both mutation-test recipes.
- Extended the baseline checker to require the root declaration, rooted
  generator inputs, and every rooted script command exactly.
- Preserved specification content, generated format, workflows, dependencies,
  and supported Ruby behavior.

## Verification Completed

- Ruby 2.7.0 passed all Make aliases, including `make check`, from the repository
  root and through the absolute Makefile path from /tmp with a hostile
  `REPO_ROOT=/tmp` override.
- Ruby 3.3 `make check` passed externally in a read-only, network-isolated
  container with executable temporary fixtures and read-only Git metadata.
- External generation completed and left `spec.md` byte-identical at SHA-256
  `6371186f648a79f0fa870709fc0f987b7877719672b0e048f0ef1be0f76edc7e`.
- The checker rejected seven isolated hostile mutations covering root
  derivation, generator prerequisites, and every rooted script recipe.
- Ruby and POSIX shell syntax, YAML parsing, `git diff --check`, intended-path,
  generated-artifact, credential-pattern, dependency, workflow, prior-plan,
  `spec.yaml`, and `spec.md` preservation checks passed.
