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

module Machinery
  def self.is_int?(string)
    (string =~ /^\d+$/) != nil
  end

  def self.check_package(package)
    begin
      Cheetah.run("rpm", "-q", package)
    rescue
      needed_module = LocalSystem.os_object.module_required_by_package(package)
      if needed_module
        raise(Machinery::Errors::MissingRequirement.new("You need the package '#{package}' from module '#{needed_module}'. You can install it as follows:\n" \
          "If you haven't selected the module '#{needed_module}' before, run `yast2 scc` and choose 'Select Extensions' and activate '#{needed_module}'.\nRun `zypper install #{package}` to install the package."))
      else
        raise(Machinery::Errors::MissingRequirement.new("You need the package '#{package}'. You can install it by running `zypper install #{package}`"))
      end
    end
  end

  def self.check_build_compatible_host(system_description)
    if !LocalSystem.os_object.can_build?(system_description.os_object)
      message = "Building '#{system_description.os_object.name}' images is " \
        "not supported on this distribution.\n" \
        "Check the 'BUILD SUPPORT MATRIX' section in our man page for " \
        "further information which build targets are supported."

      raise(Machinery::Errors::BuildFailed.new(message))
    end
  end
end
