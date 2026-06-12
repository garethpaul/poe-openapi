# Hosted OpenAPI Validation

## Status

Completed

## Context

The dependency-free OpenAPI validator was available only as a local gate and
assumed callers launched it from the repository root. Pull requests and pushes
could skip the contract checks, while direct script invocation from another
directory failed before validation began.

## Work Completed

- Made `scripts/validate-openapi.rb` resolve repository files from its own
  location instead of the caller's working directory.
- Added a fixed-runner GitHub Actions workflow for pushes to `main` and pull
  requests.
- Limited the workflow token to read-only contents access and pinned the
  checkout action to a reviewed commit.
- Extended the baseline guard to preserve the workflow contract and verify
  location-independent validator execution.

## Verification

- `scripts/validate-openapi.rb`
- `(cd / && /path/to/scripts/validate-openapi.rb)`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
