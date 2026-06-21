# Safe Make Repository Root

## Status Completed

## Problem

The location-independent Makefile expanded its repository root directly into
shell source. A checkout path containing a backtick command therefore executed
that command before the quality script ran. Closed pull request #13 attempted
to canonicalize the root but kept the unsafe recipe interpolation and its
dry-run verifier did not exercise backticks, `MAKEFILES`, `SHELL`, or Ruby
command authority.

## Design

- Snapshot the checked-in Makefile path with `$(value MAKEFILE_LIST)` and export
  that literal value as environment data without interpolating it into recipe
  source.
- Resolve and export `REPO_ROOT` inside each recipe from the environment value,
  then read it as `$$REPO_ROOT`, never as Make-expanded shell text.
- Pin `SHELL`, `.SHELLFLAGS`, and `RUBY` to repository-approved commands.
- Reject detected non-empty `MAKEFILES` and direct `MAKEFILE_LIST` overrides
  before repository quality commands run.
- Keep caller-provided `REPO_ROOT` and Ruby command values non-authoritative.
- Do not add a Python authority variable because Poe OpenAPI has no Python
  command surface; Ruby is the actual maintained interpreter boundary.

## Verification

- Execute all seven public targets through 77 hostile path and authority cases.
- Prove a literal backtick checkout path does not create its marker file.
- Prove caller-controlled shell and Ruby commands are not executed.
- Prove command-line and environment `MAKEFILE_LIST` overrides fail closed.
- Prove a detected `MAKEFILES` preload fails before repository quality commands
  run.
- Run `make check`, syntax checks, generated-spec drift checks, secret scans,
  and repository integrity checks without credentials or provider calls.

## Trust Boundary

The checked-in Makefile must be the only explicit Makefile. GNU Make loads
`MAKEFILES` content before this file and loads later `-f` files afterward; that
content is executable Make code and can reset Make variables or replace target
recipes. No rule inside this Makefile can sandbox hostile extra Makefiles. The
regression suite therefore proves the supported invocation and direct override
boundary without claiming that GNU Make itself is a security sandbox.

GNU Make also expands Make expressions embedded in a `-f` filename while
loading it. A checkout path containing text such as `$(shell command)` can run
that command before this Makefile is evaluated, so dollar-sign Make expressions
in the Makefile path are outside the supported boundary. The implementation
does not use `eval`, `$(shell ...)`, or any shell re-parsing of repository path
data after the Makefile has loaded.
