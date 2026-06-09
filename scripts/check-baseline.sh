#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT_DIR/README.md"
MAKEFILE="$ROOT_DIR/Makefile"
GITIGNORE="$ROOT_DIR/.gitignore"
VALIDATOR="$ROOT_DIR/scripts/validate-openapi.rb"
DOCS_PLANS="$ROOT_DIR/docs/plans"

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
  "scripts/validate-openapi.rb" \
  "docs/plans/2026-06-08-placeholder-server-validation.md" \
  "docs/plans/2026-06-09-scripted-baseline-check.md" \
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

if ! [ -x "$VALIDATOR" ]; then
  printf '%s\n' "scripts/validate-openapi.rb must be executable." >&2
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

for documented in "make check" "make build" "scripts/check-baseline.sh"; do
  if ! grep -Fq "$documented" "$README"; then
    printf '%s\n' "README must document $documented." >&2
    exit 1
  fi
done

if ! grep -Fq "docs/plans/2026-06-09-scripted-baseline-check.md" "$VALIDATOR"; then
  printf '%s\n' "OpenAPI validator must include the scripted baseline plan." >&2
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
