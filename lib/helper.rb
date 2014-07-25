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
  def self.check_package(package)
    begin
      Cheetah.run("rpm", "-q", package)
    rescue
      raise(Machinery::MissingRequirementsError.new("You need the package '#{package}'. You can install it by running `zypper install #{package}`"))
    end
  end

  def self.check_build_compatible_host(system_description)
    if !system_description.buildhost.can_build?
      message = "Building image for " +
        "'#{system_description.os.name}' is not supported." +
        " Supported image build target(s) on buildhost " +
        "'#{system_description.buildhost.os_name}' are: " +
        "'#{system_description.buildhost.can_build}'"
      raise(Machinery::UnsupportedHostForImageError.new(message))
    end
  end
end
