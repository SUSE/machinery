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
  def initialize(hash, path = nil)
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
      next if !scope_extracted?(scope)

      expected_files = expected_files(scope)
      file_errors = FileValidator.validate(ScopeFileStore.new(@path, scope.to_s), expected_files)

      errors << "Scope '#{scope}':\n" + file_errors.join("\n") if !file_errors.empty?
    end

    errors
  end

  private

  def scope_extracted?(scope)
    if @format_version == 1
      @hash[scope] && ScopeFileStore.new(@path, scope.to_s).path
    else
      @hash[scope] && @hash[scope]["extracted"]
    end
  end

  def expected_files(scope)
    if @format_version == 1
      files = @hash[scope]
    else
      files = @hash[scope]["files"]
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
      expected_files = files.
        reject { |file| file["changes"].include?("deleted") }.
        map { |file| file["name"] }
    end

    store_base_path = ScopeFileStore.new(@path, scope.to_s).path
    expected_files.map { |file| File.join(store_base_path, file) }
  end
end
