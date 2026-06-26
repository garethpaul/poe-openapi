# OpenAPI 3.1 Nullability

## Status Completed

## Problem

`spec.yaml` declares OpenAPI 3.1 but two Poe query fields still used the removed
OpenAPI 3.0 `nullable` keyword. OpenAPI 3.1 delegates schema semantics to JSON
Schema 2020-12, so generators may ignore that keyword and model legitimate
`null` payloads as invalid.

## Requirements

1. Preserve the existing wire contract and field names.
2. Express nullable primitive values and referenced identifiers with JSON
   Schema unions supported by OpenAPI 3.1.
3. Reject `nullable` in component schemas and inline request/response schemas.
4. Render null unions accurately in generated Markdown.
5. Keep validation dependency-free and bounded by the iterative graph walker.

## Decision

- Represent the nested metadata string with `type: [string, "null"]`.
- Represent the nullable identifier with `anyOf` containing the existing local
  reference and `{ type: "null" }`.
- Extend the validator over component and operation schema roots rather than
  changing public endpoint, field, authentication, or response semantics.
- Extend the generator's type formatter for `anyOf` and array-valued `type`.

## Alternatives

- Retain `nullable`: rejected because it is not an OpenAPI 3.1 Schema Object
  keyword and produces generator-dependent behavior.
- Remove nullability: rejected as a breaking change to accepted Poe payloads.
- Duplicate the Identifier schema with a nullable variant: rejected because it
  introduces another public component and unnecessary schema drift.

## Work Completed

- Converted both affected request fields to JSON Schema unions.
- Added bounded component and inline operation-schema keyword validation.
- Added red-first component and inline mutation fixtures.
- Regenerated `spec.md` with `Identifier or null` for the top-level field.
- Added maintainer guidance and mutation-sensitive baseline contracts.

## Verification Completed

- Focused validator and generator suites passed after both red regressions.
- Official Docker Ruby 3.4.9 and Ruby 4.0.5 `make check` runs passed.
- The Ruby 4.0.5 external-directory `make check` passed from `/tmp` using the
  absolute repository Makefile path.
- Four hostile mutations were rejected: component and inline validator
  fixtures, restoring `nullable` in the checked-in spec, and removing `anyOf`
  union rendering from the Markdown generator.
- Generated Markdown stayed synchronized with `spec.yaml`.
- `git diff --check` passed.
