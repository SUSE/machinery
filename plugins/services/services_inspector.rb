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

class ServicesInspector < Inspector
  has_priority 70

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter, _options = {})
    services, init_system =
      case
      when @description.environment.system_type == "docker"
        then [[], "none"]
      when @system.has_command?("systemctl")
        then [inspect_systemd_services, "systemd"]
      when @system.has_command?("initctl") && @system.has_command?("chkconfig")
        then [parse_redhat_chkconfig.map { |s| s["legacy_sysv"] = true; s }, "upstart"]
      when @system.has_command?("initctl") && !@system.has_command?("chkconfig")
        then [inspect_ubuntu_services, "upstart"]
      else
        [inspect_sysvinit_services, "sysvinit"]
      end

    @description.services = ServicesScope.new(
      services,
      init_system: init_system
    )
  end

  def summary
    "Found #{Machinery.pluralize(@description.services.length, "%d service")}."
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

    services.sort_by(&:name)
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

    services.sort_by(&:name)
  end

  def inspect_ubuntu_services
    # Ubuntu is managing its services using upstart but also has some
    # services still not handled by that. Therefor we need to scan upstart
    # and sysV to determine all services and their bootup state
    services = parse_ubuntu_upstart
    parse_ubuntu_sysv.each do |service|
      services << service unless services.find { |s| s.name == service.name }
    end

    services.sort_by(&:name)
  end

  def parse_ubuntu_upstart
    initctl_output = @system.run_command("/sbin/initctl", "show-config", "-e", stdout: :capture)

    servicelist = initctl_output.lines.map(&:chomp).slice_before { |l| !l.start_with?(" ") }
    enabled, disabled = servicelist.partition do |s|
      s.find { |e| e.start_with?("  start on runlevel", "  start on startup") }
    end

    services = enabled.map(&:first).each.map do |name|
      Service.new(name: name, state: "enabled", legacy_sysv: false)
    end
    services + disabled.map(&:first).each.map do |name|
      Service.new(name: name, state: "disabled", legacy_sysv: false)
    end
  end

  def parse_ubuntu_sysv
    # Get all sysV services
    out, err = @system.run_command(
      "/usr/sbin/service",
      "--status-all",
      stdout: :capture, stderr: :capture)
    services_output = out + err

    sysv_all = services_output.each_line.map { |line|
      line.chomp.sub(/^.*\]../, "")
    }

    # Get all enabled sysV services - default in ubuntu1404 is runlevel 2
    # and runlevels 3,4 and 5 are considered to be identical to 2.
    runlevels = ["2", "S"]
    find_output = runlevels.each.map do |runlevel|
      @system.run_command(
        "/usr/bin/find",
        "/etc/rc#{runlevel}.d",
        "-name",
        "S\*",
        stdout: :capture).split
    end

    sysv_enabled = find_output.flatten.map { |line|
      line.chomp.sub(/^\/etc\/rc.\.d\/.../, "")
    }.uniq
    sysv_disabled = sysv_all - sysv_enabled

    services = sysv_enabled.map.each do |name|
      Service.new(name: name, state: "enabled", legacy_sysv: true)
    end

    services + sysv_disabled.map.each do |name|
      Service.new(name: name, state: "disabled", legacy_sysv: true)
    end
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

    output.lines.map do |line|
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
