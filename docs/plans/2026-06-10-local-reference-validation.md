# Local OpenAPI Reference Validation

## Status

Completed

## Context

The contract validator checked request-body component references and the shared
error response explicitly, but other local `$ref` values could point to missing
components without failing the repository gate. Those dangling references make
the document unusable for generated documentation and clients.

## Objectives

- Validate every local OpenAPI `$ref` recursively.
- Resolve references with JSON Pointer escaping rules.
- Keep the validation dependency-free and location-independent.
- Document the completed guard and its verification.

## Work Completed

- Added recursive local-reference discovery to `scripts/validate-openapi.rb`.
- Added JSON Pointer resolution for object keys, array indexes, and escaped
  `~0` and `~1` tokens.
- Documented the validation guard in README and CHANGES.

## Verification

- `ruby -c scripts/validate-openapi.rb`
- `make check`
- Mutated a schema `$ref` to a missing component and confirmed `make check`
  rejected the contract.
- `git diff --check`
