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

class Machinery::DpkgDatabase < Machinery::ManagedFilesDatabase
  def managed_files_list(&block)
    message = "The list of changed config and managed files is not complete on dpkg systems."\
     " The reason for this is missing verification data:" \
     " https://github.com/SUSE/machinery/wiki/Ubuntu-Inspection"

    Machinery.logger.warn(message)
    Machinery::Ui.warn("Warning: #{message}")

    @system.run_command_with_progress("dpkg", "--verify", privileged: true, &block)
  end

  def package_for_file_path(file)
    output = @system.run_command(
      "dpkg", "-S", file, stdout: :capture
    )

    package_name = if output.lines == 1
      output.split(":").first
    else
      extract_package_name_from_file_diversions(output)
    end

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

  def parse_changes_line(line)
    file, changes, type = super(line)

    # dpkg doesn't report deleted files as deleted but reports md5sum changes instead
    if changes.include?("md5")
      begin
        @system.run_command("ls", file)
      rescue Cheetah::ExecutionFailed
        changes = ["deleted"]
      end
    end

    [file, changes, type]
  end

  def check_requirements
    @system.check_requirement("dpkg", "--version")
    @system.check_requirement("stat", "--version")
    @system.check_requirement("find", "--version")
  end

  private

  def extract_package_name_from_file_diversions(output)
    output.lines.last.split(":").first.split(",").first
  end
end
