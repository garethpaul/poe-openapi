# Changes

## 2026-06-10

- Added security-scheme description validation so generated OpenAPI docs keep
  authentication semantics attached to each scheme.

## 2026-06-09

- Added operation-level security validation so each OpenAPI endpoint must
  declare a non-empty security requirement.
- Added recursive required-property validation so every OpenAPI schema
  `required` entry must name a property declared on that schema.
- Added `scripts/check-baseline.sh` and `.gitignore` coverage for required
  files, validator wiring, completed plan metadata, and verification docs.
- Added a static `make build` gate for OpenAPI contract verification.

## 2026-06-08

- Added response-status reference validation so `spec.md` cannot omit, duplicate,
  or retain stale response codes for OpenAPI operations.
- Added Error schema reference validation so the Markdown Error Handling section
  must document every shared `Error` payload field.
- Added Security section validation so `spec.md` must name every OpenAPI
  security scheme and its concrete header or HTTP scheme.
- Added component-schema description validation so shared OpenAPI payloads
  keep top-level semantics for generated docs and clients.
- Added request-property reference validation so optional top-level request
  fields stay documented in the Markdown endpoint reference.
- Added schema-property description validation so OpenAPI fields keep
  field-level semantics for generated docs and clients.
- Added canonical `docs/plans` coverage and placeholder-server validation so
  example hosts cannot be presented as real production endpoints.
- Added request-field reference validation so required OpenAPI request fields
  must stay documented in `spec.md`.
- Added `make check` as an alias for the existing OpenAPI verification gate.
- Added a dependency-free Ruby validator for OpenAPI endpoint, security, response, and Markdown reference consistency.
- Added `make verify` as the local quality gate for the specification.
- Updated `spec.md` to include operation IDs for every documented endpoint.
