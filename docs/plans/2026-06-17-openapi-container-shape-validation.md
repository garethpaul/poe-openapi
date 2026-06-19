# OpenAPI Container Shape Validation

## Status Completed

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

## Work Completed

- Added field-specific container-shape preflight checks to both validator and
  generator entry points before generator dispatch, traversal, rendering, or
  output replacement.
- Added isolated fixtures for malformed `info`, `paths`, `components`,
  `components.schemas`, `components.securitySchemes`, and `servers` values.
- Proved invalid validator input does not invoke the generator and invalid
  generator input leaves `spec.md` unchanged.
- Registered durable ordering, diagnostic, fixture, guidance, and plan
  contracts in the scripted baseline.

## Verification Completed

- Ruby syntax checks and both POSIX shell parsers passed for every changed
  executable script.
- Focused validator and generator suites passed on the available Ruby runtime.
- Full `make check` passed from the repository root and through the absolute
  Makefile path from `/tmp` in a Git-backed isolated final-state projection.
- Full `make check` then passed from both caller locations against the exact
  worktree after the completed-plan contract was active.
- Eight hostile mutations were rejected across both entry-point guards, exact
  diagnostics, both fixture contracts, plan registration, completed status,
  and maintainer guidance.
- `spec.yaml` and generated `spec.md` remained byte-identical.
