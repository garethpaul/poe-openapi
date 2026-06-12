# Credential-free OpenAPI validation

## Status

Completed

## Context

The hosted OpenAPI workflow used pinned, read-only checkout but still persisted
its repository credential. The baseline checked individual workflow fragments,
which could accept extra actions or shadowed settings alongside required text.
The validator also lacked direct mutation coverage for its local-reference
resolver.

## Decision

1. Configure checkout with `persist-credentials: false`.
2. Pin `ruby/setup-ruby` and validate the legacy Ruby 2.7 floor plus modern
   Ruby 3.3.
3. Enforce the exact workflow contract, including events, permissions,
   concurrency, runner, timeout, action commits, runtime matrix, and command.
4. Require contributor guidance for the canonical specification, security
   schemes, credential-adjacent names, and repository gate.
5. Reject a dangling local `$ref` and accept JSON Pointer escaping for `/` and
   `~` in the validator mutation suite.

## Verification

- `make check`
- Ruby 2.7 and Ruby 3.3 hosted lanes
- `scripts/test-validator.sh`
- focused hostile workflow and contributor-guidance mutations
- `git diff --check`
