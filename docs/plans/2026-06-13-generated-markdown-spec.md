# Generated Markdown Specification

## Status

Completed

## Context

`spec.yaml` is the source API contract, while `spec.md` is hand-maintained.
The validator catches selected endpoint, request-field, response, and security
drift, but the roadmap still identifies Markdown generation as the missing
source-to-reference workflow. A deterministic generator can make all represented
Markdown contract data derive from the YAML rather than parallel edits.

## Requirements

- Add a dependency-free Ruby generator for the title, overview, API metadata,
  servers, operations, request schema fields, responses, security schemes, and
  shared error example represented in `spec.md`.
- Keep the existing endpoint/method/operation-ID/request/response Markdown shape
  compatible with the fail-closed validator.
- Add `--check` mode that fails with a stable diagnostic when `spec.md` differs
  byte-for-byte from generated output.
- Run generation drift checks in the canonical validator and expose an explicit
  Make generation target.
- Produce identical output on supported Ruby 2.7 and 3.3 runtimes.
- Add mutation-sensitive offline tests without network or new dependencies.

## Scope Boundaries

- Do not change `spec.yaml`, operation behavior, host placeholders, security
  requirements, schemas, responses, workflows, or supported Ruby versions.
- Do not introduce templates, gems, external references, or live service calls.

## Verification Plan

- Generate `spec.md`, run `--check`, the validator, mutation tests, and all Make
  gates on Ruby 2.7 and Ruby 3.3.
- Run hostile mutations against generated metadata, operations, fields,
  responses, security, drift diagnostics, Make/checker wiring, and plan status.
- Confirm the YAML spec, workflow, dependency files, supported-runtime plan,
  and unrelated docs have no diff.
- Run Ruby/shell syntax, YAML parsing, generated-artifact, secret, and
  `git diff --check` scans.

## Work Completed

- Added dependency-free `scripts/generate-spec-md.rb` generation and exact
  `--check` drift detection for `spec.md`.
- Wired generation through `make generate`, the canonical validator, mutation
  tests, and the scripted baseline contract.
- Documented `spec.yaml` as the hand-edited source and regenerated the complete
  Markdown reference without changing the OpenAPI contract or workflow.

## Verification Completed

- Ruby and shell syntax checks passed on Ruby 2.7.
- The focused generator suite passed; stale output, unsupported arguments, and
  metadata, operation, request-field, response, security, and error-example
  hostile mutations rejected incorrect or incomplete generation.
- `make check` passed on Ruby 2.7 and Ruby 3.3; the Ruby 3.3 run used a
  read-only, network-isolated container with the repository mounted at its
  canonical worktree path.
- `git diff --check` and the repository's secret, captured-prompt, generated-artifact, specification, and dependency scan passed.
