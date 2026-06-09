# Required Property Validation

## Status Completed

## Context

OpenAPI schemas can declare a `required` list that names fields missing from the
same schema's `properties` map. That drift creates impossible payload contracts
for generated clients and readers even when endpoint-level request docs stay in
sync.

## Objectives

- Validate every schema `required` entry recursively across the OpenAPI tree.
- Fail when a schema declares required fields without a `properties` map.
- Preserve existing endpoint-level request-property reference checks.
- Keep `make check` as the root verification command.

## Work Completed

- Added recursive required-property validation to `scripts/validate-openapi.rb`.
- Reused the same validation for nested schemas and array entries.
- Moved endpoint request-schema required checks into the recursive validator.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/validate-openapi.rb`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Add fixture specs for validator failure modes if the validator grows beyond a
  single dependency-free script.
- Generate Markdown from the spec once required-property drift is fully
  covered by the generator.
