# Changes

## 2026-06-08

- Added response-status reference validation so `spec.md` cannot omit, duplicate,
  or retain stale response codes for OpenAPI operations.
- Added Error schema reference validation so the Markdown Error Handling section
  must document every shared `Error` payload field.
- Added canonical `docs/plans` coverage and placeholder-server validation so
  example hosts cannot be presented as real production endpoints.
- Added request-field reference validation so required OpenAPI request fields
  must stay documented in `spec.md`.
- Added `make check` as an alias for the existing OpenAPI verification gate.
- Added a dependency-free Ruby validator for OpenAPI endpoint, security, response, and Markdown reference consistency.
- Added `make verify` as the local quality gate for the specification.
- Updated `spec.md` to include operation IDs for every documented endpoint.
