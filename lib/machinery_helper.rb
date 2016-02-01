# Copyright (c) 2015 SUSE LLC
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

# The MachineryHelper class handles the helper binaries Machinery can use to
# do inspections. It provides methods to check, if a helper is available, to
# inject it to the target machine, run it there, and clean up after it's done.
#
# The inspection checks, if a binary helper is available on the machine where
# the inspection is started. It looks at the location
#
# <machinery-installation-path>/machinery-helper/machinery-helper

class MachineryHelper
  attr_accessor :local_helpers_path

  def initialize(s)
    @system = s

    @local_helpers_path = File.join(Machinery::ROOT, "machinery-helper")
  end

  def local_helper_path
    File.join(local_helpers_path, "machinery-helper")
  end

  def remote_helper_path
    @remote_helper_path ||= @system.run_command(
      # Expand Machinery::HELPER_REMOTE_PATH on remote machine
      "bash", "-c", "echo -n #{File.join(Machinery::HELPER_REMOTE_PATH, "machinery-helper")}",
        stdout: :capture
    )
  end

  # Returns true, if there is a helper binary matching the architecture of the
  # inspected system. Return false, if not.
  def can_help?
    File.exist?(local_helper_path) && LocalSystem.matches_architecture?(@system.arch)
  end

  def inject_helper
    @system.inject_file(local_helper_path, remote_helper_path)
  end

  def run_helper(scope)
    error = TeeIO.new(STDERR)
    json = @system.run_command(
      remote_helper_path, stdout: :capture, stderr: error, privileged: true
    )
    scope.insert(0, *JSON.parse(json)["files"])
  rescue Cheetah::ExecutionFailed => e
    if error.string.include?("password is required")
      raise Machinery::Errors::InsufficientPrivileges.new(@system.remote_user, @system.host)
    else
      raise e
    end
  end

  def remove_helper
    @system.remove_file(remote_helper_path)
  end

  def has_compatible_version?
    output = @system.run_command(remote_helper_path, "--version", stdout: :capture).chomp

    version = output[/^Version: ([a-f0-9]{40})$/, 1]

    version == File.read(File.join(Machinery::ROOT, ".git_revision"))
  end

  def run_helper_subcommand(subcommand, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options[:privileged] = true
    @system.run_command(remote_helper_path, subcommand, *args, options)
  end
end
