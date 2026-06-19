---
title: YAML parser recursion guard
date: 2026-06-15
type: implementation
status: completed
---

# YAML Parser Recursion Guard

## Status

Completed

## Problem Frame

`scripts/validate-openapi.rb` loads `spec.yaml` through Psych before its
cycle-aware object-graph checks run. A deeply nested but acyclic mapping can
therefore exhaust Ruby's call stack inside `YAML.safe_load` and print a large
`SystemStackError` backtrace instead of returning a bounded validation error.

The parser boundary should fail predictably without changing ordinary YAML
syntax diagnostics, cyclic-alias handling, generated Markdown validation, or
the supported Ruby 2.7 and 3.3 contract.

## Requirements

- R1. Convert `SystemStackError` raised while loading `spec.yaml` into one
  stable, actionable diagnostic and a nonzero exit without a Ruby backtrace.
- R2. Scope the rescue to `YAML.safe_load` itself so file-read failures and
  recursion defects in later validator code are not mislabeled as parser-depth
  failures.
- R3. Preserve Psych syntax-error behavior and the existing exact cyclic-alias
  diagnostic and pre-generator ordering.
- R4. Add a bounded deep acyclic fixture that reproduces parser recursion
  exhaustion on Ruby 2.7 and verifies the exact error and generator non-entry.
- R5. Add mutation-sensitive baseline contracts for rescue scope, diagnostic,
  executable fixture wiring, and completed verification evidence.
- R6. Preserve `spec.yaml`, `spec.md`, dependencies, workflows, and generated
  outputs byte-for-byte.

## Scope Boundaries

- Do not replace Psych or pre-parse YAML with an ad hoc indentation scanner.
- Do not impose a new application-level schema-depth limit on documents Psych
  can load successfully.
- Do not refactor the existing recursive schema and reference validators in
  this change; parser exhaustion occurs before those walkers receive a graph.
- Do not merge or close stacked pull requests without explicit authorization.

## Key Technical Decisions

- Catch `SystemStackError` immediately around `YAML.safe_load`. This is the
  narrowest boundary that distinguishes parser recursion exhaustion from
  unrelated validator stack failures.
- Keep the existing stable-error style used by cyclic-alias rejection. The
  command-line contract should be concise and deterministic across supported
  Ruby versions.
- Generate the deep fixture in the test temporary directory and execute the
  copied validator under a timeout. This avoids modifying tracked
  specifications and proves bounded failure plus generator ordering.

## Implementation Units

### U1. Bound YAML parser recursion failures

- **Files:** `scripts/validate-openapi.rb`
- **Goal:** Wrap only the `YAML.safe_load` call, emit the stable parser-depth
  diagnostic on `SystemStackError`, and leave subsequent cycle and contract
  validation unchanged.
- **Pattern:** Follow the existing early `warn` and `exit 1` validation style.
- **Test scenarios:** Deep acyclic mapping returns the exact diagnostic;
  ordinary input loads; cyclic aliases still return their existing error;
  malformed YAML continues to surface as a Psych syntax failure rather than a
  parser-depth error.

### U2. Add bounded executable regression coverage

- **Files:** `scripts/test-validator.sh`
- **Goal:** Build a deep acyclic YAML fixture, invoke the copied validator
  under a fixed timeout, require exact output, and prove the generator did not
  execute.
- **Test scenarios:** Reproducing depth fails within the timeout with one line;
  shallower valid content remains accepted; commented or bypassed fixture
  invocation is detectable by the baseline gate.

### U3. Protect contracts and completed evidence

- **Files:** `scripts/check-baseline.sh`,
  `docs/plans/2026-06-15-yaml-parser-recursion-guard.md`
- **Goal:** Register the plan and require the narrow rescue, stable diagnostic,
  executable test scenario, timeout, generator-order assertion, and truthful
  completed verification record.
- **Test scenarios:** Mutations that remove or broaden the rescue, change the
  diagnostic, bypass the fixture, remove the timeout or generator assertion,
  or restore provisional plan language are rejected.

## Verification Completed

- Ruby 2.7.0 passed syntax checks, the focused validator suite, repository
  `make check`, and the absolute-Makefile `make check` from an unrelated
  directory.
- Ruby 3.3.11 passed the focused validator suite and complete `make check` in
  the official network-disabled container with the repository mounted
  read-only.
- A 2,000-level acyclic mapping returned exactly
  `spec.yaml exceeds the YAML parser nesting limit` within five seconds and
  before generator execution; a 100-level acyclic mapping remained accepted.
- Malformed YAML continued to report `Psych::SyntaxError` and was not
  mislabeled as parser recursion.
- Twelve isolated hostile mutations were rejected across rescue presence and
  scope, parser assignment, diagnostic stability, timeout and generator
  assertions, fixture depth and invocation, syntax-error distinction, plan
  registration, and completed evidence.
- Final `git diff --check`, generated-artifact, credential-pattern,
  conflict-marker, dependency-drift, workflow, and specification audits passed.
  `spec.yaml` and `spec.md` remained byte-identical at SHA-256
  `5b84534b62a346a35b99a3c2253931cef63ab2bcd6ab602b5d4f2d7d6a967f0a`
  and `6371186f648a79f0fa870709fc0f987b7877719672b0e048f0ef1be0f76edc7e`.

## Risks

- Psych's recursion threshold is runtime-dependent, so the fixture must be
  deep enough to reproduce on both supported runtimes while remaining bounded
  by a timeout.
- `SystemStackError` is not a `StandardError`; broad rescue patterns can miss it
  or accidentally hide unrelated validator defects. Static and hostile
  mutation coverage must enforce the narrow parser boundary.

## Assumptions

- Deeply nested OpenAPI documents that Psych cannot materialize are invalid for
  this validator regardless of whether their YAML graph is acyclic.
- Existing recursive post-load validators are outside this parser-boundary fix
  unless execution reveals a separate concrete failure after successful load.
