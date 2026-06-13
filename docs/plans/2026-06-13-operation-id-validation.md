# OpenAPI Operation ID Validation

## Status

Planned

## Context

The repository validator requires every operation to declare an `operationId`
and rejects duplicate values. However, the missing-value check calls `empty?`
directly on the parsed YAML value. A numeric, array, or object value therefore
raises a Ruby exception instead of producing a stable validation error. The
duplicate contract also lacks mutation coverage, so a future validator change
could silently weaken generated-client safety.

## Priority

OpenAPI generators use operation IDs as stable method names. Requiring a
non-empty string and preserving uniqueness protects generated clients while
keeping malformed specifications inside the validator's normal error path.

## Prioritized Engineering Backlog

1. Require every operation ID to be a non-empty string and report malformed
   values without a Ruby exception.
2. Add mutation tests for missing, whitespace-only, non-string, and duplicate
   operation IDs.
3. Generate the Markdown endpoint reference from `spec.yaml` once its current
   hand-maintained semantics can be preserved.

## Objectives

- Reject missing, blank, and non-string operation IDs with stable diagnostics.
- Preserve the existing repository-wide uniqueness requirement.
- Add dependency-free mutation tests that exercise each failure mode.
- Keep Markdown operation ID alignment and all existing OpenAPI checks intact.
- Run the new contract through `make test` and the canonical `make check` gate.
- Document the strengthened contract in contributor and change documentation.

## Scope Boundaries

- Do not rename existing operation IDs or change endpoint behavior.
- Do not impose an identifier character pattern beyond the OpenAPI string and
  uniqueness requirements.
- Do not add Ruby gems or another OpenAPI parser.
- Do not generate or rewrite `spec.md` in this focused change.

## Planned Verification

- `ruby -c scripts/validate-openapi.rb`
- `scripts/test-validator.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
