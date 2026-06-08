# Changes

## 2026-06-08

- Added request-field reference validation so required OpenAPI request fields
  must stay documented in `spec.md`.
- Added `make check` as an alias for the existing OpenAPI verification gate.
- Added a dependency-free Ruby validator for OpenAPI endpoint, security, response, and Markdown reference consistency.
- Added `make verify` as the local quality gate for the specification.
- Updated `spec.md` to include operation IDs for every documented endpoint.
