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

class ChangedManagedFilesInspector < Inspector
  include ChangedRpmFilesHelper

  def inspect(system, description, options = {})
    @system = system
    store_name = "changed_managed_files"

    result = changed_files

    description.remove_file_store(store_name)
    if options[:extract_changed_managed_files]
      description.initialize_file_store(store_name)
      existing_files = changed_files.reject { |f| f.changes.nil? || f.changes.include?("deleted") }
      system.retrieve_files(existing_files.map(&:name), description.file_store(store_name))
    end

    summary = "#{options[:extract_changed_managed_files] ? "Extracted" : "Found"} #{result.count} changed files."

    description["changed_managed_files"] = ChangedManagedFilesScope.new(result.sort_by(&:name))
    summary
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
    raw_list = @system.run_script("changed_managed_files.sh", stdout: :capture)

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
            error:             $2
          )
        else
          file, changes, flag = parse_rpm_changes_line(changed_file)

          # Config files (flagged as 'c') are handled by the ConfigFilesInspector
          next if flag == "c"

          ChangedManagedFile.new(
              name:              file,
              package_name:      package_name,
              package_version:   package_version,
              changes:           changes
          )
        end
        # Since errors are also recognized for config-files we have
        # to filter them
      end.compact.select { |item| item.changes }
    end
    amend_file_attributes(changed_files)
  end

end
