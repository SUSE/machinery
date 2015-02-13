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

    @format_version = @hash["meta"]["format_version"] if @hash["meta"]
  end

  def validate_json
    validator = JsonValidator.new(@format_version)
    errors = validator.validate(@hash)

    scopes = @hash.keys
    scopes.delete("meta")

    errors += scopes.flat_map do |scope|
      validator.validate_scope(@hash[scope], scope)
    end

    errors
  end

  def validate_file_data
    errors = []

    ["config_files", "changed_managed_files", "unmanaged_files"].each do |scope|
      if @format_version == 1
        next if !@hash[scope] || !ScopeFileStore.new(@path, scope.to_s).path

        expected_files = expected_files_v1(scope)
      else
        next if !@hash[scope] || !@hash[scope]["extracted"]

        expected_files = expected_files(scope)
      end

      file_errors = FileValidator.validate(ScopeFileStore.new(@path, scope.to_s), expected_files)

      errors << "Scope '#{scope}':\n" + file_errors.join("\n") if !file_errors.empty?
    end

    errors
  end

  def expected_files_v1(scope)
    if scope == "unmanaged_files"
      has_files_tarball = @hash[scope].any? { |f| f["type"] == "file" || f["type"] == "link" }
      tree_tarballs = @hash[scope].
        select { |f| f["type"] == "dir" }.
        map { |d| File.join("trees", d["name"].sub(/\/$/, "") + ".tgz") }

      expected_files = []
      expected_files << "files.tgz" if has_files_tarball
      expected_files += tree_tarballs
    else
      expected_files = @hash[scope]
        .reject { |file| file["changes"].include?("deleted") }
        .map {|file| file["name"] }
    end

    store_base_path = ScopeFileStore.new(@path, scope.to_s).path
    expected_files.map { |file| File.join(store_base_path, file) }
  end

  def expected_files(scope)
    if scope == "unmanaged_files"
      has_files_tarball = @hash[scope]["files"].any? { |f| f["type"] == "file" || f["type"] == "link" }
      tree_tarballs = @hash[scope]["files"].
        select { |f| f["type"] == "dir" }.
        map { |d| File.join("trees", d["name"].sub(/\/$/, "") + ".tgz") }

      expected_files = []
      expected_files << "files.tgz" if has_files_tarball
      expected_files += tree_tarballs
    else
      expected_files = @hash[scope]["files"]
        .reject { |file| file["changes"].include?("deleted") }
        .map {|file| file["name"] }
    end

    store_base_path = ScopeFileStore.new(@path, scope.to_s).path
    expected_files.map { |file| File.join(store_base_path, file) }
  end
end
