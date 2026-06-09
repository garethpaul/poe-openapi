# Scripted Baseline Check

## Status Completed

## Context

The repository had a dependency-free Ruby validator and Makefile gates, but it
did not have a scriptable repository baseline guard for required files,
validator wiring, completed plan metadata, and local metadata hygiene.

## Objectives

- Keep `make check` as the root verification command.
- Add a script-level baseline guard for required repository files.
- Keep the Ruby validator aware of completed maintenance plans.
- Keep local secrets and editor metadata out of the OpenAPI spec repository.

## Work Completed

- Added `.gitignore` coverage for local environment files, logs, and editor
  metadata.
- Added `scripts/check-baseline.sh`.
- Wired the script into `make check` after the existing verification gate.
- Added the scripted-baseline plan to the Ruby validator's completed-plan list.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `scripts/validate-openapi.rb`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Add generated Markdown output only after the source-to-reference workflow is
  automated.
- Add CI that runs `make check` if the repository becomes actively maintained.
