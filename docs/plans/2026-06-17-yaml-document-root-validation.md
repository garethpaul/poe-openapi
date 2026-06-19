# YAML Document Root Validation

## Status Completed

## Problem

`YAML.safe_load` can successfully return `nil`, a scalar, or an Array for a
syntactically valid YAML document. OpenAPI requires a mapping at the document
root, but the validator and Markdown generator currently continue into Hash
operations and can expose `NoMethodError` stack traces. The validator can also
invoke the generator before rejecting the invalid root.

## Requirements

- R1. Reject every non-Hash `spec.yaml` root with a deterministic validator
  diagnostic before cyclic-graph checks, generator execution, or semantic
  validation.
- R2. Reject the same roots directly in the generator with a scoped generator
  diagnostic before rendering or writing `spec.md`.
- R3. Preserve parser-recursion, cyclic-alias, ordinary syntax-error, semantic
  validation, generated-Markdown, and `--check` behavior.
- R4. Cover empty, scalar, and sequence YAML documents in both executable test
  suites and prove validator rejection occurs before generator invocation.
- R5. Add mutation-sensitive baseline contracts for both guards, exact
  diagnostics, fixture execution, ordering, and completed verification.
- R6. Keep `spec.yaml`, `spec.md`, dependencies, and workflows byte-identical.

## Scope Boundaries

- Do not recover or coerce non-mapping YAML roots.
- Do not change supported OpenAPI fields or semantic diagnostics.
- Do not change generic Psych syntax-error behavior.
- Do not add dependencies or alter generated reference content.
- Do not merge or close stacked pull requests without explicit authorization.

## Technical Design

- Add an explicit `Hash` root guard immediately after each successful
  `YAML.safe_load` call.
- Use entry-point-specific messages so failures identify whether validation or
  generation rejected the document.
- Reuse the validator test's generator-call log to prove the guard runs before
  generator dispatch.
- Use isolated temporary `spec.yaml` fixtures for empty, scalar, and sequence
  roots while preserving the checked-in specification and reference bytes.

## Implementation Units

### U1. Guard Both YAML Entry Points

- **Files:** `scripts/validate-openapi.rb`, `scripts/generate-spec-md.rb`
- Fail closed on non-Hash roots before downstream processing.

### U2. Add Executable Root Fixtures

- **Files:** `scripts/test-validator.sh`, `scripts/test-generator.sh`
- Exercise all three non-mapping root shapes, exact messages, no stack traces,
  no generator call from validation, and unchanged generated output.

### U3. Preserve The Contract

- **Files:** `scripts/check-baseline.sh`, `README.md`, `CHANGES.md`, this plan
- Register the plan and require guards, diagnostics, fixture coverage,
  ordering, guidance, and truthful completed verification.

## Verification Plan

- Ruby syntax checks and POSIX shell syntax checks for changed scripts.
- Focused validator and generator suites on the available Ruby runtime.
- Repository-root and external-directory `make check`.
- Hostile mutations covering removed guards, weakened type checks, moved
  ordering, changed diagnostics, missing fixtures, and reopened plan status.
- Final generated-output, specification, artifact, secret-pattern,
  conflict-marker, binary, mode, dependency, and whitespace audits.

## Work Completed

- Added entry-point-specific Hash root guards immediately after successful YAML
  parsing in both validation and generation.
- Added empty, scalar, and sequence root fixtures to both executable suites,
  including proof that validation rejects before generator dispatch and that
  generation never replaces `spec.md`.
- Registered mutation-sensitive baseline contracts for guards, diagnostics,
  ordering, fixtures, side effects, plan registration, and completed evidence.
- Documented the deterministic failure boundary without changing the checked-in
  OpenAPI specification, generated reference, dependencies, or workflows.

## Verification Completed

- Ruby 2.7.0 passed syntax checks and the focused validator and generator
  suites; POSIX `sh -n` and `dash -n` passed for all changed shell scripts.
- Full `make check` passed from the repository root and through the absolute
  Makefile path from an external directory in an isolated Git-aware final-state
  projection.
- Empty, scalar, and sequence documents produced exact scoped diagnostics,
  never exposed `NoMethodError`, and preserved generator ordering and output.
- Ten isolated hostile mutations were rejected across both guards, weakened
  type checks, changed diagnostics, validator ordering, fixture execution,
  output preservation, plan registration, and reopened status.
- `spec.yaml` and `spec.md` remained byte-identical; final generated-output,
  artifact, credential-pattern, conflict-marker, binary, mode, dependency, and
  whitespace audits passed for the exact eight-file change.
