# Changes

## 2026-06-13

- Accepted standard OpenAPI Path Item metadata without treating it as an HTTP
  operation and added stable errors for unsupported or non-object structures.
- Strengthened operation ID validation to reject missing, blank, and
  non-string values with stable diagnostics while preserving uniqueness.
- Added dependency-free mutations for malformed and duplicate operation IDs.

## 2026-06-12

- Replaced the end-of-life Ruby 2.7 and security-only Ruby 3.3 CI lanes with
  maintained Ruby 3.4 and Ruby 4.0 coverage.
- Added response-description validation so missing or whitespace-only OpenAPI
  response descriptions fail before reaching generated documentation.
- Added a dependency-free mutation test and wired it through `make test` and
  the canonical `make check` gate.
- Disabled persisted checkout credentials and made the baseline enforce the
  exact hosted OpenAPI workflow contract.
- Pinned Ruby setup and added hosted Ruby 2.7 and Ruby 3.3 validation lanes.
- Expanded validator mutations to reject dangling local references and accept
  correctly escaped JSON Pointer tokens.
- Required every OpenAPI `$ref` to be a resolvable local string, rejecting
  external URLs, relative files, and non-string values.

## 2026-06-10

- Added hosted OpenAPI contract validation with read-only permissions and a
  pinned checkout action.
- Made the OpenAPI validator independent of the caller's working directory and
  protected that behavior in the scripted baseline check.
- Added security-scheme description validation so generated OpenAPI docs keep
  authentication semantics attached to each scheme.
- Added recursive local-reference validation so dangling OpenAPI JSON Pointers
  fail before they reach documentation or client generators.

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
