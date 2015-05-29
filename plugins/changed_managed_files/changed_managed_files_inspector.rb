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

class ChangedManagedFilesInspector < Inspector
  include ChangedRpmFilesHelper
  has_priority 90

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(filter, options = {})
    system.check_requirement("rsync", "--version") if options[:extract_changed_managed_files]

    @system = system
    file_store = @description.scope_file_store("changed_managed_files")

    result = changed_files

    if filter
      file_filter = filter.element_filter_for("/changed_managed_files/files/name")
      result.delete_if { |e| file_filter.matches?(e.name) } if file_filter
    end

    file_store.remove
    if options[:extract_changed_managed_files]
      file_store.create

      existing_files = result.reject do |f|
        f.changes.nil? ||
        f.changes.include?("deleted") ||
        f.name == "/"
      end

      system.retrieve_files(existing_files.map(&:name), file_store.path)
    end

    @description["changed_managed_files"] = ChangedManagedFilesScope.new(
      extracted: !!options[:extract_changed_managed_files],
      files: ChangedManagedFileList.new(result.sort_by(&:name))
    )
  end

  def summary
    "#{@description.changed_managed_files.extracted ? "Extracted" : "Found"} " +
      "#{@description.changed_managed_files.files.count} changed files."
  end

  private

  def amend_file_attributes(changed_files)
    existing_files = changed_files.reject { |f| f.changes.nil? || f.changes.include?("deleted") }
    file_attributes = get_path_data(@system, existing_files.map(&:name))
    changed_files.map do |changed_file|
      if file_attributes[changed_file.name]
        ChangedManagedFile.new(changed_file.attributes.merge(file_attributes[changed_file.name]))
      else
        changed_file
      end
    end
  end

  def changed_files
    raw_list = @system.run_script(
      "changed_files.sh", "--", "changed-managed-files", stdout: :capture
    )

    # The raw list lists each package followed by the changed files, e.g.
    #
    #   libpulse0-4.0.git.270.g9490a:
    #   S.5......  c /etc/pulse/client.conf
    #   ntp-4.2.6p5:
    #   S.5......  c /etc/ntp.conf
    #
    # We map this to an array of files like this:
    #
    # [
    #   {
    #     name: "/etc/pulse/client.conf",
    #     package_name: "libpulse0",
    #     package_version: "4.0.git.270.g9490a"
    #   },
    #   ...
    # ]
    changed_files = raw_list.split("\n").slice_before(/(.*):\z/).flat_map do |package, *changed_files|
      package_name, package_version = package.scan(/(.*)-([^-]*):/).first
      changed_files.map do |changed_file|
        if changed_file =~ /\A(\/\S+) (.*)/
          ChangedManagedFile.new(
            name:              $1,
            package_name:      package_name,
            package_version:   package_version,
            status:            "error",
            error_message:     $2
          )
        else
          file, changes, flag = parse_rpm_changes_line(changed_file)

          # Config files (flagged as 'c') are handled by the ConfigFilesInspector
          next if flag == "c"

          ChangedManagedFile.new(
              name:              file,
              package_name:      package_name,
              package_version:   package_version,
              status:            "changed",
              changes:           changes
          )
        end
        # Since errors are also recognized for config-files we have
        # to filter them
      end.compact.select { |item| item.changes }
    end.uniq
    amend_file_attributes(changed_files)
  end

end
