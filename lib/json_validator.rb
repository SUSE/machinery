# Copyright (c) 2013-2016 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

class JsonValidator
  def initialize(json_hash)
    @json_hash = json_hash

    format_version = @json_hash["meta"]["format_version"] if @json_hash["meta"]

    if !format_version
      raise Machinery::Errors::SystemDescriptionValidationFailed.new(
        ["Could not determine format version"]
      )
    end

    @global_schema = global_schema(format_version)
    @scope_schemas = scope_schemas(format_version)
  end

  def validate
    errors = JSON::Validator.fully_validate(@global_schema, @json_hash)

    scopes = @json_hash.keys
    scopes.delete("meta")

    errors += scopes.flat_map do |scope|
      validate_scope(@json_hash[scope], scope)
    end

    errors
  end

  private

  def validate_scope(scope_hash, scope)
    return [] if !@scope_schemas[scope]

    errors = JSON::Validator.fully_validate(@scope_schemas[scope], scope_hash).map do |error|
      "In scope #{scope}: #{error}"
    end
    errors.map do |error|
      JsonValidationErrorCleaner.cleanup_error(error, scope)
    end
  end

  def global_schema(format_version = SystemDescription::CURRENT_FORMAT_VERSION)
    JSON.parse(File.read(File.join(
      Machinery::ROOT,
      "schema",
      "system-description-global.schema-v#{format_version}.json"
    )))
  end

  def scope_schemas(format_version = SystemDescription::CURRENT_FORMAT_VERSION)
    schema_path = File.join(
      Machinery::ROOT,
      "plugins",
      "**",
      "schema",
      "*.schema-v#{format_version}.json"
    )

    Hash[
      Dir[schema_path].map do |file|
        scope = file.match(/system-description-(.*)\.schema-v#{format_version}\.json$/)[1].
          tr("-", "_")
        schema = JSON.parse(File.read(file))

        [scope, schema]
      end
    ]
  end
end
