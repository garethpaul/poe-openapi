# Operation Security Validation

## Status

Completed

## Context

The OpenAPI validator checked security scheme references only after an operation
declared `security`. If an endpoint lost its operation-level security block, the
spec could accidentally describe an unauthenticated route while still passing
local validation.

## Objectives

- Fail when an OpenAPI operation omits an operation-level security requirement.
- Fail when an operation-level security requirement is empty or does not name a
  configured scheme.
- Keep the validation dependency-free in `scripts/validate-openapi.rb`.
- Add a static `make build` target for the OpenAPI contract verification gate.
- Document the guard in README, VISION, SECURITY, and CHANGES.

## Work Completed

- Extended `scripts/validate-openapi.rb` to require non-empty operation-level
  `security` requirements for every endpoint.
- Kept the existing unknown-scheme validation for each named security scheme.
- Added `make build` as a static OpenAPI validation alias and wired `verify`
  through lint, test, and build.
- Updated project documentation and maintenance notes for the new guard.

## Verification

- Temp-copy red check with `/stream-to-poe` security removed.
- Red `make build` before adding the target.
- `ruby -c scripts/validate-openapi.rb`
- `scripts/validate-openapi.rb`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
