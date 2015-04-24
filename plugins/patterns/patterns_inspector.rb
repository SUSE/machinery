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

class PatternsInspector < Inspector
  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter, _options = {})
    if @system.has_command?("zypper")
      @patterns_supported = true
      inspect_with_zypper
    else
      @patterns_supported = false
      @description.patterns = PatternsScope.new
      "Patterns are not supported on this system."
    end
  end

  def summary
    if @patterns_supported
      "Found #{@description.patterns.count} patterns."
    else
      "Patterns are not supported on this system."
    end
  end

  private

  def inspect_with_zypper
    begin
      xml = @system.run_command("zypper", "-xq", "--no-refresh", "patterns",
        "-i", stdout: :capture)
    rescue Cheetah::ExecutionFailed => e
      if e.stdout.include?("locked")
        Machinery.logger.error(e.stdout)
        raise Machinery::Errors::ZypperFailed.new(
          "Zypper is locked."
        )
      else
        raise
      end
    end
    pattern_list = Nokogiri::XML(xml).xpath("/stream/pattern-list/pattern")

    if pattern_list.count == 0
      @description.patterns = PatternsScope.new
      return
    end

    patterns = pattern_list.map do |pattern|
      Pattern.new(
        name: pattern["name"],
        version: pattern["version"],
        release: pattern["release"]
      )
    end.uniq.sort_by(&:name)

    @description.patterns = PatternsScope.new(patterns)
  end
end
