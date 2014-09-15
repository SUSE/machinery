# Copyright (c) 2013-2014 SUSE LLC
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

class SystemDescriptionValidator
  class << self
    def load_global_schema
      JSON.parse(File.read(File.join(
        Machinery::ROOT,
        "schema",
        "v#{SystemDescription::CURRENT_FORMAT_VERSION}",
        "system-description-global.schema.json"
      )))
    end

    def load_scope_schemas
      schema_dir = File.join(
        Machinery::ROOT,
        "plugins",
        "schema",
        "v#{SystemDescription::CURRENT_FORMAT_VERSION}",
      )

      Hash[
        Dir["#{schema_dir}/*.schema.json"].map do |file|
          scope = file.match(/system-description-(.*)\.schema\.json$/)[1].tr("-", "_")
          schema = JSON.parse(File.read(file))

          [scope, schema]
        end
      ]
    end
  end

  GLOBAL_SCHEMA = load_global_schema
  SCOPE_SCHEMAS = load_scope_schemas

  def initialize(description)
    @description = description
  end

  def validate_json(json)
    errors = JSON::Validator.fully_validate(GLOBAL_SCHEMA, json)

    scopes = json.keys
    scopes.delete("meta")

    errors += scopes.flat_map do |scope|
      schema = SCOPE_SCHEMAS[scope]

      if schema
        issue = JSON::Validator.fully_validate(schema, json[scope]).map do |error|
          "In scope #{scope}: #{error}"
        end
        issue.map do |error|
          cleanup_json_error_message(error, scope)
        end
      else
        []
      end
    end

    if !errors.empty?
      raise Machinery::Errors::SystemDescriptionError.new(errors.join("\n"))
    end
  end

  def missing_files_for_plain_scope(scope)
    expected_files = @description[scope].files.reject { |file| file.changes.include?("deleted") }
    missing_files = @description.missing_files(scope, expected_files.map(&:name))
  end

  def expected_files_for_tared_scope(scope)
    has_files_tarball = @description[scope].files.any? { |f| f.type == "file" || f.type == "link" }
    tree_tarballs = @description[scope].files.
      select { |f| f.type == "dir" }.
      map { |d| File.join("trees", d.name.sub(/\/$/, "") + ".tgz") }

    expected_files = []
    expected_files << "files.tgz" if has_files_tarball
    expected_files += tree_tarballs
  end

  def missing_files_for_tared_scope(scope)
    expected_files = expected_files_for_tared_scope(scope)
    missing_files = @description.missing_files(scope, expected_files)
  end

  def missing_files_for_scope(scope)
    if scope == "unmanaged_files"
      missing_files_for_tared_scope(scope)
    else
      missing_files_for_plain_scope(scope)
    end
  end

  def additional_files_for_tared_scope(scope)
    expected_files = expected_files_for_tared_scope(scope)
    additional_files = @description.additional_files(scope, expected_files)
  end

  def additional_files_for_plain_scope(scope)
    expected_files = @description[scope].files.reject { |file| file.changes.include?("deleted") }
    additional_files = @description.additional_files(scope, expected_files.map(&:name))
  end

  def additional_files_for_scope(scope)
    if scope == "unmanaged_files"
      additional_files_for_tared_scope(scope)
    else
      additional_files_for_plain_scope(scope)
    end
  end

  def format_file_errors(scope, missing_files, additional_files)
    error_message = "Scope '#{scope}':\n"
    error_message += missing_files.map do |file|
      "  * File '" + file + "' doesn't exist"
    end.join("\n")
    error_message += additional_files.map do |file|
      "  * File '" + file + "' doesn't have meta data"
    end.join("\n")
  end

  def validate_file_data!
    errors = []

    ["config_files", "changed_managed_files", "unmanaged_files"].each do |scope|
      if @description.scope_extracted?(scope)
        missing_files = missing_files_for_scope(scope)
        additional_files = additional_files_for_scope(scope)

        if !missing_files.empty? or !additional_files.empty?
          errors.push(format_file_errors(scope, missing_files, additional_files))
        end
      end
    end

    if !errors.empty?
      e = Machinery::Errors::SystemDescriptionValidationFailed.new(errors)
      e.header = "Error validating description '#{@description.name}'"
      raise e
    end
  end

  def cleanup_json_error_message(message, scope)
    message = cleanup_json_path(message, scope)
    message = remove_json_error_uuid(message)
    message
  end

  private

  def cleanup_json_path(message, scope)
    old_path = message[/The property '#\/(.*?)'/,1]

    position = error_position_from_json_path(old_path)
    details = extract_details_from_json_path(old_path, scope)

    new_path = "The property"
    new_path += " ##{position}" if position > -1
    new_path += " (#{details})" if !details.empty?

    message.gsub(/The property '#\/.*?'/, new_path)
  end

  def error_position_from_json_path(path)
    elements = path.split("/")

    position = -1
    elements.each do |e|
      if Machinery::is_int?(e)
        number = e.to_i
        position = number if number > position
      end
    end
    position
  end

  def extract_details_from_json_path(path, scope)
    elements = path.split("/")

    elements.uniq!

    # filter numbers since the position is calculated elswhere
    elements.reject! { |e| Machinery::is_int?(e) }

    # The json schema path often contains the word "type" in many messages
    # but this information adds no value for the user since it is not related
    # to our manifest.json
    # So we filter it for all scopes except of repositories since this is the
    # only scope which does have an attribute called "type"
    if scope != "repositories"
      elements.reject! { |e| e == "type" }
    end

    elements.join("/")
  end

  def remove_json_error_uuid(message)
    message.gsub(/ in schema .*$/, ".")
  end
end
