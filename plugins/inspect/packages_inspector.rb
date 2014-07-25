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

class PackagesInspector < Inspector
  def inspect(system, description, options = {})
    system.check_requirement("rpm", "--version")

    packages = Array.new
    rpm_data = system.run_command(
      "rpm","-qa","--qf", "%{NAME}|%{VERSION}$",
      :stdout=>:capture
    )
    # gpg-pubkeys are no real packages but listed by rpm in the regular
    # package list
    rpm_data.scan(/(.*?)\|(.*?)\$/).reject do |name, version|
      name =~ /^gpg-pubkey$/
    end.each do |name, version|
      packages << Package.new(:name => name, :version => version)
    end

    description.packages = PackagesScope.new(packages.sort_by(&:name))
    "Found #{packages.count} packages."
  end
end
