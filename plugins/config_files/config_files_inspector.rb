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
  include ChangedRpmFilesHelper

  has_priority 80
  # checks if all required binaries are present
  def check_requirements(check_rsync)
    @system.check_requirement("rpm", "--version")
    @system.check_requirement("stat", "--version")
    @system.check_requirement("find", "--version")
    @system.check_requirement("rsync", "--version") if check_rsync
  end

  # returns list of packages containing configfiles
  def packages_with_config_files
    # first determine packages that have config files at all
    # rpm command provides lines with package names and subsequent
    # lines with pathes of config files for that package
    # e.g.
    # apache2
    # /etc/apache2/charset.conv
    # /etc/apache2/default-server.conf
    #
    output = @system.run_command(
      "rpm", "-qa", "--configfiles", "--queryformat",
      "%{NAME}-%{VERSION}\n",
      :stdout => :capture
    )
    # use leading slash to decide between lines containing package names
    # and lines containing config files
    chunks = output.split("\n").slice_before { |l| !l.start_with?("/") }
    chunks.reject { |_pkg, *cfiles| cfiles.empty? }.map(&:first).uniq
  end

  # returns a hash with entries for changed config files
  def config_file_changes(pkg)
    begin
      out = @system.run_command(
        "rpm", "-V",
        "--nodeps", "--nodigest", "--nosignature", "--nomtime",
        pkg,
        stdout: :capture,
        privileged: true
      )
    # rpm returns 1 as exit code when modified config files are detected
    # currently cheetah cannot be told to ignore this and throws ExecutionFailed
    rescue Cheetah::ExecutionFailed => e
      out = e.stdout
    end

    parts = pkg.split("-")
    package_name    = parts[0..-2].join("-")
    package_version = parts.last

    paths_and_changes = out.lines.map { |line| parse_rpm_changes_line(line) }
    paths_and_changes.reject! do |path, changes, type|
      # only consider config files and only those with changes
      type != "c" || changes.empty?
    end

    paths_and_changes.map do |path, changes|
      ConfigFile.new(
        name:            path,
        package_name:    package_name,
        package_version: package_version,
        status:          "changed",
        changes:         changes
      )
    end.uniq
  end

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter, options = {})
    do_extract = options[:extract_changed_config_files]
    check_requirements(do_extract)

    result = packages_with_config_files.flat_map do |package|
      config_file_changes(package)
    end

    paths = result.reject { |f| f.changes == Machinery::Array.new(["deleted"]) }.map(&:name)
    path_data = get_path_data(@system, paths)
    key_list = [ :user, :group, :mode, :type, :target ]
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
      @system.retrieve_files(extracted_paths, file_store.path)
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
