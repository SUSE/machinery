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
end
