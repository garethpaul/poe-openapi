# Request Field Reference Validation

## Status

Completed

## Context

`poe-openapi` already checked endpoint, method, operation ID, security scheme,
and error-response drift between `spec.yaml` and `spec.md`. The remaining
documentation drift risk was that required request-body fields could change in
the component schemas without being reflected in the Markdown endpoint
reference.

## Objectives

- Keep validation dependency-free using Ruby's standard library.
- Resolve each operation's JSON request body to its component schema.
- Require every schema `required` field to be named in the matching Markdown
  endpoint section.
- Fail when an operation request body stops using a component schema.

## Verification

- `make verify`
- `scripts/validate-openapi.rb`
- `git diff --check`
