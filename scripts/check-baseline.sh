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
  "docs/plans/2026-06-12-response-description-validation.md" \
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

if ! grep -Fq 'Ruby and `make`' "$README"; then
  printf '%s\n' 'README must document Ruby and `make`.' >&2
  exit 1
fi

for documented in "make check" "make build" "scripts/check-baseline.sh" "Every OpenAPI response must include a non-empty"; do
  if ! grep -Fq "$documented" "$README"; then
    printf '%s\n' "README must document $documented." >&2
    exit 1
  fi
done

if ! grep -Fq "docs/plans/2026-06-09-scripted-baseline-check.md" "$VALIDATOR"; then
  printf '%s\n' "OpenAPI validator must include the scripted baseline plan." >&2
  exit 1
fi

if ! grep -Fq "response missing description" "$VALIDATOR"; then
  printf '%s\n' "OpenAPI validator must reject missing response descriptions." >&2
  exit 1
fi

if ! grep -Fq "docs/plans/2026-06-10-hosted-openapi-validation.md" "$VALIDATOR"; then
  printf '%s\n' "OpenAPI validator must include the hosted validation plan." >&2
  exit 1
fi

if ! grep -Fxq 'permissions:' "$WORKFLOW" || ! grep -Fxq '  contents: read' "$WORKFLOW"; then
  printf '%s\n' "Hosted validation must use read-only repository contents permission." >&2
  exit 1
fi

if ! grep -Fq 'uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10' "$WORKFLOW"; then
  printf '%s\n' "Hosted validation must pin the reviewed actions/checkout v6 commit." >&2
  exit 1
fi

if ! grep -Eq '^[[:space:]]+run: make check$' "$WORKFLOW"; then
  printf '%s\n' "Hosted validation must run the canonical make check gate." >&2
  exit 1
fi

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

tracked_local=$(git -C "$ROOT_DIR" ls-files '.env' '.env.*' '.idea' '.vscode' '*.iml' || true)
if [ -n "$tracked_local" ]; then
  printf '%s\n%s\n' "Local secrets or editor metadata must not be tracked:" "$tracked_local" >&2
  exit 1
fi

found_plan=0
for plan in "$DOCS_PLANS"/*.md; do
  [ -e "$plan" ] || continue
  found_plan=1
  if ! grep -Fq "## Status" "$plan" || ! grep -Fq "Completed" "$plan"; then
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
