---
title: YAML Generator Recursion Guard
type: reliability
status: completed
date: 2026-06-15
execution: code
---

# YAML Generator Recursion Guard

## Problem

The validator converts deep acyclic YAML parser exhaustion to a stable error,
but `scripts/generate-spec-md.rb` parses `spec.yaml` independently. Direct
generation can still expose a raw `SystemStackError` instead of one controlled
nonzero diagnostic.

## Approach

- Read `spec.yaml` outside the parser exception boundary.
- Rescue only `SystemStackError` around `YAML.safe_load`.
- Emit one stable generator-specific diagnostic and exit nonzero before output
  replacement.
- Add a deep acyclic fixture plus mutation-sensitive source, guidance, and
  completed-plan contracts.

## Files

- `scripts/generate-spec-md.rb`
- `scripts/test-generator.sh`
- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `docs/plans/2026-06-15-yaml-generator-recursion-guard.md`

## Verification

- Run the focused generator fixture, all Make gates, and external-directory
  verification on the supported Ruby runtime.
- Reject isolated rescue-boundary, diagnostic, fixture, guidance, and plan
  mutations.
- Audit the exact diff, generated output, credentials, dependencies, conflicts,
  binaries, large files, modes, and whitespace.

## Risks

- Ordinary malformed YAML continues to report its existing parser diagnostic.
- No network access, private schema, or dependency change will be used.
- Keep this change stacked on PR #8; do not merge or close stacked pull
  requests without explicit authorization.

## Status

Completed

## Work Completed

- Read `spec.yaml` outside the generator parser rescue boundary.
- Convert only `SystemStackError` to one stable generator diagnostic.
- Prove deep parser failure leaves `spec.md` byte-identical.

## Verification Completed

- The focused generator contract fixture passed on the available Ruby runtime.
- All four Make gates passed, and `make check` passed from an external directory.
- Six isolated hostile mutations were rejected for a removed rescue, changed
  diagnostic, broadened exception handling, removed output assertion, missing
  guidance, and reopened plan status.
- Exact diff, generated output, credential, dependency, conflict, binary,
  large-file, mode, whitespace, and intended-path audits passed.
- No network access, private schema, or dependency change was used.
