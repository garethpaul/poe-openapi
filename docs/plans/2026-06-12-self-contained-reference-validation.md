# Self-Contained OpenAPI Reference Validation

## Status

Completed

## Context

The validator resolves local JSON Pointer references but ignores `$ref` values
that are external URLs, relative files, or non-strings. Such references can
make the contract depend on network or filesystem content even though the
repository's validation boundary is documented as self-contained and offline.

## Priority

Every reference affects the machine-readable API contract. Failing closed on
non-local references prevents hidden network, filesystem, and supply-chain
dependencies from entering a specification that canonical CI validates
without external access.

## Objectives

- Require every `$ref` value to be a string.
- Allow only `#` and `#/...` local JSON Pointer references.
- Continue resolving local pointers, including escaped `/` and `~` tokens.
- Reject external URLs and relative-file references with stable errors.
- Add dependency-free mutation tests and baseline enforcement.
- Keep `spec.yaml` and the public API contract unchanged.

## Verification

- `ruby -c scripts/validate-openapi.rb`
- `sh -n scripts/test-validator.sh`
- `dash -n scripts/test-validator.sh`
- `scripts/test-validator.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`

## Work Completed

- The validator now rejects non-string, external URL, relative-file, and
  malformed local `$ref` values before resolving valid local JSON Pointers.
- Mutation coverage exercises each rejected reference form, including malformed
  fragments, and preserves the escaped JSON Pointer acceptance case.
- The baseline guard requires the validator implementation, mutation cases,
  documentation, and this completed plan.
- `spec.yaml` remains unchanged.

## Verification Results

- `ruby -c scripts/validate-openapi.rb` passed with Ruby 2.7.0.
- `sh -n scripts/test-validator.sh` passed.
- `dash -n scripts/test-validator.sh` passed.
- `scripts/test-validator.sh` passed.
- `make lint`, `make test`, `make build`, `make verify`, and `make check`
  passed with Ruby 2.7.0.
- Caller-independent validator execution from `/` passed.
- `make check` passed with Ruby 3.3 in the official container after marking
  the read-only bind mount as a Git safe directory.
- All 12 hostile baseline mutations were rejected.
- `git diff --check` passed.
- `spec.yaml` retained SHA-256
  `5b84534b62a346a35b99a3c2253931cef63ab2bcd6ab602b5d4f2d7d6a967f0a`.
