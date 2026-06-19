# Cyclic YAML Alias Validation

## Status

Completed

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

## Verification Completed

- Ruby 2.7.0 passed syntax checks, focused validator and generator fixtures,
  the repository `make check`, and the absolute-Makefile `make check` from an
  external directory.
- Ruby 3.3.11 passed the full `make check` in the official Ruby container with
  networking disabled and the repository mounted read-only.
- Focused fixtures rejected cyclic mapping values, cyclic arrays, cyclic
  mapping keys, and a 12,000-node alias chain with exactly
  `spec.yaml contains cyclic YAML aliases` before generator execution; an
  acyclic shared alias remained accepted.
- Fifteen isolated hostile mutations were rejected across back-edge detection,
  visited-node handling, array and mapping-key traversal, stack cleanup,
  preflight bypass, assertion bypass, timeout removal, diagnostic drift,
  executable fixture wiring, and plan status.
- Plan-aware correctness, testing, maintainability, project-standards,
  reliability, security, adversarial, agent-native, and repository-learning
  review findings were applied: traversal is iterative, fixtures are bounded,
  and executable assertion lines plus completed evidence are enforced.
- Final `git diff --check`, generated-artifact, credential-pattern,
  conflict-marker, dependency-drift, workflow, and specification audits passed.
  `spec.yaml` and `spec.md` remained byte-identical at SHA-256
  `5b84534b62a346a35b99a3c2253931cef63ab2bcd6ab602b5d4f2d7d6a967f0a`
  and `6371186f648a79f0fa870709fc0f987b7877719672b0e048f0ef1be0f76edc7e`.
