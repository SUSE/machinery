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

class ServicesInspector < Inspector
  has_priority 70

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter, _options = {})
    if @description.environment.system_type == "docker"
      result = ServicesScope.new(
        init_system: "none",
        services: []
      )
    elsif @system.has_command?("systemctl")
      result = ServicesScope.new(
        init_system: "systemd",
        services: inspect_systemd_services
      )
    elsif @system.has_command?("initctl")
      result = ServicesScope.new(
        init_system: "upstart",
        services: inspect_upstart_services
      )
    else
      result = ServicesScope.new(
        init_system: "sysvinit",
        services: inspect_sysvinit_services
      )
    end

    @description.services = result
  end

  def summary
    "Found #{@description.services.services.length} services."
  end

  private

  def inspect_systemd_services
    output = @system.run_command(
      "systemctl",
      "list-unit-files",
      "--type=service,socket",
      :stdout => :capture
    )

    # The first line contains a table header. The last two lines contain a
    # separator and a summary (e.g. "197 unit files listed"). We also filter
    # templates.
    lines = output.lines[1..-3].reject { |l| l =~ /@/ }
    services = lines.map do |line|
      name, state = line.split(/\s+/)

      Service.new(name: name, state: state)
    end

    ServiceList.new(services.sort_by(&:name))
  end

  def inspect_sysvinit_services
    # Red Hat's chkconfig behaves differently than SUSE's: It takes different
    # command line arguments and has a different output format. We determine
    # if it's Red Hat by calling 'chkconfig --version'. On SUSE it exits with
    # an error, on Red Hat it doesn't.
    #
    begin
      @system.run_command("/sbin/chkconfig", "--version")
      services = parse_redhat_chkconfig
    rescue
      services = parse_suse_chkconfig
    end

    ServiceList.new(services.sort_by(&:name))
  end

  def inspect_upstart_services
    output = @system.run_command("/sbin/initctl", "show-config", "-e", stdout: :capture)

    servicelist = output.lines.map(&:chomp).slice_before { |l| !l.start_with?(" ") }
    enabled, disabled = servicelist.partition do |s|
      s.find { |e| e.start_with?("  start on runlevel", "  start on startup") }
    end

    services = enabled.map(&:first).each.map do |name|
      Service.new(name: name, state: "enabled")
    end
    services += disabled.map(&:first).each.map do |name|
      Service.new(name: name, state: "disabled")
    end

    ServiceList.new(services.sort_by(&:name))
  end

  def parse_suse_chkconfig
    # check if chkconfig is available otherwise use /sbin/chkconfig
    # this fixes issue on sles11sp3 where chkconfig isn't in /usr/bin
    chkconfig = @system.check_requirement(["chkconfig", "/sbin/chkconfig"], "--help")
    output = @system.run_command(
      chkconfig,
      "--allservices",
      :stdout => :capture
    )

    services = output.lines.map do |line|
      name, state = line.split(/\s+/)
      Service.new(name: name, state: state)
    end
  end

  def parse_redhat_chkconfig
    @system.check_requirement("/sbin/runlevel")
    _, runlevel = @system.run_command(
      "/sbin/runlevel",
      stdout: :capture
    ).split(" ")

    output = @system.run_command(
      "/sbin/chkconfig", "--list",
      stdout: :capture
    )

    # Run chkconfig output through regular expressions to parse
    # seperatly for systemv and xinetd services.
    services = output.lines.select do |line|
      line =~ /^\S+(\s+\d:(on|off))+.*$/
    end.map do |line|
      state = []
      name, state[0], state[1], state[2], state[3], state[4], state[5], state[6] = line.split(/\s+/)
      Service.new(name: name, state: state[runlevel.to_i].split(":")[1])
    end

    services += output.lines.select { |line| line =~ /^\s+\S+:\s+(on|off).*$/ }.map do |line|
      name, state = line.split(/:/)
      Service.new(name: name.strip, state: state.strip)
    end

    services
  end
end
