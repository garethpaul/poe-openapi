# OpenAPI Response Description Validation

## Status

Completed

## Context

OpenAPI response objects require a `description`, but the repository validator
currently checks only response status coverage and error schema references. A
response can therefore lose its description while `make check` remains green,
leaving generated documentation and client tooling without the response's
meaning.

## Priority

Response descriptions are part of the machine-readable API contract. Rejecting
missing or whitespace-only descriptions prevents a small YAML edit from
silently degrading every generated consumer of the specification.

## Prioritized Engineering Backlog

1. Require a non-empty description on every OpenAPI response now.
2. Add fixture-driven validation for operation summaries and descriptions.
3. Generate the Markdown endpoint reference from `spec.yaml` once its current
   hand-maintained semantics can be preserved.

## Objectives

- Fail validation when any response omits `description` or provides only
  whitespace.
- Preserve response status, shared error schema, and Markdown alignment checks.
- Add a dependency-free mutation test proving the failure behavior.
- Run that mutation test through `make test` and the canonical `make check`
  gate.
- Document the contract in README, SECURITY, VISION, and CHANGES.

## Scope Boundaries

- Do not change endpoint response payloads or status codes.
- Do not add Ruby gems or another OpenAPI parser.
- Do not generate or rewrite `spec.md` in this focused change.

## Verification

- `ruby -c scripts/validate-openapi.rb`
- `scripts/test-validator.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`

## Work Completed

- Added non-empty response-description checks to the Ruby validator.
- Added mutation tests that remove a valid response description or rewrite it
  to whitespace and require the validator to reject both cases.
- Wired the mutation test into `make test` and the repository baseline.
- Updated maintenance and security documentation for the new contract.
