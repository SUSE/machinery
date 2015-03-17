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

#  Inspect name, version, and other attributes of the operating system
class OsInspector < Inspector
  # determines the architecture
  def get_arch
    @system.run_command("uname", "-m", :stdout => :capture).chomp
  end

  def strip_arch_from_name(name)
    # architecture information in the name might be misleading
    # information with regards to the real architecture name.
    # in addition the architecture information is not consistently
    # added for all distributions. Thus we strip this part
    name.gsub(/\((i.86|x86_64|s390|ia64|ppc|arm).*\)/, "").strip
  end

  # checks for additional version information like Beta or RC
  def get_additional_version
    issue = @system.read_file("/etc/issue")
    special_version = issue.scan(/Beta\d+|RC\d|GMC\d*/).first if issue

    special_version ? " #{special_version.gsub(/[0-9]{1,2}/," \\0")}" : ""
  end

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter, _options = {})
    @system.check_requirement("cat", "--version") if @system.is_a?(RemoteSystem)

    os = get_os
    if os
      os.architecture = get_arch
      os.version += get_additional_version
    else
      raise Machinery::Errors::UnknownOs
    end

    @description.os = os
  end

  def summary
    "Found operating system '#{@description.os.name}' version '#{@description.os.version}'."
  end

  private

  def get_os
    # Use os-release file by default
    os = get_os_from_os_release

    # Fall back to SuSE-release file
    if !os
      os = get_os_from_suse_release
    end

    # Fall back to redhat-release file
    if !os
      os = get_os_from_redhat_release
    end

    os
  end

  # check for freedesktop standard: /etc/os-release
  def get_os_from_os_release
    os_release = @system.read_file("/etc/os-release")
    return if !os_release

    result = Hash.new
    key_value_pairs = Hash[os_release.split("\n").reject(&:empty?).map { |l| l.split("=") }]
    key_value_pairs.each_pair do |k,v|
      result[k.downcase] = v.strip.gsub(/^"|"$/,"")
    end
    if result["pretty_name"]
      result["pretty_name"] = strip_arch_from_name(result["pretty_name"])
    end
    # return pretty_name as name as it contains the actual full length
    # name instead of an abbreviation
    os = Os.for(result["pretty_name"])
    os.version = result["version"]
    os
  end

  # checks for old suse standard: /etc/SuSE-release
  def get_os_from_suse_release
    suse_release = @system.read_file("/etc/SuSE-release")
    return if !suse_release

    result = Hash.new
    # name is always the first line in /etc/SuSE-release
    result["name"] = strip_arch_from_name(suse_release.split("\n").first)

    patch = nil
    suse_release.each_line do |l|
      if l.start_with?("VERSION")
        result["version"] = l.split("=").last.strip
      end
      if l.start_with?("PATCHLEVEL")
        patch = l.split("=").last.strip
      end
    end
    if result["version"] && !patch.nil?
      result["version"] = "#{result["version"]} SP#{patch}"
    end
    os = Os.for(result["name"])
    os.version = result["version"]
    os
  end

  # checks for redhat standard: /etc/redhat-release
  def get_os_from_redhat_release
    redhat_release = @system.read_file("/etc/redhat-release")
    return if !redhat_release

    result = Hash.new
    result["name"], result["version"] = redhat_release.split("\n").first.split(" release ")

    os = Os.for(result["name"])
    os.version = result["version"]
    os
  end
end
