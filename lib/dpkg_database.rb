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

class DpkgDatabase < ManagedFilesDatabase
  def managed_files_list
    message = "The inspection of config-files and changed-managed files is not "\
     "accurate on Ubuntu systems: Only content changes to a subset of files can "\
     "be detected. Relevant changes might not be caught."

    Machinery.logger.warn(message)
    Machinery::Ui.warn("Warning: #{message}")

    @system.run_command("dpkg", "--verify", stdout: :capture)
  end

  def package_for_file_path(file)
    package_name = @system.run_command("dpkg", "-S", file, stdout: :capture).split(":").first
    package_details = @system.run_command("dpkg", "-s", package_name, stdout: :capture)
    package_version = package_details.match(/^Version: (.*)$/)[1]

    [package_name, package_version]
  end

  def handle_verify_fail(_path)
    # dpkg can only check for md5sum. Thus, dpkg will report for every file
    # that not all tests (e.g. owner, mode) could be performed.
    #
    # We won't show a warning for each and every file but one warning
    # per inspection.
    #
    # This method is a no-op for DpkgDatabase.
  end

  def check_requirements
    @system.check_requirement("dpkg", "--version")
    @system.check_requirement("stat", "--version")
    @system.check_requirement("find", "--version")
  end
end
