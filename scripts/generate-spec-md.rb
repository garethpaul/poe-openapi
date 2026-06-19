#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'

ROOT_DIR = File.expand_path('..', __dir__)
SPEC_PATH = File.join(ROOT_DIR, 'spec.yaml')
REFERENCE_PATH = File.join(ROOT_DIR, 'spec.md')
HTTP_METHODS = %w[get put post delete options head patch trace].freeze

def normalized_text(value)
  value.to_s.lines.map(&:strip).reject(&:empty?).join(' ')
end

def markdown_text(value)
  normalized_text(value).gsub(/[\\\[\]`*_]/) { |character| "\\#{character}" }
                        .gsub('<', '&lt;')
                        .gsub('>', '&gt;')
end

def markdown_code(value)
  text = value.to_s
  fence = '`' * ((text.scan(/`+/).map(&:length).max || 0) + 1)
  padding = text.include?('`') || text.start_with?(' ') || text.end_with?(' ') ? ' ' : ''

  "#{fence}#{padding}#{text}#{padding}#{fence}"
end

def safe_markdown_url(value)
  url = value.to_s.strip
  return if url.empty?
  return url if url.match?(/\Ahttps?:\/\/[^\s<>()]+\z/)
end

def markdown_link(label, url)
  safe_url = safe_markdown_url(url)
  return "#{markdown_text(label)} (#{markdown_code(url)})" unless safe_url

  "[#{markdown_text(label)}](#{safe_url})"
end

def schema_type(schema)
  return schema.fetch('$ref').split('/').last if schema.key?('$ref')

  type = schema.fetch('type', 'value').to_s
  return type unless type == 'array'

  "array of #{schema_type(schema.fetch('items', {}))}"
end

def render_default(value)
  value.is_a?(String) ? value : JSON.generate(value)
end

def request_schema(spec, operation)
  schema = operation.dig('requestBody', 'content', 'application/json', 'schema')
  return unless schema.is_a?(Hash)
  return schema unless schema['$ref']

  spec.dig('components', 'schemas', schema.fetch('$ref').split('/').last)
end

def error_example(schema)
  schema.fetch('properties', {}).each_with_object({}) do |(name, property), example|
    example[name] = property.fetch('example', property.fetch('type', 'value'))
  end
end

def openapi_container_shape_error(spec)
  return 'spec.yaml info must be a mapping' unless spec['info'].is_a?(Hash)
  return 'spec.yaml paths must be a mapping' unless spec['paths'].is_a?(Hash)

  info = spec['info']
  contact = info['contact']
  return 'spec.yaml info.contact must be a mapping' if !contact.nil? && !contact.is_a?(Hash)

  license = info['license']
  return 'spec.yaml info.license must be a mapping' if !license.nil? && !license.is_a?(Hash)

  components = spec['components']
  return 'spec.yaml components must be a mapping' if !components.nil? && !components.is_a?(Hash)

  if components.is_a?(Hash)
    schemas = components['schemas']
    return 'spec.yaml components.schemas must be a mapping' if !schemas.nil? && !schemas.is_a?(Hash)
    if schemas.is_a?(Hash)
      schemas.each do |schema_name, schema|
        return "spec.yaml components.schemas.#{schema_name} must be a mapping" unless schema.is_a?(Hash)

        properties = schema['properties']
        unless properties.nil? || properties.is_a?(Hash)
          return "spec.yaml components.schemas.#{schema_name}.properties must be a mapping"
        end

        next unless properties.is_a?(Hash)

        properties.each do |property_name, property_schema|
          next if property_schema.is_a?(Hash)

          return "spec.yaml components.schemas.#{schema_name}.properties.#{property_name} must be a mapping"
        end
      end
    end

    security_schemes = components['securitySchemes']
    if !security_schemes.nil? && !security_schemes.is_a?(Hash)
      return 'spec.yaml components.securitySchemes must be a mapping'
    end
    if security_schemes.is_a?(Hash)
      security_schemes.each do |scheme_name, scheme|
        return "spec.yaml components.securitySchemes.#{scheme_name} must be a mapping" unless scheme.is_a?(Hash)
      end
    end
  end

  servers = spec['servers']
  return 'spec.yaml servers must be an array' if !servers.nil? && !servers.is_a?(Array)
  if servers.is_a?(Array)
    servers.each_with_index do |server, index|
      return "spec.yaml servers[#{index}] must be a mapping" unless server.is_a?(Hash)
    end
  end

  spec['paths'].each do |path, path_item|
    return "spec.yaml path item #{path} must be an object" unless path_item.is_a?(Hash)

    path_item.each do |method, operation|
      next unless HTTP_METHODS.include?(method.to_s)

      method_name = method.to_s.upcase
      return "#{method_name} #{path} operation must be an object" unless operation.is_a?(Hash)

      request_body = operation['requestBody']
      return "#{method_name} #{path} requestBody must be an object" if !request_body.nil? && !request_body.is_a?(Hash)

      if request_body.is_a?(Hash)
        content = request_body['content']
        return "#{method_name} #{path} requestBody.content must be an object" if !content.nil? && !content.is_a?(Hash)

        json_content = content['application/json'] if content.is_a?(Hash)
        if !json_content.nil? && !json_content.is_a?(Hash)
          return "#{method_name} #{path} requestBody application/json content must be an object"
        end

        schema = json_content['schema'] if json_content.is_a?(Hash)
        return "#{method_name} #{path} requestBody schema must be an object" if !schema.nil? && !schema.is_a?(Hash)
      end

      responses = operation['responses']
      return "#{method_name} #{path} responses must be an object" if !responses.nil? && !responses.is_a?(Hash)
      next unless responses.is_a?(Hash)

      responses.each do |status, response|
        return "#{method_name} #{path} #{status} response must be an object" unless response.is_a?(Hash)

        content = response['content']
        return "#{method_name} #{path} #{status} response content must be an object" if !content.nil? && !content.is_a?(Hash)

        json_content = content['application/json'] if content.is_a?(Hash)
        if !json_content.nil? && !json_content.is_a?(Hash)
          return "#{method_name} #{path} #{status} response application/json content must be an object"
        end

        schema = json_content['schema'] if json_content.is_a?(Hash)
        return "#{method_name} #{path} #{status} response schema must be an object" if !schema.nil? && !schema.is_a?(Hash)
      end
    end
  end

  nil
end

def generate_reference(spec)
  info = spec.fetch('info')
  lines = []
  title = info.fetch('title').to_s
  title = "#{title} API" unless title.end_with?('API')
  lines << "# #{markdown_text(title)}"
  lines << ''
  lines << '<!-- Generated by scripts/generate-spec-md.rb from spec.yaml. Do not edit directly. -->'
  lines << ''
  lines << '## Overview'
  lines << ''
  lines << markdown_text(info['description'])
  lines << ''
  lines << '## API Information'
  lines << ''
  lines << "- **Version**: #{markdown_text(info.fetch('version'))}"
  contact = info.fetch('contact', {})
  lines << "- **Contact**: #{markdown_link(contact.fetch('name'), contact.fetch('url'))} (#{markdown_text(contact.fetch('email'))})"
  license = info.fetch('license', {})
  lines << "- **License**: #{markdown_link(license.fetch('name'), license.fetch('url'))}"
  lines << ''
  lines << '## Servers'
  lines << ''
  Array(spec['servers']).each do |server|
    lines << "- **#{markdown_text(server['description'])}**: #{markdown_code(server.fetch('url'))}"
  end
  lines << ''
  lines << '## Endpoints'

  operation_number = 0
  spec.fetch('paths').each do |path, path_item|
    path_item.each do |method, operation|
      next unless HTTP_METHODS.include?(method.to_s)

      operation_number += 1
      lines << ''
      lines << "### #{operation_number}. #{markdown_text(operation.fetch('summary'))}"
      lines << ''
      lines << "- **Endpoint**: #{markdown_code(path)}"
      lines << "- **Method**: #{markdown_code(method.to_s.upcase)}"
      lines << "- **Operation ID**: #{markdown_code(operation.fetch('operationId'))}"
      lines << "- **Description**: #{markdown_text(operation['description'])}"
      schema = request_schema(spec, operation)
      if schema
        required = Array(schema['required'])
        lines << '- **Request Body**:'
        schema.fetch('properties', {}).each do |name, property|
          requirement = required.include?(name) ? 'required' : 'optional'
          detail = markdown_text(property['description'])
          detail += " (default: #{markdown_code(render_default(property['default']))})" if property.key?('default')
          lines << "  - #{markdown_code(name)} (#{markdown_text(schema_type(property))}, #{requirement}): #{detail}"
        end
      end
      lines << ''
      lines << '- **Responses**:'
      operation.fetch('responses', {}).each do |status, response|
        lines << "  - #{markdown_code(status)}: #{markdown_text(response['description'])}"
      end
    end
  end

  lines << ''
  lines << '## Security'
  lines << ''
  lines << 'The API uses the following authentication schemes:'
  lines << ''
  spec.dig('components', 'securitySchemes').each do |name, scheme|
    detail = case scheme.fetch('type')
             when 'apiKey'
               "API key in the #{markdown_text(scheme.fetch('in'))} #{markdown_code(scheme.fetch('name'))}"
             when 'http'
               "HTTP #{markdown_code(scheme.fetch('scheme'))} authentication"
             else
               markdown_text(scheme.fetch('type'))
             end
    lines << "- **#{markdown_code(name)}**: #{detail}. #{markdown_text(scheme['description'])}"
  end

  error_schema = spec.dig('components', 'schemas', 'Error')
  lines << ''
  lines << '## Error Handling'
  lines << ''
  lines << markdown_text(error_schema['description'])
  lines << ''
  lines << '```json'
  lines.concat(JSON.pretty_generate(error_example(error_schema)).lines.map(&:chomp))
  lines << '```'
  lines << ''
  lines << '## Conclusion'
  lines << ''
  lines << "This reference is generated from `spec.yaml` for OpenAPI #{spec.fetch('openapi')} contract review."
  lines << ''
  lines.join("\n")
end

unless ARGV.empty? || ARGV == ['--check']
  warn 'usage: scripts/generate-spec-md.rb [--check]'
  exit 64
end

spec_source = File.read(SPEC_PATH)
begin
  spec = YAML.safe_load(spec_source, aliases: true)
rescue SystemStackError
  warn 'spec.yaml exceeds the YAML generator parser nesting limit'
  exit 1
end
unless spec.is_a?(Hash)
  warn 'spec.yaml root must be a mapping for Markdown generation'
  exit 1
end
if (shape_error = openapi_container_shape_error(spec))
  warn shape_error
  exit 1
end

generated = generate_reference(spec)
if ARGV == ['--check']
  unless File.file?(REFERENCE_PATH) && File.read(REFERENCE_PATH) == generated
    warn 'spec.md is out of date; run scripts/generate-spec-md.rb'
    exit 1
  end
else
  File.write(REFERENCE_PATH, generated)
  puts 'Generated spec.md from spec.yaml.'
end
