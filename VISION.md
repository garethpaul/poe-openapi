## Poe OpenAPI Vision

Poe OpenAPI is an OpenAPI specification and Markdown reference for an adapter
that converts between Server-Sent Events streams and Poe Protocol request and
response shapes.

The repository is useful as a contract-first description of endpoints,
authentication, request schemas, response streams, and error payloads for a Poe
Protocol bridge.

The goal is to keep the spec internally consistent and clear about which parts
are examples versus deployable service details.

The current focus is:

Priority:

- Preserve `spec.yaml` as the source API contract
- Keep `spec.md` aligned with the YAML specification
- Maintain `make check`, `make verify`, and `make build` as the local OpenAPI
  consistency gates
- Run the canonical dependency-free OpenAPI gate in hosted CI with read-only
  permissions and pinned third-party actions
- Keep hosted checkout credential-free and reject workflow drift structurally
- Preserve Ruby 2.7 compatibility while validating on modern Ruby 3.3
- Keep the validator independent of the caller's working directory
- Keep a scriptable baseline guard for required files and local metadata
- Preserve required request-field documentation in the Markdown reference
- Keep optional top-level request properties documented in the Markdown
  reference
- Keep OpenAPI schema `required` lists aligned with declared properties
- Keep documented response status codes aligned with the OpenAPI contract
- Keep operation IDs string-valued, non-empty, unique, and aligned with the
  Markdown endpoint reference
- Require every response status to retain a non-empty OpenAPI description
- Keep every OpenAPI reference local, string-valued, and resolvable so the
  machine-readable contract remains self-contained
- Keep the Markdown Error Handling section aligned with the shared Error schema
- Keep the Markdown Security section aligned with OpenAPI security schemes
- Keep OpenAPI security schemes self-describing for generated docs
- Require every operation to declare an explicit security requirement
- Accept standard Path Item metadata while rejecting unsupported or malformed
  path and operation structures
- Keep component schemas and their properties self-describing for generated
  docs and clients
- Make placeholder servers and support contacts obvious
- Require `example.com` servers to be labeled as placeholders in YAML and
  Markdown
- Keep authentication schemes and streaming response formats explicit

Next priorities:

- Add generation steps for producing Markdown from the YAML spec
- Replace example hostnames only when a real deployment exists
- Add example request and response fixtures for each endpoint
- Add generated reference output that preserves component and property
  descriptions

Contribution rules:

- One PR = one focused endpoint, schema, auth, example, or docs change.
- Update both YAML and Markdown outputs together.
- Do not claim production availability without a real server.
- Keep protocol examples minimal and machine-checkable.

## Security And Responsible Use

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Protocol adapters can forward user messages and credentials. The spec should
make authentication, error handling, and streaming behavior explicit so
implementations do not invent unsafe defaults.

## What We Will Not Merge (For Now)

- Production server claims that still point to placeholders
- Auth behavior without schema coverage
- Hand-edited Markdown that diverges from the OpenAPI source
- Ambiguous proxying or forwarding semantics

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
