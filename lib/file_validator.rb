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

class FileValidator
  def initialize(json_hash, base_path)
    @json_hash = json_hash
    @base_path = base_path

    @format_version = @json_hash["meta"]["format_version"] if @json_hash["meta"]

    unless @format_version
      raise Machinery::Errors::SystemDescriptionValidationFailed.new(
        ["Could not determine format version"]
      )
    end
  end

  def validate
    errors = []

    # the deprecated config_files is still needed to be able to validate older descriptions
    [
      "changed_config_files", "config_files", "changed_managed_files", "unmanaged_files"
    ].each do |scope|
      next unless scope_extracted?(scope)

      expected_files = expected_files(scope)
      file_errors = validate_scope(
        Machinery::ScopeFileStore.new(@base_path, scope.to_s),
        expected_files
      )

      errors << "Scope '#{scope}':\n" + file_errors.join("\n") unless file_errors.empty?
    end

    errors
  end

  private

  def validate_scope(scope, expected_files)
    missing_files = missing_files(expected_files)
    additional_files = additional_files(expected_files, scope)

    format_file_errors(missing_files, additional_files)
  end

  def scope_extracted?(scope)
    if @format_version == 1
      @json_hash[scope] && Machinery::ScopeFileStore.new(@base_path, scope.to_s).path
    elsif @format_version < 6
      @json_hash[scope] && @json_hash[scope]["extracted"]
    else
      @json_hash[scope] && @json_hash[scope]["_attributes"]["extracted"]
    end
  end

  def expected_files(scope)
    changes_proc = -> (file) { file["changes"] }
    if @format_version == 1
      files = @json_hash[scope]
    elsif @format_version < 6
      files = @json_hash[scope]["files"]
    else
      changes_proc = -> (file) { file["changes"]}
      files = @json_hash[scope]["_elements"]
    end

    if scope == "unmanaged_files"
      has_files_tarball = files.any? { |f| f["type"] == "file" || f["type"] == "link" }
      tree_tarballs = files.
        select { |f| f["type"] == "dir" }.
        map { |d| File.join("trees", d["name"].sub(/\/$/, "") + ".tgz") }

      expected_files = []
      expected_files << "files.tgz" if has_files_tarball
      expected_files += tree_tarballs
    else
      expected_files = files.reject do |file|
        changes_proc.call(file).include?("deleted") || (file["type"] && file["type"] != "file")
      end.map { |file| file["name"] }
    end

    store_base_path = Machinery::ScopeFileStore.new(@base_path, scope.to_s).path
    expected_files.map { |file| File.join(store_base_path, file) }
  end

  def missing_files(file_list)
    file_list.select { |file| !File.exist?(file) }
  end

  def additional_files(file_list, file_store)
    file_store.list_content - file_list
  end

  def format_file_errors(missing_files, additional_files)
    errors = []
    errors += missing_files.map do |file|
      "  * File '" + file + "' doesn't exist"
    end
    errors + additional_files.map do |file|
      "  * File '" + file + "' doesn't have meta data"
    end
  end
end
