# YAML Graph Walker Depth Guard

## Status Completed

## Problem

`YAML.safe_load` can materialize a deeply nested acyclic object graph from a
shallow sequence of aliases. That input bypasses the parser recursion guard and
then raises an uncontrolled `SystemStackError` in the validator's recursive
property, required-field, or reference walkers. A 5,000-node disposable alias
fixture reproduces the failure in `validate_property_descriptions`.

## Requirements

- R1. Traverse loaded Hash and Array graphs without Ruby call-stack recursion.
- R2. Visit aliased container objects once so a shared acyclic graph remains
  bounded instead of repeating the same subgraph for every alias path.
- R3. Preserve all existing property-description, required-field, and local
  reference diagnostics for ordinary specifications.
- R4. Add a bounded shallow-YAML/deep-alias regression that reaches validation,
  exits normally with contract errors, and never emits `SystemStackError`.
- R5. Add mutation-sensitive baseline contracts for iterative traversal,
  alias deduplication, fixture execution, timeout protection, and completed
  verification evidence.
- R6. Keep `spec.yaml`, generated `spec.md`, dependencies, and workflows
  byte-identical.

## Scope Boundaries

- Do not change YAML parsing, cyclic-alias detection, or generator behavior.
- Do not add an arbitrary application-level depth limit to valid OpenAPI data.
- Do not refactor operation-specific validation outside the three recursive
  whole-document walkers.
- Do not merge or close stacked pull requests without explicit authorization.

## Technical Design

- Replace each recursive walker with an explicit LIFO work stack containing the
  current node and diagnostic path.
- Track visited Hash and Array object IDs per walker. Shared aliases have the
  same validation content, so validating the first reachable path preserves
  correctness while preventing repeated traversal and stack exhaustion.
- Push child containers in reverse source order so LIFO traversal preserves the
  validator's current deterministic diagnostic order.
- Keep the existing field checks and error strings inside each iterative loop.
- Build the regression in the validator test's temporary directory using
  shallow anchored mappings whose aliases form a deep acyclic chain.

## Implementation Units

### U1. Make whole-document validation iterative

- **Files:** `scripts/validate-openapi.rb`
- Convert property-description, required-property, and `$ref` traversal to
  explicit stacks with per-walker visited-container tracking.

### U2. Add executable regression coverage

- **Files:** `scripts/test-validator.sh`
- Generate a deep acyclic alias graph, run the copied validator under a fixed
  timeout, reject stack traces, and require normal validation diagnostics.

### U3. Protect the contract and record evidence

- **Files:** `scripts/check-baseline.sh`, `README.md`, `CHANGES.md`, this plan
- Register the plan and require iterative/visited traversal, fixture wiring,
  bounded execution, user guidance, and truthful completed verification.

## Work Completed

- Added one iterative, alias-aware graph enumerator and routed all three
  whole-document semantic validators through it.
- Added a 5,000-node shallow-YAML/deep-alias fixture with a ten-second timeout
  and explicit `SystemStackError` rejection.
- Registered static contracts for traversal order, visited-object state, all
  three walker call sites, fixture execution, timeout behavior, and this plan.
- Documented the bounded validation behavior without changing generated API
  content, dependencies, or hosted workflow configuration.

## Verification Completed

- Ruby 2.7.0 passed syntax checks, the focused validator and generator suites,
  repository-root `make check`, and external-directory `make check` through the
  absolute Makefile path.
- Ruby 3.3 remains hosted-only in this environment; exact-head pull-request
  evidence is recorded separately in the repository tracker.
- The 5,000-node alias regression completed normally within ten seconds and
  did not emit `SystemStackError`; the former recursive implementation failed
  on the same graph.
- Eight isolated hostile mutations were rejected across recursive traversal,
  removed visited-state, incomplete walker adoption, fixture depth and
  execution, timeout removal, output assertion removal, and reopened status.
- Final `git diff --check`, generated-output, artifact, credential-pattern,
  conflict-marker, binary, large-file, mode, and whitespace audits passed.
  `spec.yaml` and `spec.md` remained byte-identical.

## Risks

- Object-ID deduplication changes which alias path appears in a diagnostic when
  the same invalid container is reachable more than once; the content remains
  invalid and validation still fails.
- A fixture that is too small may not reproduce the former stack failure across
  supported Ruby versions, while an unnecessarily large fixture can slow CI.

## Assumptions

- Hash and Array identity is stable for the lifetime of one validation run.
- Validating shared container content once is sufficient because these walkers
  do not apply parent-specific semantic rules.
