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
  expected=$2
  if output=$("$TMP_DIR/scripts/validate-openapi.rb" 2>&1); then
    printf '%s\n' "Validator accepted a $label mutation." >&2
    exit 1
  fi

  case "$output" in
    *"$expected"*) ;;
    *)
      printf '%s\n%s\n' "Validator returned the wrong mutation error:" "$output" >&2
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
assert_rejected "whitespace-only response description" "POST /stream-to-poe 200 response missing description"

mutate_description missing
assert_rejected "missing response description" "POST /stream-to-poe 200 response missing description"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec['x-validation-reference'] = { '$ref' => '#/components/schemas/MissingSchema' }
File.write(path, YAML.dump(spec))
RUBY
assert_rejected "dangling local reference" "contains unresolved local reference"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec['x-validation-reference'] = { '$ref' => 'https://example.com/shared.yaml#/Error' }
File.write(path, YAML.dump(spec))
RUBY
assert_rejected "external URL reference" "contains non-local reference"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec['x-validation-reference'] = { '$ref' => '../shared.yaml#/Error' }
File.write(path, YAML.dump(spec))
RUBY
assert_rejected "relative file reference" "contains non-local reference"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec['x-validation-reference'] = { '$ref' => '#components/schemas/Error' }
File.write(path, YAML.dump(spec))
RUBY
assert_rejected "malformed local reference" "contains invalid local reference"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec['x-validation-reference'] = { '$ref' => { 'path' => '#/components/schemas/Error' } }
File.write(path, YAML.dump(spec))
RUBY
assert_rejected "non-string reference" '$ref must be a string'

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec.fetch('components').fetch('schemas')['Escaped/Schema~Name'] = {
  'type' => 'object',
  'description' => 'Schema used to verify escaped JSON Pointer tokens.'
}
spec['x-validation-reference'] = {
  '$ref' => '#/components/schemas/Escaped~1Schema~0Name'
}
File.write(path, YAML.dump(spec))
RUBY
if ! "$TMP_DIR/scripts/validate-openapi.rb" >/dev/null; then
  printf '%s\n' "Validator rejected a valid escaped local reference." >&2
  exit 1
fi

printf '%s\n' "OpenAPI validator mutation tests passed."
