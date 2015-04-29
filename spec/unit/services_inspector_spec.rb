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

require_relative "spec_helper"

describe ServicesInspector do
  let(:system) { double }
  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
  }
  let(:filter) { nil }
  subject(:inspector) { ServicesInspector.new(system, description) }

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

    it "returns data about systemd services when systemd is present" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(true)
      expect(system).to receive(:run_command).
        with(
          "systemctl",
          "list-unit-files",
          "--type=service,socket",
          :stdout => :capture
        ).
        and_return(systemctl_list_unit_files_output)

      inspector.inspect(filter)

      expect(description.services).to eq(ServicesScope.new(
        init_system: "systemd",
        services:    ServiceList.new([
          Service.new(name: "alsasound.service", state: "static"),
          Service.new(name: "autofs.service",    state: "disabled"),
          Service.new(name: "syslog.socket",     state: "enabled")
        ])
      ))
      expect(inspector.summary).to eq("Found 3 services.")
    end

    it "returns data about SysVinit services on a suse system when no systemd is present" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:run_command).
        with("chkconfig", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect(inspector).to receive(:parse_suse_chkconfig).
        and_return([
          Service.new(name: "alsasound",   state: "on"),
          Service.new(name: "autofs",      state: "off"),
          Service.new(name: "boot.isapnp", state: "on")])

      inspector.inspect(filter)

      expect(description.services).to eq(ServicesScope.new(
        init_system: "sysvinit",
        services:    ServiceList.new([
          Service.new(name: "alsasound",   state: "on"),
          Service.new(name: "autofs",      state: "off"),
          Service.new(name: "boot.isapnp", state: "on"),
        ])
      ))
      expect(inspector.summary).to eq("Found 3 services.")
    end

    it "raises an exception when requirements are not fulfilled" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:run_command).
        with("chkconfig", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      expect(system).to receive(:check_requirement).
        with("chkconfig", "--help").
        and_raise(Machinery::Errors::MissingRequirement)

      expect {
        inspector.inspect(filter)
      }.to raise_error(Machinery::Errors::MissingRequirement)
    end

    it "returns data about SysVinit services on a redhat system" do
      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:run_command).
        with("chkconfig", "--version")
      expect(inspector).to receive(:parse_redhat_chkconfig).
        and_return([
          Service.new(name: "crond", state: "on"),
          Service.new(name: "dnsmasq", state: "off")])

      inspector.inspect(filter)

      expect(description.services).to eq(ServicesScope.new(
        init_system: "sysvinit",
        services: ServiceList.new([
          Service.new(name: "crond", state: "on"),
          Service.new(name: "dnsmasq", state: "off"),
        ])
      ))
      expect(inspector.summary).to eq("Found 2 services.")
    end
  end

  describe "parse_suse_chkconfig" do
    it "returns data about SysVinit services on a suse system" do
      chkconfig_suse_output =
        <<-EOF
boot.isapnp               on
alsasound                 on
autofs                    off
EOF

      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("chkconfig", "--version").and_return(false)

      expect(system).to receive(:check_requirement).
        with("chkconfig", "--help")

      expect(system).to receive(:run_command).
        with("chkconfig", "--allservices", stdout: :capture).
      and_return(chkconfig_suse_output)
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
      chkconfig_redhat_output =
        <<-EOF
crond 0:off 1:off 2:on 3:on 4:on 5:on 6:off
dnsmasq 0:off 1:off 2:off 3:off 4:off 5:off 6:off

xinetd based services:
        chargen-dgram:  off
        chargen-stream: on
        eklogin:        off
EOF

      allow(system).to receive(:has_command?).
        with("systemctl").and_return(false)
      allow(system).to receive(:has_command?).
        with("chkconfig", "--version").and_return(true)

      expect(system).to receive(:check_requirement).
        with("chkconfig", "--version")
      expect(system).to receive(:check_requirement).
        with("runlevel")
      expect(system).to receive(:run_command).
        with("runlevel", stdout: :capture).
        and_return("N 5")
      expect(system).to receive(:run_command).
        with("chkconfig", "--list", stdout: :capture).
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
