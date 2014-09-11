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

        # filter duplicates
        issue.map! do |error|
          lines = error.split("\n")
          lines.uniq.join("\n")
        end

        # make json error messages more user-friendly
        if ["config_files", "changed_managed_files"].include?(scope)
          issue.map! do |error|
            lines = error.split("\n")
            # The following error is most likely irrelevant if there are more
            # than one messages per issue.
            # The first element is always the introduction:
            # 'The schema specific errors were:'
            # so the check count needs to be increased by one
            if lines.length > 2
              lines.reject! {
                |l| l =~ /The property.*did not match one of the following values: deleted/
              }
            end
            lines.join("\n")
          end
        end

        issue
      else
        []
      end
    end

    errors.map! do |error|
      # optimize error message about unexpected values
      error.gsub!(/'#\/(\d+)\/([a-z\-]+)'/, "'\\2' of element #\\1")
      # optimize error message about missing required attributes
      error.gsub!(/The property '#\/(\d+).*?'/, "The element #\\1")
      # remove unnecessary information at the end of the error message
      error.gsub(/ in schema .*$/, ".")
    end

    if !errors.empty?
      raise Machinery::Errors::SystemDescriptionError.new(errors.join("\n"))
    end
  end

  def validate_file_data!
    missing_files_by_scope = {}

    ["config_files", "changed_managed_files"].each do |scope|
      if @description.scope_extracted?(scope)
        expected_files = @description[scope].reject { |file| file.changes.include?("deleted") }
        missing_files = @description.store.missing_files(@description, scope, expected_files.map(&:name))

        if !missing_files.empty?
          missing_files_by_scope[scope] = missing_files
        end
      end
    end

    scope = "unmanaged_files"
    if @description.scope_extracted?(scope)
      has_files_tarball = @description[scope].any? { |f| f.type == "file" || f.type == "link" }
      tree_tarballs = @description[scope].
        select { |f| f.type == "dir" }.
        map { |d| File.join("trees", d.name.sub(/\/$/, "") + ".tgz") }

      expected_files = []
      expected_files << "files.tgz" if has_files_tarball
      expected_files += tree_tarballs

      missing_files = @description.store.missing_files(@description, scope, expected_files)
      if !missing_files.empty?
        missing_files_by_scope[scope] = missing_files
      end
    end

    errors = missing_files_by_scope.map do |scope, missing_files|
      error_message = "Scope '#{scope}':\n"
      error_message += missing_files.map do |file|
        "  * File '" + file + "' doesn't exist"
      end.join("\n")
    end

    if errors.empty?
      return true
    else
      e = Machinery::Errors::SystemDescriptionValidationFailed.new(errors)
      e.header = "Error validating description '#{@description.name}'"
      raise e
    end
  end

  def self.cleanup_json_error_message(message, scope)
    message = cleanup_json_path(message, scope)
    message = remove_json_error_uuid(message)
    message
  end

  private

  def self.cleanup_json_path(message, scope)
    old_path = message[/The property '#\/(.*?)'/,1]

    position = error_position_from_json_path(old_path)
    details = extract_details_from_json_path(old_path, scope)

    new_path = "The property"
    new_path += " ##{position}" if position > -1
    new_path += " (#{details})" if !details.empty?

    message.gsub(/The property '#\/.*?'/, new_path)
  end

  def self.error_position_from_json_path(path)
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

  def self.extract_details_from_json_path(path, scope)
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

  def self.remove_json_error_uuid(message)
    message.gsub(/ in schema .*$/, ".")
  end
end
