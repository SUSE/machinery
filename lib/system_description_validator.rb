# Copyright (c) 2013-2015 SUSE LLC
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
  def initialize(hash, path)
    @hash = hash
    @path = path

    @format_version = @hash["meta"]["format_version"]
  end

  def validate_json
    global_schema = load_global_schema(@format_version)
    scope_schemas = load_scope_schemas(@format_version)

    errors = JsonValidator.validate(global_schema, @hash)

    scopes = @hash.keys
    scopes.delete("meta")

    errors += scopes.flat_map do |scope|
      schema = scope_schemas[scope]

      if schema
        JsonValidator.validate_scope(schema, @hash[scope], scope)
      else
        []
      end
    end

    errors
  end

  def validate_file_data
    errors = []

    if @format_version == 1
      [:config_files, :changed_managed_files, :unmanaged_files].each do |scope|
        if @hash[scope] && scope_file_store(scope).path && Dir.exists?(scope_file_store(scope).path)
          missing_files = missing_files_for_scope(scope)
          additional_files = additional_files_for_scope(scope)

          if !missing_files.empty? or !additional_files.empty?
            errors.push(format_file_errors(scope, missing_files, additional_files))
          end
        end
      end
    else
      [:config_files, :changed_managed_files, :unmanaged_files].each do |scope|
        if @hash[scope] && @hash[scope][:extracted]
          missing_files = missing_files_for_scope(scope)
          additional_files = additional_files_for_scope(scope)

          if !missing_files.empty? or !additional_files.empty?
            errors.push(format_file_errors(scope, missing_files, additional_files))
          end
        end
      end
    end

    errors
  end

  def missing_files_for_plain_scope(scope)
    expected_files = @hash[scope][:files].reject { |file| file[:changes].include?("deleted") }
    missing_files(scope, expected_files.map {|file| file[:name] })
  end

  def expected_files_for_tared_scope(scope)
    has_files_tarball = @hash[scope][:files].any? { |f| f[:type] == "file" || f[:type] == "link" }
    tree_tarballs = @hash[scope][:files].
      select { |f| f[:type] == "dir" }.
      map { |d| File.join("trees", d[:name].sub(/\/$/, "") + ".tgz") }

    expected_files = []
    expected_files << "files.tgz" if has_files_tarball
    expected_files += tree_tarballs
  end

  def missing_files_for_tared_scope(scope)
    expected_files = expected_files_for_tared_scope(scope)
    missing_files(scope, expected_files)
  end

  def missing_files_for_scope(scope)
    if scope == :unmanaged_files
      missing_files_for_tared_scope(scope)
    else
      missing_files_for_plain_scope(scope)
    end
  end

  def additional_files_for_tared_scope(scope)
    expected_files = expected_files_for_tared_scope(scope)
    additional_files(scope, expected_files)
  end

  def additional_files_for_plain_scope(scope)
    expected_files = @hash[scope][:files].reject { |file| file[:changes].include?("deleted") }
    additional_files(scope, expected_files.map {|file| file[:name] })
  end

  def additional_files_for_scope(scope)
    if scope == :unmanaged_files
      additional_files_for_tared_scope(scope)
    else
      additional_files_for_plain_scope(scope)
    end
  end

  def scope_file_store(store_name)
    ScopeFileStore.new(@path, store_name.to_s)
  end

  def missing_files(scope, file_list)
    file_list.map! { |file| File.join(scope_file_store(scope).path, file) }

    file_list.select { |file| !File.exists?(file) }
  end

  def additional_files(scope, file_list)
    file_store = scope_file_store(scope)
    file_list.map! { |file| File.join(file_store.path, file) }
    files = file_store.list_content

    files - file_list
  end

  def format_file_errors(scope, missing_files, additional_files)
    errors = missing_files.map do |file|
      "  * File '" + file + "' doesn't exist"
    end
    errors += additional_files.map do |file|
      "  * File '" + file + "' doesn't have meta data"
    end
    "Scope '#{scope}':\n" + errors.join("\n")
  end

  private

  def load_global_schema(format_version = SystemDescription::CURRENT_FORMAT_VERSION)
    JSON.parse(File.read(File.join(
      Machinery::ROOT,
      "schema",
      "v#{format_version}",
      "system-description-global.schema.json"
    )))
  end

  def load_scope_schemas(format_version = SystemDescription::CURRENT_FORMAT_VERSION)
    schema_dir = File.join(
      Machinery::ROOT,
      "plugins",
      "schema",
      "v#{format_version}",
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
