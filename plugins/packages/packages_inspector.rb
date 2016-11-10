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

class PackagesInspector < Inspector
  has_priority 20
  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter, _options = {})
    @system.check_requirement(["rpm", "dpkg"], "--version")

    if @system.has_command?("rpm")
      inspect_rpm
    elsif @system.has_command?("dpkg")
      @system.check_requirement("apt-cache", "--version")
      inspect_dpkg
    end

    @description
  end

  def summary
    "Found #{Machinery.pluralize(@description.packages.length, "%d package")}."
  end

  private

  def inspect_rpm
    packages = Machinery::Array.new
    rpm_data = @system.run_command(
      "rpm","-qa","--qf",
      "%{NAME}|%{VERSION}|%{RELEASE}|%{ARCH}|%{VENDOR}|%{SIGMD5}$",
      :stdout=>:capture
    )
    # gpg-pubkeys are no real packages but listed by rpm in the regular
    # package list
    rpm_data.scan(/(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\$/).reject do |name, *attrs|
      name =~ /^gpg-pubkey$/
    end.each do |name, version, release, arch, vendor, checksum|
      packages << RpmPackage.new(
        :name     => name,
        :version  => version,
        :release  => release,
        :arch     => arch,
        :vendor   => vendor,
        :checksum => checksum
      )
    end

    @description.packages = PackagesScope.new(
      packages.sort_by(&:name),
      package_system: "rpm"
    )
  end

  def inspect_dpkg
    dpkg_data = @system.run_command(
      "dpkg", "-l", stdout: :capture
    )

    lines = dpkg_data.lines.reject { |line| !line.start_with?("ii ") }

    packages = lines.map do |line|
      name, version, arch = line.split[1..3]
      version_segments = version.split("-")
      release = version_segments.pop if version_segments.length > 1
      version = version_segments.join("-")

      DpkgPackage.new(
        name: name,
        version: version,
        release: release,
        arch: arch
      )
    end
    packages.each_slice(100) do |packages_slice|
      begin
        apt_cache_output = @system.run_command(
          "apt-cache",
          "show",
          *packages_slice.map { |p| "#{p.name}=#{[p.version, p.release].compact.join("-")}" },
          stdout: :capture
        )
      rescue
        # Older Debian systems do not support the version parameter for `apt-cache show`
        apt_cache_output = @system.run_command(
          "apt-cache",
          "show",
          *packages_slice.map(&:name),
          stdout: :capture
        )
      end

      apt_cache_elements = Hash[
        *apt_cache_output.split("\n\n").flat_map do |element|
          name = element[/Package: (.+)$/, 1]
          [name, element]
        end
      ]

      packages_slice.each do |package|
        name = package.name.sub(/:[^:]+$/, "")
        apt_cache_element = apt_cache_elements[name]
        if apt_cache_element
          package.arch = apt_cache_element[/Architecture: (\w+)\n/, 1]
          checksum = apt_cache_element[/MD5[Ss]um: (\w+)\n/, 1]
          vendor = apt_cache_element[/Origin: (\w+)\n/, 1]
        end
        package.checksum = checksum || ""
        package.vendor = vendor || ""
        package.release ||= ""
      end
    end

    @description.packages = PackagesScope.new(
      packages.sort_by(&:name),
      package_system: "dpkg"
    )
  end
end
