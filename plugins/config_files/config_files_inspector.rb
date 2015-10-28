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

class ConfigFilesInspector < Inspector
  has_priority 80
  # checks if all required binaries are present
  def check_requirements(check_rsync)
    @system.check_requirement("rpm", "--version")
    @system.check_requirement("stat", "--version")
    @system.check_requirement("find", "--version")
    @system.check_retrieve_files_dependencies if check_rsync
  end

  # returns a hash with entries for changed config files
  def config_file_changes(pkg)
    @system.changed_files.select(&:config_file?).map do |file|
      ConfigFile.new(
        name:            file.path,
        package_name:    package_name,
        package_version: package_version,
        status:          "changed",
        changes:         file.changes
      )
    end.uniq
  end

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(filter, options = {})
    do_extract = options[:extract_changed_config_files]
    check_requirements(do_extract)

    count = 0
    files = @system.rpm_database.changed_files do |chunk|
      count += chunk.lines.count { |l| !l.chomp.end_with?(":") && l.split(" ")[1] == "c" }
      Machinery::Ui.progress(" -> Found #{count} config #{Machinery::pluralize(count, "file")}...")
    end
    result = files.select(&:config_file?).map do |file|
      ConfigFile.new(file.attributes)
    end

    if filter
      file_filter = filter.element_filter_for("/config_files/files/name")
      result.delete_if { |e| file_filter.matches?(e.name) } if file_filter
    end

    paths = result.reject { |f| f.changes == Machinery::Array.new(["deleted"]) }.map(&:name)
    path_data = @system.rpm_database.get_path_data(paths)
    key_list = [:user, :group, :mode, :type, :target]
    result.each do |pkg|
      pname = pkg.name
      if path_data.has_key?(pname)
        key_list.each { |k| pkg[k] = path_data[pname][k] if path_data[pname][k] }
      end
    end

    scope = ConfigFilesScope.new
    file_store = @description.scope_file_store("config_files")
    scope.scope_file_store = file_store

    file_store.remove
    if do_extract
      file_store.create
      extracted_paths = result.reject do |file|
        file.changes == Machinery::Array.new(["deleted"]) ||
        file.link? || file.directory?
      end.map(&:name)
      scope.retrieve_files_from_system(@system, extracted_paths)
    end

    scope.extracted = !!do_extract
    scope.files = ConfigFileList.new(result.sort_by(&:name))

    @description["config_files"] = scope
  end

  def summary
    "#{@description.config_files.extracted ? "Extracted" : "Found"} " +
      "#{@description.config_files.files.count} changed configuration files."
  end
end
