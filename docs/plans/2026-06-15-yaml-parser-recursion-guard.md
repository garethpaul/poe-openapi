---
title: YAML parser recursion guard
date: 2026-06-15
type: implementation
status: planned
---

# YAML Parser Recursion Guard

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
- R2. Scope the rescue to YAML loading so recursion defects in later validator
  code are not mislabeled as parser-depth failures.
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

## Verification Plan

- Run Ruby syntax and POSIX shell syntax checks plus the focused validator
  suite.
- Run `make check` from the repository root and through the absolute Makefile
  path from an unrelated directory on Ruby 2.7.
- Run the complete gate on Ruby 3.3 in a network-disabled container.
- Run isolated hostile mutations for implementation, test wiring, diagnostics,
  rescue scope, and plan evidence.
- Audit the exact diff, generated artifacts, credential patterns, conflict
  markers, dependency and workflow drift, and the SHA-256 values of
  `spec.yaml` and `spec.md` before commit.

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
