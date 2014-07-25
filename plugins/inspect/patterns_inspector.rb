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

class PatternsInspector < Inspector
  def inspect(system, description, options = {})
    system.check_requirement("zypper", "--version")

    xml = system.run_command("zypper", "-xq", "patterns", "-i", :stdout => :capture)
    pattern_list = Nokogiri::XML(xml).xpath("/stream/pattern-list/pattern")

    if pattern_list.count == 0
      description.patterns = PatternsScope.new()
      return "Found 0 patterns."
    end

    # The zypper patterns output looks like this:
    #
    # <?xml version='1.0'?>
    # <stream>
    # <pattern-list>
    # <pattern name="base" version="13.1" release="13.6.1" epoch="0" arch="i586" vendor="openSUSE" summary="Base System" repo="repo-oss" installed="1" uservisible="1">
    # <description>This is the base runtime system.  It contains only a minimal multiuser booting system. For running on real hardware, you need to add additional packages and pattern to make this pattern useful on its own.</description>
    # </pattern>
    # <pattern name="base" version="13.1" release="13.6.1" epoch="0" arch="x86_64" vendor="openSUSE" summary="Base System" repo="repo-oss" installed="1" uservisible="1">
    # <description>This is the base runtime system.  It contains only a minimal multiuser booting system. For running on real hardware, you need to add additional packages and pattern to make this pattern useful on its own.</description>
    # </pattern>
    # </pattern-list>
    # </stream>
    #
    #
    # and we want to return an array of pattern objects like this:
    #
    # [
    #   {
    #     name: "base",
    #     version: "13.1-13.6.1",
    #   }
    # ]
    #
    # Patterns listed for different architectures should be combined.

    patterns = pattern_list.map do |pattern|
      Pattern.new(
        name: pattern["name"],
        version: "#{pattern["version"]}-#{pattern["release"]}"
      )
    end.uniq.sort_by(&:name)

    description.patterns = PatternsScope.new(patterns)
    "Found #{patterns.count} patterns."
  end
end
