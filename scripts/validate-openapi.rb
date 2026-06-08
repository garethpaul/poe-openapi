#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

spec = YAML.safe_load(File.read('spec.yaml'), aliases: true)
reference = File.read('spec.md')
errors = []

documented_operations = {}
reference.split(/^### \d+\. /).drop(1).each do |section|
  endpoint = section[/^- \*\*Endpoint\*\*: `([^`]+)`/, 1]
  method = section[/^- \*\*Method\*\*: `([^`]+)`/, 1]
  operation_id = section[/^- \*\*Operation ID\*\*: `([^`]+)`/, 1]

  documented_operations[[endpoint, method]] = operation_id if endpoint && method
end

unless spec.fetch('openapi', '').to_s.start_with?('3.')
  errors << "spec.yaml openapi version must be 3.x"
end

paths = spec.fetch('paths', {})
security_schemes = spec.fetch('components', {}).fetch('securitySchemes', {})
operation_ids = []

paths.each do |path, methods|
  methods.each do |method, operation|
    method_name = method.to_s.upcase
    operation_id = operation['operationId']
    documented_operation_id = documented_operations[[path, method_name]]

    errors << "#{method_name} #{path} missing operationId" if operation_id.nil? || operation_id.empty?
    operation_ids << operation_id if operation_id

    if documented_operation_id.nil?
      errors << "spec.md missing endpoint/method section for #{method_name} #{path}"
    elsif documented_operation_id != operation_id
      errors << "spec.md missing operation ID entry for #{method_name} #{path}: #{operation_id}"
    end

    Array(operation['security']).each do |security_requirement|
      security_requirement.each_key do |scheme|
        errors << "#{method_name} #{path} references unknown security scheme #{scheme}" unless security_schemes.key?(scheme)
      end
    end

    responses = operation.fetch('responses', {})
    %w[200 400 401 500].each do |status|
      errors << "#{method_name} #{path} missing #{status} response" unless responses.key?(status)
    end

    responses.each do |status, response|
      next if status.to_s.start_with?('2')

      schema = response.dig('content', 'application/json', 'schema')
      next if schema && schema['$ref'] == '#/components/schemas/Error'

      errors << "#{method_name} #{path} #{status} response should use the shared Error schema"
    end
  end
end

documented_operations.each_key do |path, method_name|
  next if paths.dig(path, method_name.downcase)

  errors << "spec.md documents #{method_name} #{path}, but spec.yaml has no matching operation"
end

duplicates = operation_ids.tally.select { |_id, count| count > 1 }.keys
errors << "duplicate operationId values: #{duplicates.join(', ')}" unless duplicates.empty?

if errors.any?
  warn errors.join("\n")
  exit 1
end

puts "OpenAPI validation passed for #{paths.length} paths and #{operation_ids.length} operations."
