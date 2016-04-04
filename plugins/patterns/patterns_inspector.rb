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

class PatternsInspector < Inspector
  has_priority 30
  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter, _options = {})
    if @system.has_command?("zypper")
      @patterns_supported = true
      inspect_with_zypper
    elsif @system.has_command?("dpkg")
      if @system.has_command?("tasksel")
        Machinery::Ui.puts "Note: Tasks on Debian-like systems are treated as patterns."
        @patterns_supported = true
        inspect_with_tasksel
      else
        @patterns_supported = false
        @status = "For a patterns (tasks) inspection please install the package tasksel " \
          "on the inspected system."
        @description.patterns = PatternsScope.new
      end
    else
      @patterns_supported = false
      @status = "Patterns or tasks are not supported on this system."
      @description.patterns = PatternsScope.new
    end
  end

  def summary
    if @patterns_supported
      "Found #{Machinery.pluralize(@description.patterns.count, "%d pattern")}."
    else
      @status
    end
  end

  private

  def inspect_with_zypper
    begin
      xml = @system.run_command("zypper", "--non-interactive", "-xq", "--no-refresh", "patterns",
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
    pattern_list = REXML::Document.new(xml).get_elements("/stream/pattern-list/pattern")

    if pattern_list.count == 0
      @description.patterns = PatternsScope.new
      return
    end

    patterns = pattern_list.map do |pattern|
      Pattern.new(
        name: pattern.attributes["name"],
        version: pattern.attributes["version"],
        release: pattern.attributes["release"]
      )
    end.uniq.sort_by(&:name)

    @description.patterns = PatternsScope.new(patterns)
  end

  def inspect_with_tasksel
    tasksel_out = @system.run_command("tasksel", "--list-tasks", stdout: :capture)
    tasklist = tasksel_out.lines.map(&:chomp)
    installed = tasklist.select { |line| line.start_with?("i") }
    installed.map! { |l| l.split[1] }
    patterns = installed.map do |pattern|
      Pattern.new(
        name: pattern
      )
    end.uniq.sort_by(&:name)

    @description.patterns = PatternsScope.new(patterns)
  end
end
