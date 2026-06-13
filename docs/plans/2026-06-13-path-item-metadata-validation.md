# Validate OpenAPI Path Item Shapes

## Status

Completed

## Summary

Make the OpenAPI validator distinguish HTTP operations from standard Path Item
metadata. It currently iterates every key as an operation, so valid path-level
`summary`, `description`, `servers`, or `parameters` fields can be misvalidated
or crash the script.

## Priority

Path Item metadata is part of the OpenAPI 3 contract and is commonly emitted by
editors and client-generation tooling. Validation should accept supported
metadata and reject malformed structures with stable diagnostics rather than a
Ruby exception.

## Requirements

- R1. Only `get`, `put`, `post`, `delete`, `options`, `head`, `patch`, and
  `trace` keys may enter operation validation.
- R2. Standard Path Item metadata keys `$ref`, `summary`, `description`,
  `servers`, and `parameters` must not be treated as operations.
- R3. Unknown Path Item keys must fail with a stable path-specific diagnostic.
- R4. A Path Item or HTTP operation that is not an object must fail cleanly
  without a Ruby exception or partial validation.
- R5. Deterministic tests must cover accepted metadata, unknown keys,
  non-object Path Items, and non-object operations.
- R6. Existing operation ID, security, request, response, reference, Markdown,
  and completed-plan contracts must remain unchanged.
- R7. `spec.yaml`, `spec.md`, workflow configuration, dependencies, and public
  API semantics must remain unchanged.

## Implementation Units

### U1. Path Item Classification

**Files:** `scripts/validate-openapi.rb`

- Define the supported HTTP methods and standard metadata keys.
- Validate Path Item and operation object shapes before field access.
- Reject unknown keys before running operation contracts.

### U2. Regression And Static Contracts

**Files:** `scripts/test-validator.sh`, `scripts/check-baseline.sh`

- Add valid metadata and malformed shape cases with stable expected output.
- Protect method filtering, shape guards, test cases, and plan evidence.

### U3. Guidance And Evidence

**Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`

- Document that Path Item metadata is accepted while unsupported keys and
  malformed objects fail closed.

## Scope Boundaries

- Do not edit the OpenAPI YAML or Markdown reference.
- Do not add an OpenAPI parser dependency or change supported Ruby versions.
- Do not broaden validation beyond Path Item classification and object shape.

## Verification Plan

- Ruby 2.7 and Ruby 3.3 syntax plus `make check` and all other Make gates
- focused accepted-metadata and malformed-shape assertions
- checker execution from an external working directory
- hostile mutations covering method filtering, metadata keys, shape guards,
  regression cases, plan status, and verification evidence
- exact-base/protected-path audit, `git diff --check`, and secret,
  captured-prompt, generated-artifact, specification, and dependency scans

## Work Completed

- Added explicit standard HTTP method and Path Item field sets so metadata no
  longer enters operation validation.
- Added stable validation errors for unsupported Path Item keys, non-object
  Path Items, and non-object HTTP operations before field access.
- Added deterministic accepted-metadata and malformed-shape regressions while
  preserving all existing operation ID, response, security, and reference tests.
- Extended baseline contracts and public guidance without changing the API
  specification, Markdown reference, workflow, dependencies, or Make surface.

## Verification Completed

- Ruby 2.7 and Ruby 3.3 `make check` passed in network-disabled, read-only
  containers with executable temporary storage for the mutation harness.
- Ruby and shell syntax, focused validator assertions, all Make gates, and an
  external-working-directory completed-copy check passed.
- Ten hostile mutations rejected method filtering, metadata allowlisting,
  unknown-field handling, both shape guards, accepted and malformed tests,
  guidance, plan status, and verification evidence.
- `git diff --check` passed. Exact-base comparison confirmed `spec.yaml`,
  `spec.md`, workflow, Makefile, ignore rules, and dependencies were unchanged;
  the secret, captured-prompt, generated-artifact, specification, and dependency scan passed.
