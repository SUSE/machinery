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
#    /usr/share/machinery/helpers/<arch>/machinery-helper
#
# where <arch> is the hardware architecture of the target system. Valid values
# are x86_64, i586, s390x, and ppcle.

class MachineryHelper
  attr_accessor :local_helpers_path

  def initialize(s)
    @system = s
    @arch = @system.arch

    @local_helpers_path = "/usr/share/machinery/helpers"
  end

  def local_helper_path
    File.join(@local_helpers_path, @arch, "machinery-helper")
  end

  # Returns true, if there is a helper binary matching the architecture of the
  # inspected system. Return false, if not.
  def can_help?
    File.exist?(local_helper_path)
  end

  def inject_helper
    @system.inject_file(local_helper_path, ".")
  end

  def run_helper(scope)
    json = @system.run_command("./machinery-helper", stdout: :capture, stderr: STDERR)
    scope.set_attributes(JSON.parse(json))
  end

  def remove_helper
    @system.remove_file("./machinery-helper")
  end
end
