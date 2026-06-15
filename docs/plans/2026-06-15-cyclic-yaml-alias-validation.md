# Cyclic YAML Alias Validation

Status: In Progress

## Problem

The validator loads YAML aliases and recursively walks the resulting Ruby
object graph without detecting cycles. A recursive alias therefore raises
`SystemStackError` after thousands of frames instead of producing a concise,
actionable OpenAPI validation error.

## Requirements

1. Detect cyclic Hash and Array object graphs by object identity before the
   generator check and recursive contract validation begin.
2. Reject recursive aliases with one stable validation error and no Ruby stack
   trace or timeout.
3. Preserve ordinary non-cyclic YAML aliases, local-reference resolution,
   generated Markdown validation, and supported Ruby 2.7/3.3 behavior.
4. Add deterministic fixture and mutation-sensitive static coverage for cycle
   detection, preflight ordering, ordinary aliases, and completed evidence.

## Scope Boundaries

- Do not change `spec.yaml`, `spec.md`, dependencies, or generated output.
- Do not ban YAML aliases that form an acyclic object graph.
- Do not redesign the existing schema and reference validators.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification: Pending

- Run focused validator fixtures, Ruby syntax, and full Make gates from the
  repository and an external directory on the available supported runtime.
- Reject focused hostile mutations across identity tracking, recursion-stack
  cleanup, preflight ordering, fixtures, and completed plan evidence.
- Audit the exact diff, generated artifacts, credentials, specification bytes,
  dependency drift, conflict markers, and whitespace before commit.
