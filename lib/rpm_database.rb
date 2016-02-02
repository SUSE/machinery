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

class RpmDatabase < ManagedFilesDatabase
  def managed_files_list(&block)
    @system.run_script_with_progress("changed_files.sh", &block)
  end

  def package_for_file_path(file)
    package = @system.run_command("rpm", "-qf", file, stdout: :capture).split.first
    package_name, package_version = package.scan(/(.*)-([^-]*)-[^-]/).first
    [package_name, package_version]
  end

  def check_requirements
    @system.check_requirement("rpm", "--version")
    @system.check_requirement("stat", "--version")
    @system.check_requirement("find", "--version")
  end
end
