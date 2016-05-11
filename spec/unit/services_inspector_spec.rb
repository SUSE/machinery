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

require_relative "spec_helper"

describe ServicesInspector do
  let(:system) { double }
  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new).tap do |description|
      description.environment = EnvironmentScope.new(system_type: "remote")
    end
  }
  let(:filter) { nil }
  subject(:inspector) { ServicesInspector.new(system, description) }

  let(:chkconfig_redhat_output) {
    <<-EOF
crond 0:off 1:off 2:on 3:on 4:on 5:on 6:off
dnsmasq 0:off 1:off 2:off 3:off 4:off 5:off 6:off

xinetd based services:
        chargen-dgram:  off
        chargen-stream: on
        eklogin:        off
EOF
  }

  describe "#inspect" do
    let(:systemctl_list_unit_files_output) {
      <<-EOF
UNIT FILE         STATE
alsasound.service static
autofs.service    disabled
getty@.service    enabled
syslog.socket     enabled

4 unit files listed.
EOF
    }
    let(:systemctl_list_units_output) {
      <<-EOF
UNIT               LOAD   ACTIVE     SUB        JOB   DESCRIPTION
getty@tty1.service loaded active     running          Getty on tty1
user@0.service     loaded active     running          User Manager for UID 0

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.
JOB    = Pending job for the unit.

2 loaded units listed.
To show all installed unit files use 'systemctl list-unit-files'.
EOF
    }

    it "returns data about systemd services when systemd is present" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(true)
      expect(system).to receive(:run_command).
        with(
          "systemctl",
          "is-enabled",
          "getty@tty1.service",
          stdout: :capture
        ).
        and_return("enabled")
      expect(system).to receive(:run_command).
        with(
          "systemctl",
          "list-units",
          "--all",
          "*@*.service",
          stdout: :capture
        ).
        and_return(systemctl_list_units_output)
      expect(system).to receive(:run_command).
        with(
          "systemctl",
          "list-unit-files",
          "--type=service,socket",
          stdout: :capture
        ).
        and_return(systemctl_list_unit_files_output)

      inspector.inspect(filter)

      expect(description.services).to eq(
        ServicesScope.new(
          [
            Service.new(name: "alsasound.service",  state: "static"),
            Service.new(name: "autofs.service",     state: "disabled"),
            Service.new(name: "getty@tty1.service", state: "enabled"),
            Service.new(name: "syslog.socket",      state: "enabled")
          ],
          init_system: "systemd"
        )
      )
      expect(inspector.summary).to eq("Found 4 services.")
    end

    it "returns data about SysVinit services on a suse system when no systemd is present" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("initctl").and_return(false)
      allow(system).to receive(:run_command).
        with("/sbin/chkconfig", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect(inspector).to receive(:parse_suse_chkconfig).
        and_return([
          Service.new(name: "alsasound",   state: "on"),
          Service.new(name: "autofs",      state: "off"),
          Service.new(name: "boot.isapnp", state: "on")])

      inspector.inspect(filter)

      expect(description.services).to eq(
        ServicesScope.new(
          [
            Service.new(name: "alsasound",   state: "on"),
            Service.new(name: "autofs",      state: "off"),
            Service.new(name: "boot.isapnp", state: "on"),
          ],
          init_system: "sysvinit"
        )
      )
      expect(inspector.summary).to eq("Found 3 services.")
    end

    it "returns data about upstart services on a ubuntu system" do
      initctl_ubuntu_output =
        <<-EOF
ufw
  start on starting (job: networking, env:)
  stop on runlevel (job:, env: [!023456])
tty4
  start on runlevel (job:, env: [23])
  start on container (job:, env: CONTAINER=lxc-libvirt)
  stop on runlevel (job:, env: [!23])
hostname
  start on startup (job:, env:)
EOF

      service_ubuntu_output =
        <<-EOF
 [ + ]  apparmor
 [ + ]  ntp
 [ - ]  ssh
 [ - ]  rsync
EOF

      service_ubuntu_error =
        <<-EOF
 [ ? ]  console-setup
EOF

      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("initctl").and_return(true)
      allow(system).to receive(:has_command?).
        with("chkconfig").and_return(false)
      expect(system).to receive(:run_command).
        with(
          "/usr/sbin/service",
          "--status-all",
          stdout: :capture, stderr: :capture
        ).
        and_return([service_ubuntu_output, service_ubuntu_error])

      [2, "S"].map do |runlevel|
        expect(system).to receive(:run_command).
          with(
            "/usr/bin/find",
            "/etc/rc#{runlevel}.d",
            "-name",
            "S*",
            stdout: :capture
          ).
          and_return(
            "/etc/rc#{runlevel}.d/S23ntp\n/etc/rc#{runlevel}.d/S20rsync\n"
          )
      end

      expect(system).to receive(:run_command).
        with(
          "/sbin/initctl",
          "show-config",
          "-e",
          stdout: :capture
        ).
        and_return(initctl_ubuntu_output)
      inspector.inspect(filter)

      expect(description.services).to eq(
        ServicesScope.new(
          [
            Service.new(name: "apparmor",       state: "disabled",      legacy_sysv: true),
            Service.new(name: "console-setup",  state: "disabled",      legacy_sysv: true),
            Service.new(name: "hostname",       state: "enabled",      legacy_sysv: false),
            Service.new(name: "ntp",            state: "enabled",      legacy_sysv: true),
            Service.new(name: "rsync",          state: "enabled",      legacy_sysv: true),
            Service.new(name: "ssh",            state: "disabled",      legacy_sysv: true),
            Service.new(name: "tty4",           state: "enabled",      legacy_sysv: false),
            Service.new(name: "ufw",            state: "disabled",      legacy_sysv: false)
          ], init_system: "upstart"
        )
      )
      expect(inspector.summary).to eq("Found 8 services.")
    end

    it "raises an exception when requirements are not fulfilled" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("initctl").and_return(false)
      allow(system).to receive(:run_command).
        with("/sbin/chkconfig", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      expect(system).to receive(:check_requirement).
        with(["chkconfig", "/sbin/chkconfig"], "--help").
        and_raise(Machinery::Errors::MissingRequirement)

      expect {
        inspector.inspect(filter)
      }.to raise_error(Machinery::Errors::MissingRequirement)
    end

    it "returns data about Upstart services on a rhel6 system" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("initctl").and_return(true)
      allow(system).to receive(:has_command?).
        with("chkconfig").and_return(true)
      allow(system).to receive(:run_command).
        with("/sbin/chkconfig", "--version")
      allow(system).to receive(:check_requirement).with("/sbin/runlevel").and_return(true)
      allow(system).to receive(:run_command).
        with("/sbin/runlevel", stdout: :capture).and_return("N 3")
      allow(system).to receive(:run_command).
        with("/sbin/chkconfig", "--list", stdout: :capture).and_return(chkconfig_redhat_output)

      inspector.inspect(filter)

      expect(description.services).to match_array(
        ServicesScope.new(
          [
            Service.new(name: "crond", state: "on", legacy_sysv: true),
            Service.new(name: "dnsmasq", state: "off", legacy_sysv: true),
            Service.new(name: "chargen-dgram", state: "off", legacy_sysv: true),
            Service.new(name: "chargen-stream", state: "on", legacy_sysv: true),
            Service.new(name: "eklogin", state: "off", legacy_sysv: true)
          ],
          init_system: "upstart"
        )
      )
      expect(inspector.summary).to eq("Found 5 services.")
    end

    it "returns data about SysVinit services on a redhat system" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("initctl").and_return(false)
      allow(system).to receive(:run_command).
        with("/sbin/chkconfig", "--version")
      allow(system).to receive(:check_requirement).with("/sbin/runlevel").and_return(true)
      allow(system).to receive(:run_command).
        with("/sbin/runlevel", stdout: :capture).and_return("N 3")
      allow(system).to receive(:run_command).
        with("/sbin/chkconfig", "--list", stdout: :capture).and_return(chkconfig_redhat_output)

      inspector.inspect(filter)

      expect(description.services).to match_array(
        ServicesScope.new(
          [
            Service.new(name: "crond", state: "on"),
            Service.new(name: "dnsmasq", state: "off"),
            Service.new(name: "chargen-dgram", state: "off"),
            Service.new(name: "chargen-stream", state: "on"),
            Service.new(name: "eklogin", state: "off")
          ],
          init_system: "sysvinit"
        )
      )
      expect(inspector.summary).to eq("Found 5 services.")
    end
  end

  describe "parse_suse_chkconfig" do
    before(:each) do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("chkconfig", "--version").and_return(false)
    end

    it "returns data about SysVinit services on a suse system" do
      chkconfig_suse_output =
        <<-EOF
boot.isapnp               on
alsasound                 on
autofs                    off
EOF
      expect(system).to receive(:check_requirement).
        with(["chkconfig", "/sbin/chkconfig"], "--help").and_return("chkconfig")
      expect(system).to receive(:run_command).
        with("chkconfig", "--allservices", stdout: :capture).and_return(
          chkconfig_suse_output
        )

      services = inspector.send(:parse_suse_chkconfig)
      expect(services).to match_array([
        Service.new(name: "alsasound",   state: "on"),
        Service.new(name: "boot.isapnp", state: "on"),
        Service.new(name: "autofs",      state: "off")
      ])
    end

    it "returns data about SysVinit services on sles11sp3 system with a remote user" do
      chkconfig_suse_output =
        <<-EOF
boot.isapnp               on
alsasound                 on
autofs                    off
EOF
      expect(system).to receive(:check_requirement).
        with(["chkconfig", "/sbin/chkconfig"], "--help").and_return("/sbin/chkconfig")
      expect(system).to receive(:run_command).
        with("/sbin/chkconfig", "--allservices", stdout: :capture).and_return(
          chkconfig_suse_output
        )

      services = inspector.send(:parse_suse_chkconfig)
      expect(services).to match_array([
        Service.new(name: "alsasound",   state: "on"),
        Service.new(name: "boot.isapnp", state: "on"),
        Service.new(name: "autofs",      state: "off")
      ])
    end
  end

  describe "parse_redhat_chkconfig" do
    it "returns data about SysVinit services on a redhat system" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("/sbin/chkconfig", "--version").and_return(true)

      expect(system).to receive(:check_requirement).
        with("/sbin/runlevel")
      expect(system).to receive(:run_command).
        with("/sbin/runlevel", stdout: :capture).
        and_return("N 5")
      expect(system).to receive(:run_command).
        with("/sbin/chkconfig", "--list", stdout: :capture).
      and_return(chkconfig_redhat_output)
      services = inspector.send(:parse_redhat_chkconfig)

      expect(services).to eq([
        Service.new(name: "crond", state: "on"),
        Service.new(name: "dnsmasq", state: "off"),
        Service.new(name: "chargen-dgram", state: "off"),
        Service.new(name: "chargen-stream", state: "on"),
        Service.new(name: "eklogin", state: "off")
      ])
    end
  end
end
