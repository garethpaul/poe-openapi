#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VALIDATOR="$ROOT_DIR/scripts/validate-openapi.rb"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

"$VALIDATOR" >/dev/null

mkdir -p "$TMP_DIR/scripts" "$TMP_DIR/docs"
cp "$VALIDATOR" "$TMP_DIR/scripts/validate-openapi.rb"
cp "$ROOT_DIR/scripts/generate-spec-md.rb" "$TMP_DIR/scripts/generate-spec-md.rb"
cp "$ROOT_DIR/spec.md" "$TMP_DIR/spec.md"
cp -R "$ROOT_DIR/docs/plans" "$TMP_DIR/docs/plans"
mv "$TMP_DIR/scripts/generate-spec-md.rb" "$TMP_DIR/scripts/generate-spec-md.real.rb"
cat > "$TMP_DIR/scripts/generate-spec-md.rb" <<'SH'
#!/usr/bin/env sh
set -eu

if [ -n "${GENERATOR_CALL_LOG:-}" ]; then
  : > "$GENERATOR_CALL_LOG"
fi
exec "$(dirname "$0")/generate-spec-md.real.rb" "$@"
SH
chmod +x "$TMP_DIR/scripts/generate-spec-md.rb" "$TMP_DIR/scripts/generate-spec-md.real.rb"

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

assert_cycle_rejected() {
  label=$1
  call_log="$TMP_DIR/generator-call"
  rm -f "$call_log"
  if output=$(GENERATOR_CALL_LOG="$call_log" ruby -rtimeout -e \
    'Timeout.timeout(5) { load ARGV.fetch(0) }' \
    "$TMP_DIR/scripts/validate-openapi.rb" 2>&1); then
    printf '%s\n' "Validator accepted a $label." >&2
    exit 1
  fi
  if [ "$output" != "spec.yaml contains cyclic YAML aliases" ]; then
    printf '%s\n%s\n' "Validator returned the wrong $label error:" "$output" >&2
    exit 1
  fi
  if [ -e "$call_log" ]; then
    printf '%s\n' "The generator must not run for cyclic aliases." >&2
    exit 1
  fi
}

assert_parser_recursion_rejected() {
  call_log="$TMP_DIR/generator-call"
  rm -f "$call_log"
  if output=$(GENERATOR_CALL_LOG="$call_log" ruby -rtimeout -e \
    'Timeout.timeout(5) { load ARGV.fetch(0) }' \
    "$TMP_DIR/scripts/validate-openapi.rb" 2>&1); then
    printf '%s\n' 'Validator accepted YAML beyond the parser nesting limit.' >&2
    exit 1
  fi
  if [ "$output" != "spec.yaml exceeds the YAML parser nesting limit" ]; then
    printf '%s\n%s\n' 'Validator returned the wrong parser recursion error:' "$output" >&2
    exit 1
  fi
  if [ -e "$call_log" ]; then
    printf '%s\n' 'The generator must not run after YAML parser recursion failure.' >&2
    exit 1
  fi
}

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
path = ARGV.fetch(0)
File.open(path, 'a') do |file|
  file.puts 'x-deep-acyclic:'
  1.upto(2_000) { |index| file.puts(('  ' * index) + "level#{index}:") }
  file.puts(('  ' * 2_001) + 'value: leaf')
end
RUBY
assert_parser_recursion_rejected

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
path = ARGV.fetch(0)
File.open(path, 'a') do |file|
  file.puts 'x-shallow-acyclic:'
  1.upto(100) { |index| file.puts(('  ' * index) + "level#{index}:") }
  file.puts(('  ' * 101) + 'value: leaf')
end
RUBY
if ! "$TMP_DIR/scripts/validate-openapi.rb" >/dev/null; then
  printf '%s\n' 'Validator rejected a shallow acyclic YAML mapping.' >&2
  exit 1
fi

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
path = ARGV.fetch(0)
File.open(path, 'a') do |file|
  file.puts 'x-alias-node-0: &alias-node-0 {value: leaf}'
  1.upto(5_000) do |index|
    file.puts "x-alias-node-#{index}: &alias-node-#{index} {next: *alias-node-#{index - 1}}"
  end
end
RUBY
if ! output=$(ruby -rtimeout -e 'Timeout.timeout(10) { load ARGV.fetch(0) }' \
  "$TMP_DIR/scripts/validate-openapi.rb" 2>&1); then
  printf '%s\n%s\n' 'Validator rejected a deep acyclic YAML alias graph:' "$output" >&2
  exit 1
fi
if printf '%s\n' "$output" | grep -Fq 'SystemStackError'; then
  printf '%s\n%s\n' 'Deep acyclic YAML alias graph exhausted the validator stack:' "$output" >&2
  exit 1
fi

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
printf '\nx-invalid: [\n' >> "$TMP_DIR/spec.yaml"
if output=$("$TMP_DIR/scripts/validate-openapi.rb" 2>&1); then
  printf '%s\n' 'Validator accepted malformed YAML.' >&2
  exit 1
fi
case "$output" in
  *'Psych::SyntaxError'*) ;;
  *)
    printf '%s\n%s\n' 'Malformed YAML did not preserve its syntax error:' "$output" >&2
    exit 1
    ;;
esac
if printf '%s\n' "$output" | grep -Fq 'spec.yaml exceeds the YAML parser nesting limit'; then
  printf '%s\n' 'Malformed YAML was mislabeled as parser recursion.' >&2
  exit 1
fi

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
cat >> "$TMP_DIR/spec.yaml" <<'YAML'
x-cyclic-alias: &cyclic-alias
  self: *cyclic-alias
YAML
assert_cycle_rejected "cyclic YAML alias"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
cat >> "$TMP_DIR/spec.yaml" <<'YAML'
x-cyclic-array: &cyclic-array
  - *cyclic-array
YAML
assert_cycle_rejected "cyclic YAML array alias"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
cat >> "$TMP_DIR/spec.yaml" <<'YAML'
x-cyclic-key: &cyclic-key
  ? *cyclic-key
  : recursive-key
YAML
assert_cycle_rejected "cyclic YAML mapping key"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
path = ARGV.fetch(0)
File.open(path, 'a') do |file|
  file.puts 'x-deep-cycle: &deep-cycle-0'
  file.puts '  - *deep-cycle-0'
  1.upto(12_000) do |index|
    file.puts "x-deep-cycle: &deep-cycle-#{index}"
    file.puts "  - *deep-cycle-#{index - 1}"
  end
end
RUBY
assert_cycle_rejected "deep cyclic YAML alias chain"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
cat >> "$TMP_DIR/spec.yaml" <<'YAML'
x-shared-alias: &shared-alias
  nested:
    value: reusable
x-shared-alias-copy: *shared-alias
YAML
if ! "$TMP_DIR/scripts/validate-openapi.rb" >/dev/null; then
  printf '%s\n' "Validator rejected an acyclic shared YAML alias." >&2
  exit 1
fi

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

mutate_operation_id() {
  mode=$1
  cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
  ruby - "$TMP_DIR/spec.yaml" "$mode" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
operations = spec.fetch('paths')
first = operations.fetch('/stream-to-poe').fetch('post')

case ARGV.fetch(1)
when 'missing'
  first.delete('operationId')
when 'whitespace'
  first['operationId'] = '   '
when 'non-string'
  first['operationId'] = 123
when 'duplicate'
  operations.fetch('/poe-to-stream').fetch('post')['operationId'] = first.fetch('operationId')
end

File.write(path, YAML.dump(spec))
RUBY
}

mutate_operation_id missing
assert_rejected "missing operation ID" "POST /stream-to-poe operationId must be a non-empty string"

mutate_operation_id whitespace
assert_rejected "whitespace-only operation ID" "POST /stream-to-poe operationId must be a non-empty string"

mutate_operation_id non-string
assert_rejected "non-string operation ID" "POST /stream-to-poe operationId must be a non-empty string"

mutate_operation_id duplicate
assert_rejected "duplicate operation ID" "duplicate operationId values: convertSseToPoe"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
path_item = spec.fetch('paths').fetch('/stream-to-poe')
path_item['summary'] = 'Shared stream conversion path'
path_item['description'] = 'Metadata shared by operations under this path.'
path_item['servers'] = [{ 'url' => 'https://api.example.com/v1' }]
path_item['parameters'] = []
File.write(path, YAML.dump(spec))
RUBY
"$TMP_DIR/scripts/generate-spec-md.rb" >/dev/null
if ! "$TMP_DIR/scripts/validate-openapi.rb" >/dev/null; then
  printf '%s\n' "Validator rejected standard Path Item metadata." >&2
  exit 1
fi

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec.fetch('paths').fetch('/stream-to-poe')['fetch'] = {}
File.write(path, YAML.dump(spec))
RUBY
assert_rejected "unsupported Path Item field" 'path item /stream-to-poe contains unsupported field `fetch`'

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec.fetch('paths')['/stream-to-poe'] = []
File.write(path, YAML.dump(spec))
RUBY
assert_rejected "non-object Path Item" "path item /stream-to-poe must be an object"

cp "$ROOT_DIR/spec.yaml" "$TMP_DIR/spec.yaml"
ruby - "$TMP_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec.fetch('paths').fetch('/stream-to-poe')['post'] = 'invalid'
File.write(path, YAML.dump(spec))
RUBY
assert_rejected "non-object operation" "POST /stream-to-poe operation must be an object"

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
