#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/poe-openapi-generator.XXXXXX")
trap 'rm -rf "$WORK_DIR"' EXIT HUP INT TERM

mkdir -p "$WORK_DIR/scripts"
cp "$ROOT_DIR/scripts/generate-spec-md.rb" "$WORK_DIR/scripts/"
cp "$ROOT_DIR/spec.yaml" "$ROOT_DIR/spec.md" "$WORK_DIR/"
chmod +x "$WORK_DIR/scripts/generate-spec-md.rb"

"$ROOT_DIR/scripts/generate-spec-md.rb" --check

assert_document_root_rejected() {
  label=$1
  cp "$ROOT_DIR/spec.md" "$WORK_DIR/spec.md"
  if output=$("$WORK_DIR/scripts/generate-spec-md.rb" 2>&1); then
    printf '%s\n' "generator accepted a $label YAML document root" >&2
    exit 1
  fi
  if [ "$output" != "spec.yaml root must be a mapping for Markdown generation" ]; then
    printf '%s\n%s\n' "generator returned the wrong $label root error:" "$output" >&2
    exit 1
  fi
  cmp "$ROOT_DIR/spec.md" "$WORK_DIR/spec.md"
}

assert_container_shape_rejected() {
  label=$1
  field_path=$2
  invalid_yaml=$3
  expected=$4
  cp "$ROOT_DIR/spec.yaml" "$WORK_DIR/spec.yaml"
  cp "$ROOT_DIR/spec.md" "$WORK_DIR/spec.md"
  ruby -ryaml - "$WORK_DIR/spec.yaml" "$field_path" "$invalid_yaml" <<'RUBY'
path, field_path, invalid_yaml = ARGV
spec = YAML.safe_load(File.read(path), aliases: true)
keys = field_path.split('.')
container = keys[0...-1].reduce(spec) do |node, key|
  node.is_a?(Array) ? node.fetch(Integer(key)) : node.fetch(key)
end
replacement = YAML.safe_load(invalid_yaml, aliases: true)
container.is_a?(Array) ? container[Integer(keys.last)] = replacement : container[keys.last] = replacement
File.write(path, YAML.dump(spec))
RUBY
  if output=$("$WORK_DIR/scripts/generate-spec-md.rb" 2>&1); then
    printf '%s\n' "generator accepted malformed $label" >&2
    exit 1
  fi
  if [ "$output" != "$expected" ]; then
    printf '%s\n%s\n' "generator returned the wrong $label error:" "$output" >&2
    exit 1
  fi
  cmp "$ROOT_DIR/spec.md" "$WORK_DIR/spec.md"
}

: > "$WORK_DIR/spec.yaml"
assert_document_root_rejected "empty"
printf '%s\n' 'scalar-root' > "$WORK_DIR/spec.yaml"
assert_document_root_rejected "scalar"
printf '%s\n' '- sequence-root' > "$WORK_DIR/spec.yaml"
assert_document_root_rejected "sequence"

assert_container_shape_rejected info info '[]' 'spec.yaml info must be a mapping'
assert_container_shape_rejected paths paths '[]' 'spec.yaml paths must be a mapping'
assert_container_shape_rejected components components '[]' 'spec.yaml components must be a mapping'
assert_container_shape_rejected components.schemas components.schemas '[]' 'spec.yaml components.schemas must be a mapping'
assert_container_shape_rejected components.securitySchemes components.securitySchemes '[]' 'spec.yaml components.securitySchemes must be a mapping'
assert_container_shape_rejected servers servers 'invalid' 'spec.yaml servers must be an array'
assert_container_shape_rejected info.contact info.contact '[]' 'spec.yaml info.contact must be a mapping'
assert_container_shape_rejected info.license info.license '[]' 'spec.yaml info.license must be a mapping'
assert_container_shape_rejected servers.0 servers.0 'invalid' 'spec.yaml servers[0] must be a mapping'
assert_container_shape_rejected component.schema components.schemas.Error 'invalid' 'spec.yaml components.schemas.Error must be a mapping'
assert_container_shape_rejected schema.properties components.schemas.SseConversionRequest.properties '[]' 'spec.yaml components.schemas.SseConversionRequest.properties must be a mapping'
assert_container_shape_rejected schema.property components.schemas.SseConversionRequest.properties.contentType 'invalid' 'spec.yaml components.schemas.SseConversionRequest.properties.contentType must be a mapping'
assert_container_shape_rejected security.scheme components.securitySchemes.ApiKeyAuth 'invalid' 'spec.yaml components.securitySchemes.ApiKeyAuth must be a mapping'
assert_container_shape_rejected path.item paths./stream-to-poe '[]' 'spec.yaml path item /stream-to-poe must be an object'
assert_container_shape_rejected operation paths./stream-to-poe.post 'invalid' 'POST /stream-to-poe operation must be an object'
assert_container_shape_rejected requestBody paths./stream-to-poe.post.requestBody 'invalid' 'POST /stream-to-poe requestBody must be an object'
assert_container_shape_rejected responses paths./stream-to-poe.post.responses '[]' 'POST /stream-to-poe responses must be an object'
assert_container_shape_rejected response paths./stream-to-poe.post.responses.200 'invalid' 'POST /stream-to-poe 200 response must be an object'

cp "$ROOT_DIR/spec.yaml" "$WORK_DIR/spec.yaml"
cp "$WORK_DIR/spec.md" "$WORK_DIR/spec.md.before-recursion"
ruby - "$WORK_DIR/spec.yaml" <<'RUBY'
path = ARGV.fetch(0)
File.open(path, 'a') do |file|
  file.puts 'x-deep-acyclic:'
  1.upto(2_000) { |index| file.puts(('  ' * index) + "level#{index}:") }
  file.puts(('  ' * 2_001) + 'value: leaf')
end
RUBY
if output=$(ruby -rtimeout -e 'path = ARGV.shift; Timeout.timeout(5) { load path }' \
  "$WORK_DIR/scripts/generate-spec-md.rb" 2>&1); then
  printf '%s\n' 'generator accepted YAML beyond the parser nesting limit' >&2
  exit 1
fi
if [ "$output" != "spec.yaml exceeds the YAML generator parser nesting limit" ]; then
  printf '%s\n%s\n' 'generator returned the wrong parser recursion error:' "$output" >&2
  exit 1
fi
cmp "$WORK_DIR/spec.md.before-recursion" "$WORK_DIR/spec.md"
cp "$ROOT_DIR/spec.yaml" "$WORK_DIR/spec.yaml"
printf '%s\n' '<!-- drift -->' >> "$WORK_DIR/spec.md"
if output=$("$WORK_DIR/scripts/generate-spec-md.rb" --check 2>&1); then
  printf '%s\n' 'generator check accepted stale Markdown' >&2
  exit 1
fi
printf '%s\n' "$output" | grep -Fq 'spec.md is out of date; run scripts/generate-spec-md.rb'

"$WORK_DIR/scripts/generate-spec-md.rb" >/dev/null
"$WORK_DIR/scripts/generate-spec-md.rb" --check
for contract in \
  '<!-- Generated by scripts/generate-spec-md.rb from spec.yaml. Do not edit directly. -->' \
  '- **Endpoint**: `/stream-to-poe`' \
  '- **Operation ID**: `convertSseToPoe`' \
  '`sseUrl` (string, required)' \
  '`metadata` (Identifier or null, optional)' \
  '- `404`: SSE stream not found' \
  '**`ApiKeyAuth`**' \
  '"details"'; do
  grep -Fq -- "$contract" "$WORK_DIR/spec.md"
done

cp "$ROOT_DIR/spec.yaml" "$WORK_DIR/spec.yaml"
ruby - "$WORK_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec.fetch('info')['title'] = 'Mutation Contract'
spec.fetch('info')['version'] = '9.9.9'
spec.fetch('servers').first['description'] = 'Mutation server'
operation = spec.fetch('paths').fetch('/stream-to-poe').fetch('post')
operation['summary'] = 'Mutation operation summary'
operation['operationId'] = 'mutationOperation'
operation['description'] = 'Mutation operation description.'
operation.fetch('responses').fetch('404')['description'] = 'Mutation response description'
property = spec.fetch('components').fetch('schemas').fetch('SseConversionRequest').fetch('properties').fetch('contentType')
property['description'] = 'Mutation field description'
property['default'] = 'mutation/type'
security = spec.fetch('components').fetch('securitySchemes').fetch('ApiKeyAuth')
security['name'] = 'X-Mutation-Key'
security['description'] = 'Mutation security description.'
spec.fetch('components').fetch('schemas').fetch('Error').fetch('properties').fetch('message')['example'] = 'Mutation error example'
File.write(path, YAML.dump(spec))
RUBY
"$WORK_DIR/scripts/generate-spec-md.rb" >/dev/null
for mutation in \
  '# Mutation Contract API' \
  '- **Version**: 9.9.9' \
  '**Mutation server**' \
  '### 1. Mutation operation summary' \
  '- **Operation ID**: `mutationOperation`' \
  'Mutation operation description.' \
  'Mutation field description (default: `mutation/type`)' \
  '- `404`: Mutation response description' \
  'X-Mutation-Key' \
  'Mutation security description.' \
  'Mutation error example'; do
  grep -Fq -- "$mutation" "$WORK_DIR/spec.md"
done
"$WORK_DIR/scripts/generate-spec-md.rb" --check

cp "$ROOT_DIR/spec.yaml" "$WORK_DIR/spec.yaml"
ruby - "$WORK_DIR/spec.yaml" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
spec = YAML.safe_load(File.read(path), aliases: true)
spec.fetch('info')['title'] = 'Unsafe [Title](javascript:alert(1)) <script>'
spec.fetch('info')['description'] = 'Overview [link](javascript:alert(1)) with <b>HTML</b>.'
spec.fetch('info').fetch('contact')['name'] = 'Support [Team]'
spec.fetch('info').fetch('contact')['url'] = 'javascript:alert(1)'
spec.fetch('info').fetch('license')['name'] = 'Apache <License>'
spec.fetch('servers').first['description'] = 'Primary **server** <img src=x>'
operation = spec.fetch('paths').fetch('/stream-to-poe').fetch('post')
operation['summary'] = 'Summary [jump](javascript:alert(1)) <script>'
operation['description'] = 'Description with [link](javascript:alert(1)) and <tag>.'
property = spec.fetch('components').fetch('schemas').fetch('SseConversionRequest').fetch('properties').fetch('contentType')
property['description'] = 'Field `code` and [link](javascript:alert(1)) <tag>'
property['default'] = 'type`with`tick'
security = spec.fetch('components').fetch('securitySchemes').fetch('ApiKeyAuth')
security['description'] = 'Security [link](javascript:alert(1)) <tag>.'
File.write(path, YAML.dump(spec))
RUBY
"$WORK_DIR/scripts/generate-spec-md.rb" >/dev/null
for escaped in \
  '# Unsafe \[Title\](javascript:alert(1)) &lt;script&gt; API' \
  'Overview \[link\](javascript:alert(1)) with &lt;b&gt;HTML&lt;/b&gt;.' \
  '- **Contact**: Support \[Team\] (`javascript:alert(1)`) (support@example.com)' \
  '- **License**: [Apache &lt;License&gt;](https://www.apache.org/licenses/LICENSE-2.0.html)' \
  '**Primary \*\*server\*\* &lt;img src=x&gt;**' \
  '### 1. Summary \[jump\](javascript:alert(1)) &lt;script&gt;' \
  'Description with \[link\](javascript:alert(1)) and &lt;tag&gt;.' \
  'Field \`code\` and \[link\](javascript:alert(1)) &lt;tag&gt; (default: `` type`with`tick ``)' \
  'Security \[link\](javascript:alert(1)) &lt;tag&gt;.'; do
  grep -Fq -- "$escaped" "$WORK_DIR/spec.md"
done
if grep -Fq '<script' "$WORK_DIR/spec.md" ||
   grep -Fq '<tag>' "$WORK_DIR/spec.md" ||
   grep -Fq '<img' "$WORK_DIR/spec.md" ||
   grep -Eq '(^|[^\\])\]\(javascript:' "$WORK_DIR/spec.md"; then
  printf '%s\n' 'Generated Markdown retained unescaped HTML or a clickable javascript link.' >&2
  exit 1
fi
"$WORK_DIR/scripts/generate-spec-md.rb" --check

if output=$("$WORK_DIR/scripts/generate-spec-md.rb" unexpected 2>&1); then
  printf '%s\n' 'generator accepted an unsupported argument' >&2
  exit 1
fi
printf '%s\n' "$output" | grep -Fq 'usage: scripts/generate-spec-md.rb [--check]'

printf '%s\n' 'Generated Markdown contract tests passed.'
