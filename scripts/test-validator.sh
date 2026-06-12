#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VALIDATOR="$ROOT_DIR/scripts/validate-openapi.rb"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

"$VALIDATOR" >/dev/null

mkdir -p "$TMP_DIR/scripts" "$TMP_DIR/docs"
cp "$VALIDATOR" "$TMP_DIR/scripts/validate-openapi.rb"
cp "$ROOT_DIR/spec.md" "$TMP_DIR/spec.md"
cp -R "$ROOT_DIR/docs/plans" "$TMP_DIR/docs/plans"

assert_rejected() {
  label=$1
  if output=$("$TMP_DIR/scripts/validate-openapi.rb" 2>&1); then
    printf '%s\n' "Validator accepted a $label response description." >&2
    exit 1
  fi

  case "$output" in
    *"POST /stream-to-poe 200 response missing description"*) ;;
    *)
      printf '%s\n%s\n' "Validator returned the wrong response-description error:" "$output" >&2
      exit 1
      ;;
  esac
}

mutate_description() {
  mode=$1
  cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
  ruby - "$TMP_DIR/spec.yaml" "$mode" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
responses = spec.fetch('paths').fetch('/stream-to-poe').fetch('post').fetch('responses')
response = responses.fetch('200')
ARGV.fetch(1) == 'missing' ? response.delete('description') : response['description'] = '   '
File.write(path, YAML.dump(spec))
RUBY
}

mutate_description whitespace
assert_rejected "whitespace-only"

mutate_description missing
assert_rejected "missing"

printf '%s\n' "OpenAPI validator mutation tests passed."
