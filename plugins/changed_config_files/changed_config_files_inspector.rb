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

class ChangedConfigFilesInspector < Inspector
  has_priority 80

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
    system.check_retrieve_files_dependencies if do_extract

    count = 0
    files = @system.managed_files_database.changed_files do |chunk|
      count += chunk.lines.count { |l| !l.chomp.end_with?(":") && l.split(" ")[1] == "c" }
      Machinery::Ui.progress(" -> Found #{Machinery.pluralize(count, "%d changed config file")}...")
    end
    result = files.select(&:config_file?).map do |file|
      ConfigFile.new(file.attributes)
    end

    if filter
      file_filter = filter.element_filter_for("/config_files/files/name")
      result.delete_if { |e| file_filter.matches?(e.name) } if file_filter
    end

    scope = ChangedConfigFilesScope.new
    file_store = @description.scope_file_store("config_files")
    scope.scope_file_store = file_store

    file_store.remove
    if do_extract
      file_store.create
      extracted_paths = result.reject do |file|
        file.changes == ["deleted"] ||
        file.link? || file.directory?
      end.map(&:name)
      scope.retrieve_files_from_system(@system, extracted_paths)
    end

    scope.extracted = !!do_extract
    scope += result.sort_by(&:name)

    @description["config_files"] = scope
  end

  def summary
    "#{@description.config_files.extracted ? "Extracted" : "Found"} " +
      Machinery.pluralize(@description.config_files.count, "%d changed config file") + "."
  end
end
