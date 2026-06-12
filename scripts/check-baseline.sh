#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT_DIR/README.md"
MAKEFILE="$ROOT_DIR/Makefile"
GITIGNORE="$ROOT_DIR/.gitignore"
VALIDATOR="$ROOT_DIR/scripts/validate-openapi.rb"
DOCS_PLANS="$ROOT_DIR/docs/plans"
WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  "AGENTS.md" \
  ".gitignore" \
  "CHANGES.md" \
  "Makefile" \
  "README.md" \
  "SECURITY.md" \
  "VISION.md" \
  "spec.md" \
  "spec.yaml" \
  "scripts/test-validator.sh" \
  "scripts/validate-openapi.rb" \
  "docs/plans/2026-06-08-placeholder-server-validation.md" \
  "docs/plans/2026-06-09-scripted-baseline-check.md" \
  "docs/plans/2026-06-10-hosted-openapi-validation.md" \
  "docs/plans/2026-06-10-local-reference-validation.md" \
  "docs/plans/2026-06-12-credential-free-openapi-validation.md" \
  "docs/plans/2026-06-12-response-description-validation.md" \
  "docs/plans/2026-06-12-self-contained-reference-validation.md" \
  "docs/plans/2026-06-12-supported-ruby-matrix.md" \
  ".github/workflows/check.yml" \
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

if ! [ -x "$VALIDATOR" ]; then
  printf '%s\n' "scripts/validate-openapi.rb must be executable." >&2
  exit 1
fi

if ! [ -x "$ROOT_DIR/scripts/test-validator.sh" ]; then
  printf '%s\n' "scripts/test-validator.sh must be executable." >&2
  exit 1
fi

if ! grep -Fq "scripts/check-baseline.sh" "$MAKEFILE"; then
  printf '%s\n' "Makefile must run scripts/check-baseline.sh from make check." >&2
  exit 1
fi

if ! grep -Fq "scripts/validate-openapi.rb" "$MAKEFILE"; then
  printf '%s\n' "Makefile must expose the OpenAPI validator." >&2
  exit 1
fi

if ! grep -Fq "scripts/test-validator.sh" "$MAKEFILE"; then
  printf '%s\n' "Makefile must run validator mutation tests." >&2
  exit 1
fi

for target in "lint:" "test:" "build:" "verify:" "check:"; do
  if ! grep -Fq "$target" "$MAKEFILE"; then
    printf '%s\n' "Makefile must expose the $target gate." >&2
    exit 1
  fi
done

if ! grep -Fq 'Ruby 3.4 or Ruby 4.0 and `make`' "$README"; then
  printf '%s\n' 'README must document supported Ruby releases and `make`.' >&2
  exit 1
fi

for documented in \
  "make check" \
  "make build" \
  "scripts/check-baseline.sh" \
  'Every OpenAPI `$ref` must be a local string' \
  "Every OpenAPI response must include a non-empty"; do
  if ! grep -Fq "$documented" "$README"; then
    printf '%s\n' "README must document $documented." >&2
    exit 1
  fi
done

if ! grep -Fq "docs/plans/2026-06-09-scripted-baseline-check.md" "$VALIDATOR"; then
  printf '%s\n' "OpenAPI validator must include the scripted baseline plan." >&2
  exit 1
fi

if ! grep -Fq "docs/plans/2026-06-12-self-contained-reference-validation.md" "$VALIDATOR"; then
  printf '%s\n' "OpenAPI validator must include the self-contained reference plan." >&2
  exit 1
fi

if ! grep -Fq "docs/plans/2026-06-12-supported-ruby-matrix.md" "$VALIDATOR"; then
  printf '%s\n' "OpenAPI validator must include the supported Ruby matrix plan." >&2
  exit 1
fi

for validator_contract in \
  "response missing description" \
  "def resolve_json_pointer" \
  "contains non-local reference" \
  '$ref must be a string' \
  "validate_references(spec, spec"; do
  if ! grep -Fq "$validator_contract" "$VALIDATOR"; then
    printf '%s\n' "OpenAPI validator must preserve: $validator_contract" >&2
    exit 1
  fi
done

for mutation_contract in \
  "whitespace-only response description" \
  "dangling local reference" \
  "external URL reference" \
  "relative file reference" \
  "malformed local reference" \
  "non-string reference" \
  "Escaped~1Schema~0Name"; do
  if ! grep -Fq "$mutation_contract" "$ROOT_DIR/scripts/test-validator.sh"; then
    printf '%s\n' "Validator mutation tests must preserve: $mutation_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "docs/plans/2026-06-10-hosted-openapi-validation.md" "$VALIDATOR"; then
  printf '%s\n' "OpenAPI validator must include the hosted validation plan." >&2
  exit 1
fi

expected_workflow=$(cat <<'EOF'
name: Check

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: check-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  openapi:
    name: OpenAPI contract validation
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    strategy:
      fail-fast: false
      matrix:
        ruby-version: ["3.4", "4.0"]
    steps:
      - name: Check out repository
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false
      - name: Set up Ruby
        uses: ruby/setup-ruby@89f90524b88a01fe6e0b732220432cc6142926af # v1.313.0
        with:
          ruby-version: ${{ matrix.ruby-version }}
      - name: Validate OpenAPI contract
        run: make check
EOF
)
actual_workflow=$(cat "$WORKFLOW")
if [ "$actual_workflow" != "$expected_workflow" ]; then
  printf '%s\n' "Hosted validation must match the exact pinned, credential-free OpenAPI contract." >&2
  exit 1
fi

if ! grep -Fq 'Ruby 3.4 and Ruby 4.0' "$README"; then
  printf '%s\n' "README must document the supported Ruby 3.4 and Ruby 4.0 matrix." >&2
  exit 1
fi

if ! grep -Fq 'Supported verification runtimes: Ruby 3.4 and Ruby 4.0' "$ROOT_DIR/AGENTS.md"; then
  printf '%s\n' "AGENTS.md must document the supported Ruby matrix." >&2
  exit 1
fi

if ! grep -Fq 'Ruby 3.4 plus Ruby 4.0' "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "SECURITY.md must document the supported Ruby matrix." >&2
  exit 1
fi

if ! grep -Fq 'maintained Ruby 3.4 and Ruby 4.0' "$ROOT_DIR/VISION.md"; then
  printf '%s\n' "VISION.md must document the maintained Ruby matrix." >&2
  exit 1
fi

for policy_file in "$README" "$ROOT_DIR/AGENTS.md" "$ROOT_DIR/SECURITY.md" "$ROOT_DIR/VISION.md"; do
  if grep -Eq 'Ruby (2\.7|3\.3)' "$policy_file"; then
    printf '%s\n' "$policy_file must not advertise obsolete Ruby validation lanes." >&2
    exit 1
  fi
done

for guardrail in "make check" "spec.yaml" "security scheme" "credential-adjacent"; do
  if ! grep -Fqi "$guardrail" "$ROOT_DIR/AGENTS.md"; then
    printf '%s\n' "AGENTS.md must preserve the guardrail: $guardrail" >&2
    exit 1
  fi
done

if ! (cd / && "$VALIDATOR" >/dev/null); then
  printf '%s\n' "OpenAPI validator must run independently of the caller's working directory." >&2
  exit 1
fi

for ignored in ".env" ".env.*" "*.log" ".idea/" ".vscode/" "*.iml" ".DS_Store"; do
  if ! grep -Fq "$ignored" "$GITIGNORE"; then
    printf '%s\n' ".gitignore must include $ignored" >&2
    exit 1
  fi
done

if ! tracked_local=$(git -C "$ROOT_DIR" ls-files '.env' '.env.*' '.idea' '.vscode' '*.iml'); then
  printf '%s\n' "Baseline must be able to inspect tracked secret and editor metadata paths." >&2
  exit 1
fi
if [ -n "$tracked_local" ]; then
  printf '%s\n%s\n' "Local secrets or editor metadata must not be tracked:" "$tracked_local" >&2
  exit 1
fi

found_plan=0
for plan in "$DOCS_PLANS"/*.md; do
  [ -e "$plan" ] || continue
  found_plan=1
  completed_statuses=$(awk '
    $0 == "## Status Completed" { count += 1; next }
    $0 == "## Status" { in_status = 1; next }
    in_status && /^## / { in_status = 0 }
    in_status && $0 == "Completed" { count += 1 }
    END { print count + 0 }
  ' "$plan")
  if [ "$completed_statuses" -ne 1 ]; then
    printf '%s\n' "$plan must record completed status." >&2
    exit 1
  fi
  if ! grep -Fq "make check" "$plan"; then
    printf '%s\n' "$plan must document make check verification." >&2
    exit 1
  fi
done

if [ "$found_plan" -eq 0 ]; then
  printf '%s\n' "docs/plans must contain completed markdown plans." >&2
  exit 1
fi
