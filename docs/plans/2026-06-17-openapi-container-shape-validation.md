# OpenAPI Container Shape Validation

## Status

In Progress

## Problem

The validator now rejects non-mapping YAML document roots, but it dispatches
the Markdown generator before validating the shapes of core top-level OpenAPI
containers. A mapping-root document with malformed `paths`, `components`,
`components.schemas`, `components.securitySchemes`, or `servers` values can
therefore expose Ruby `TypeError` or `NoMethodError` traces instead of one
stable validation diagnostic.

## Requirements

1. Validate core top-level container shapes before invoking the Markdown
   generator or traversing those values.
2. Require `paths` and `components` to be mappings, optional component maps to
   be mappings, and `servers` to be an array when present.
3. Emit one stable, field-specific diagnostic for the first invalid container.
4. Preserve missing optional-container behavior and all existing semantic,
   recursion, alias, generation, and checked-in Markdown contracts.
5. Add isolated fixtures proving malformed containers do not invoke the
   generator.
6. Add mutation-sensitive baseline contracts and completed verification
   evidence.

## Implementation Units

### U1. Pre-Generator Shape Boundary

Add a small field/type preflight after YAML root and cyclic-alias validation.
Keep normalized container assignments for the existing semantic checks.

### U2. Stable Regression Fixtures

Exercise each guarded container with an invalid YAML type, assert the exact
diagnostic, and prove the generator call log remains absent.

### U3. Durable Contracts And Guidance

Register this plan and its shape/ordering fixtures in the baseline checker,
then update maintainer guidance and the changelog.

## Verification Plan

- Run Ruby syntax checks plus `sh -n` and `dash -n` for changed shell scripts.
- Run focused validator and generator suites on the available Ruby runtime.
- Run full `make check` from the repository root and through the absolute
  Makefile path from an external directory.
- Reject mutations that remove a guard, move generator dispatch before
  preflight, weaken exact diagnostics, remove fixtures, or reopen plan status.
- Audit the exact diff, generated Markdown, artifacts, secrets, dependencies,
  workflow, modes, and whitespace before committing.

## Scope Boundaries

- Do not change `spec.yaml` or generated `spec.md` content.
- Do not add a schema-validation dependency or attempt full OpenAPI validation.
- Do not change nested operation, response, schema, or security semantics.
- Do not merge or close stacked pull requests without explicit authorization.
