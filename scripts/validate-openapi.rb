#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

ROOT_DIR = File.expand_path('..', __dir__)
Dir.chdir(ROOT_DIR)

PLANS = [
  'docs/plans/2026-06-08-placeholder-server-validation.md',
  'docs/plans/2026-06-08-response-status-reference-validation.md',
  'docs/plans/2026-06-09-error-schema-reference-validation.md',
  'docs/plans/2026-06-09-security-scheme-reference-validation.md',
  'docs/plans/2026-06-09-schema-property-description-validation.md',
  'docs/plans/2026-06-09-component-schema-description-validation.md',
  'docs/plans/2026-06-10-security-scheme-description-validation.md',
  'docs/plans/2026-06-09-request-property-reference-validation.md',
  'docs/plans/2026-06-09-operation-security-validation.md',
  'docs/plans/2026-06-09-required-property-validation.md',
  'docs/plans/2026-06-09-scripted-baseline-check.md',
  'docs/plans/2026-06-10-hosted-openapi-validation.md',
  'docs/plans/2026-06-10-local-reference-validation.md',
  'docs/plans/2026-06-12-response-description-validation.md',
  'docs/plans/2026-06-12-self-contained-reference-validation.md',
  'docs/plans/2026-06-12-supported-ruby-matrix.md',
  'docs/plans/2026-06-13-operation-id-validation.md',
  'docs/plans/2026-06-13-path-item-metadata-validation.md',
  'docs/plans/2026-06-13-generated-markdown-spec.md',
  'docs/plans/2026-06-15-cyclic-yaml-alias-validation.md',
  'docs/plans/2026-06-15-yaml-parser-recursion-guard.md',
  'docs/plans/2026-06-16-yaml-graph-walker-depth.md',
  'docs/plans/2026-06-17-yaml-document-root-validation.md'
].freeze

HTTP_METHODS = %w[get put post delete options head patch trace].freeze
PATH_ITEM_FIELDS = (HTTP_METHODS + %w[$ref summary description servers parameters]).freeze

def cyclic_object_graph?(root)
  visiting = {}
  visited = {}
  stack = [[:enter, root]]

  until stack.empty?
    action, node = stack.pop
    next unless node.is_a?(Hash) || node.is_a?(Array)

    object_id = node.object_id
    if action == :exit
      visiting.delete(object_id)
      visited[object_id] = true
      next
    end

    return true if visiting[object_id]
    next if visited[object_id]

    visiting[object_id] = true
    stack << [:exit, node]
    if node.is_a?(Hash)
      node.each_pair do |key, value|
        stack << [:enter, value]
        stack << [:enter, key]
      end
    else
      node.each { |value| stack << [:enter, value] }
    end
  end

  false
end

spec_source = File.read('spec.yaml')
begin
  spec = YAML.safe_load(spec_source, aliases: true)
rescue SystemStackError
  warn 'spec.yaml exceeds the YAML parser nesting limit'
  exit 1
end
unless spec.is_a?(Hash)
  warn 'spec.yaml root must be a mapping for OpenAPI validation'
  exit 1
end
if cyclic_object_graph?(spec)
  warn 'spec.yaml contains cyclic YAML aliases'
  exit 1
end

reference = File.read('spec.md')
errors = []

generator = File.join(ROOT_DIR, 'scripts/generate-spec-md.rb')
unless File.file?(generator) && system(generator, '--check', out: File::NULL, err: File::NULL)
  errors << 'spec.md must match scripts/generate-spec-md.rb output'
end

def each_graph_node(root, root_path)
  visited = {}
  stack = [[root, root_path]]

  until stack.empty?
    node, path = stack.pop
    next unless node.is_a?(Hash) || node.is_a?(Array)
    next if visited[node.object_id]

    visited[node.object_id] = true
    yield node, path

    if node.is_a?(Hash)
      node.reverse_each do |key, value|
        stack << [value, "#{path}.#{key}"]
      end
    else
      (node.length - 1).downto(0) do |index|
        stack << [node[index], "#{path}[#{index}]"]
      end
    end
  end
end

def validate_property_descriptions(root, root_path, errors)
  each_graph_node(root, root_path) do |node, path|
    next unless node.is_a?(Hash)

    if node['properties'].is_a?(Hash)
      node['properties'].each do |property_name, property_schema|
        property_path = "#{path}.properties.#{property_name}"
        description = property_schema['description'].to_s.strip if property_schema.is_a?(Hash)

        errors << "spec.yaml schema property #{property_path} missing description" if description.to_s.empty?
      end
    end
  end
end

def validate_required_properties(root, root_path, errors)
  each_graph_node(root, root_path) do |node, path|
    next unless node.is_a?(Hash)

    if node['required'].is_a?(Array)
      properties = node['properties']
      if properties.is_a?(Hash)
        node['required'].each do |field|
          next if properties.key?(field)

          errors << "spec.yaml schema #{path} requires unknown field `#{field}`"
        end
      else
        errors << "spec.yaml schema #{path} declares required fields without properties"
      end
    end
  end
end

def resolve_json_pointer(document, reference)
  return document if reference == '#'
  return unless reference.start_with?('#/')

  reference.delete_prefix('#/').split('/').reduce(document) do |node, token|
    key = token.gsub('~1', '/').gsub('~0', '~')

    case node
    when Hash
      break unless node.key?(key)

      node[key]
    when Array
      break unless key.match?(/\A(?:0|[1-9]\d*)\z/) && key.to_i < node.length

      node[key.to_i]
    else
      break
    end
  end
end

def validate_references(root, document, root_path, errors)
  each_graph_node(root, root_path) do |node, path|
    next unless node.is_a?(Hash)

    if node.key?('$ref')
      reference = node['$ref']
      if !reference.is_a?(String)
        errors << "spec.yaml #{path} $ref must be a string"
      elsif !reference.start_with?('#')
        errors << "spec.yaml #{path} contains non-local reference `#{reference}`"
      elsif reference != '#' && !reference.start_with?('#/')
        errors << "spec.yaml #{path} contains invalid local reference `#{reference}`"
      elsif resolve_json_pointer(document, reference).nil?
        errors << "spec.yaml #{path} contains unresolved local reference `#{reference}`"
      end
    end
  end
end

documented_operations = {}
documented_sections = {}
documented_responses = {}
reference.split(/^### \d+\. /).drop(1).each do |section|
  endpoint = section[/^- \*\*Endpoint\*\*: `([^`]+)`/, 1]
  method = section[/^- \*\*Method\*\*: `([^`]+)`/, 1]
  operation_id = section[/^- \*\*Operation ID\*\*: `([^`]+)`/, 1]

  next unless endpoint && method

  documented_operations[[endpoint, method]] = operation_id
  documented_sections[[endpoint, method]] = section
  documented_responses[[endpoint, method]] = section.scan(/^\s+- `(\d{3})`:/).flatten
end

unless spec.fetch('openapi', '').to_s.start_with?('3.')
  errors << "spec.yaml openapi version must be 3.x"
end

paths = spec.fetch('paths', {})
components = spec.fetch('components', {})
schemas = components.fetch('schemas', {})
security_schemes = components.fetch('securitySchemes', {})
operation_ids = []

schemas.each do |schema_name, schema|
  description = schema['description'].to_s.strip if schema.is_a?(Hash)
  next unless description.to_s.empty?

  errors << "spec.yaml component schema #{schema_name} missing description"
end

PLANS.each do |plan_path|
  unless File.file?(plan_path)
    errors << "#{plan_path} must document the completed validation plan"
    next
  end

  plan = File.read(plan_path)
  errors << "#{plan_path} must be marked completed" unless plan.match?(/^## Status\s+Completed/m)
  errors << "#{plan_path} must record make check verification" unless plan.include?('make check')
end

Array(spec.fetch('servers', [])).each do |server|
  url = server.fetch('url', '').to_s
  description = server.fetch('description', '').to_s
  next unless url.include?('example.com')

  unless description.downcase.include?('placeholder')
    errors << "example.com server #{url} must be described as a placeholder in spec.yaml"
  end

  reference_line = reference.lines.find { |line| line.include?(url) }
  unless reference_line&.downcase&.include?('placeholder')
    errors << "example.com server #{url} must be described as a placeholder in spec.md"
  end
end

error_schema = schemas.fetch('Error', {})
error_section = reference[/^## Error Handling\n(?<body>.*?)(?=^## |\z)/m, :body].to_s
error_schema.fetch('properties', {}).each_key do |field|
  next if error_section.include?("\"#{field}\"") || error_section.include?("`#{field}`")

  errors << "spec.md Error Handling section missing Error schema field `#{field}`"
end

security_section = reference[/^## Security\n(?<body>.*?)(?=^## |\z)/m, :body].to_s
security_schemes.each do |scheme_name, scheme|
  scheme_description = scheme.fetch('description', '').to_s.strip
  errors << "spec.yaml security scheme #{scheme_name} missing description" if scheme_description.empty?

  unless security_section.include?("`#{scheme_name}`")
    errors << "spec.md Security section missing security scheme `#{scheme_name}`"
  end

  case scheme.fetch('type', nil)
  when 'apiKey'
    header_name = scheme.fetch('name', '').to_s
    next if header_name.empty? || security_section.include?("`#{header_name}`")

    errors << "spec.md Security section missing API key header `#{header_name}`"
  when 'http'
    http_scheme = scheme.fetch('scheme', '').to_s
    next if http_scheme.empty? || security_section.downcase.include?("`#{http_scheme.downcase}`")

    errors << "spec.md Security section missing HTTP auth scheme `#{http_scheme}`"
  end
end

validate_property_descriptions(spec, 'spec', errors)
validate_required_properties(spec, 'spec', errors)
validate_references(spec, spec, 'spec', errors)

paths.each do |path, path_item|
  unless path_item.is_a?(Hash)
    errors << "spec.yaml path item #{path} must be an object"
    next
  end

  unsupported_fields = path_item.keys.map(&:to_s) - PATH_ITEM_FIELDS
  unsupported_fields.each do |field|
    errors << "spec.yaml path item #{path} contains unsupported field `#{field}`"
  end

  path_item.each do |method, operation|
    next unless HTTP_METHODS.include?(method.to_s)

    method_name = method.to_s.upcase
    unless operation.is_a?(Hash)
      errors << "#{method_name} #{path} operation must be an object"
      next
    end

    operation_id = operation['operationId']
    documented_operation_id = documented_operations[[path, method_name]]

    if operation_id.is_a?(String) && !operation_id.strip.empty?
      operation_ids << operation_id
    else
      errors << "#{method_name} #{path} operationId must be a non-empty string"
    end

    if documented_operation_id.nil?
      errors << "spec.md missing endpoint/method section for #{method_name} #{path}"
    elsif documented_operation_id != operation_id
      errors << "spec.md missing operation ID entry for #{method_name} #{path}: #{operation_id}"
    end

    request_schema_ref = operation.dig('requestBody', 'content', 'application/json', 'schema', '$ref')
    if request_schema_ref
      unless request_schema_ref.start_with?('#/components/schemas/')
        errors << "#{method_name} #{path} requestBody should use a component schema"
        next
      end

      schema_name = request_schema_ref.delete_prefix('#/components/schemas/')
      schema = schemas.fetch(schema_name, {})
      documented_section = documented_sections.fetch([path, method_name], '')
      request_properties = schema.fetch('properties', {})

      request_properties.each_key do |field|
        next if documented_section.match?(/`#{Regexp.escape(field)}`/)

        errors << "spec.md request body for #{method_name} #{path} missing field `#{field}`"
      end

    elsif operation['requestBody']
      errors << "#{method_name} #{path} requestBody should use a component schema"
    end

    security_requirements = operation['security']
    if !security_requirements.is_a?(Array) || security_requirements.empty?
      errors << "#{method_name} #{path} missing operation-level security requirement"
    end

    Array(security_requirements).each do |security_requirement|
      unless security_requirement.is_a?(Hash) && !security_requirement.empty?
        errors << "#{method_name} #{path} security requirement must name a scheme"
        next
      end

      security_requirement.each_key do |scheme|
        errors << "#{method_name} #{path} references unknown security scheme #{scheme}" unless security_schemes.key?(scheme)
      end
    end

    responses = operation.fetch('responses', {})
    response_statuses = responses.keys.map(&:to_s)
    documented_statuses = documented_responses.fetch([path, method_name], [])

    documented_duplicates = documented_statuses.tally.select { |_status, count| count > 1 }.keys
    unless documented_duplicates.empty?
      errors << "spec.md response list for #{method_name} #{path} duplicates #{documented_duplicates.join(', ')}"
    end

    (response_statuses - documented_statuses).each do |status|
      errors << "spec.md response list for #{method_name} #{path} missing #{status}"
    end

    (documented_statuses - response_statuses).each do |status|
      errors << "spec.md response list for #{method_name} #{path} documents unknown #{status}"
    end

    %w[200 400 401 500].each do |status|
      errors << "#{method_name} #{path} missing #{status} response" unless responses.key?(status)
    end

    responses.each do |status, response|
      description = response.fetch('description', '').to_s.strip
      if description.empty?
        errors << "#{method_name} #{path} #{status} response missing description"
      end

      next if status.to_s.start_with?('2')

      schema = response.dig('content', 'application/json', 'schema')
      next if schema && schema['$ref'] == '#/components/schemas/Error'

      errors << "#{method_name} #{path} #{status} response should use the shared Error schema"
    end
  end
end

documented_operations.each_key do |path, method_name|
  path_item = paths[path]
  next if path_item.is_a?(Hash) && path_item[method_name.downcase].is_a?(Hash)

  errors << "spec.md documents #{method_name} #{path}, but spec.yaml has no matching operation"
end

duplicates = operation_ids.tally.select { |_id, count| count > 1 }.keys
errors << "duplicate operationId values: #{duplicates.join(', ')}" unless duplicates.empty?

if errors.any?
  warn errors.join("\n")
  exit 1
end

puts "OpenAPI validation passed for #{paths.length} paths and #{operation_ids.length} operations."
