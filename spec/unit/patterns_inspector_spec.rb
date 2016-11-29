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

describe Machinery::PatternsInspector do
  let(:description) {
    Machinery::SystemDescription.new("systemname", Machinery::SystemDescriptionStore.new)
  }
  let(:filter) { nil }

  let(:zypper_output) {
    <<-EOF
      <?xml version='1.0'?>
      <stream>
      <pattern-list>
      <pattern name="enhanced_base" version="13.1" release="13.6.1" epoch="0" arch="i586" vendor="openSUSE" summary="Enhanced Base System" repo="repo-oss" installed="1" uservisible="1">
      <description>This is the enhanced base runtime system with lots of convenience packages.</description>
      </pattern>
      <pattern name="enhanced_base" version="13.1" release="13.6.1" epoch="0" arch="x86_64" vendor="openSUSE" summary="Enhanced Base System" repo="repo-oss" installed="1" uservisible="1">
      <description>This is the enhanced base runtime system with lots of convenience packages.</description>
      </pattern>
      <pattern name="base" version="13.1" release="13.6.1" epoch="0" arch="i586" vendor="openSUSE" summary="Base System" repo="repo-oss" installed="1" uservisible="1">
      <description>This is the base runtime system.  It contains only a minimal multiuser booting system. For running on real hardware, you need to add additional packages and pattern to make this pattern useful on its own.</description>
      </pattern>
      <pattern name="base" version="13.1" release="13.6.1" epoch="0" arch="x86_64" vendor="openSUSE" summary="Base System" repo="repo-oss" installed="1" uservisible="1">
      <description>This is the base runtime system.  It contains only a minimal multiuser booting system. For running on real hardware, you need to add additional packages and pattern to make this pattern useful on its own.</description>
      </pattern>
      </pattern-list>
      </stream>
    EOF
  }

  let(:tasksel_output) {
    <<-EOF
u server        Basic Ubuntu server
i openssh-server        OpenSSH server
i dns-server    DNS server
u lamp-server   LAMP server
i mail-server   Mail server
u postgresql-server     PostgreSQL database
i print-server  Print server
i samba-server  Samba file server
u tomcat-server Tomcat Java server
u cloud-image   Ubuntu Cloud Image (instance)
u virt-host     Virtual Machine host
EOF
  }

  let(:patterns_inspector) { Machinery::PatternsInspector.new(system, description) }
  let(:system) {
    double(
      requires_root?: false,
      host: "example.com",
      check_requirement: nil
    )
  }

  describe "#inspect" do
    context "on a zypper based OS" do
      before(:each) do
        allow(system).to receive(:has_command?).with("zypper").and_return(true)
        allow(system).to receive(:has_command?).with("dpkg").and_return(false)
      end

      it "parses the patterns list into a Hash" do
        expect(system).to receive(:run_command).
          with("zypper", "--non-interactive", "-xq", "--no-refresh", "patterns", "-i",
            stdout: :capture).and_return(zypper_output)
        patterns_inspector.inspect(filter)

        expect(description.patterns.size).to eql(2)
        expect(description.patterns.first).to eq(
          Machinery::Pattern.new(
            name: "base",
            version: "13.1",
            release: "13.6.1"
          )
        )

        expect(patterns_inspector.summary).to include("Found 2 patterns")
      end

      it "returns an empty array when there are no patterns installed" do
        expect(system).to receive(:run_command).and_return("")

        patterns_inspector.inspect(filter)
        expect(description.patterns).to eql(Machinery::PatternsScope.new)
      end

      it "returns sorted data" do
        expect(system).to receive(:run_command).and_return(zypper_output)

        patterns_inspector.inspect(filter)
        names = description.patterns.map(&:name)
        expect(names).to eq(names.sort)
      end

      it "raises an error if zypper is locked" do
        expect(system).to receive(:run_command).
          with("zypper", "--non-interactive", "-xq", "--no-refresh", "patterns", "-i",
            stdout: :capture).
          and_raise(
            Cheetah::ExecutionFailed.new(
              nil,
              OpenStruct.new(exitstatus: 7),
              "System management is locked by the application with pid 5480 (zypper).",
              nil
            )
          )
        expect { patterns_inspector.inspect(filter) }.to raise_error(
          Machinery::Errors::ZypperFailed, /Zypper is locked./)
      end

      it "parses the the pattern besides repo issues" do
        stdout = <<-EOF
<?xml version='1.0'?>
<stream>
<prompt id="14">
<text>
New repository or package signing key received:

  Repository:       SLE-12-SLP
  Key Name:         SuSE Package Signing Key &lt;build&gt;
  Key Fingerprint:  E1243BD2 39D846DB BA9EDDC1 70AF9E81 22C66E76
  Key Created:      Dunn 31. Jan 2013 16:06:03 UTC
  Key Expires:      Maan 30. Jan 2017 16:06:03 UTC (expires in 62 days)
  Rpm Name:         gpg-pubkey-d8e8fca2-c0f896fd


Do you want to reject the key, trust temporarily, or trust always?</text>
<option default="1" value="r" desc="Don&apos;t trust the key."/>
<option value="t" desc="Trust the key temporarily."/>
<option value="a" desc="Trust the key and import it into trusted keyring."/>
</prompt>
<message type="error">Error building the cache:
[SLE-12-SLP|http://dist.suse.de/install/SLP/SLE-12-SP2-Server-GM/x86_64/DVD1/] Valid metadata not found at specified URL
</message>
<message type="warning">Skipping repository &apos;SLE-12-SLP&apos; because of the above error.</message>
<message type="error">Some of the repositories have not been refreshed because of an error.</message>
<pattern-list>
<pattern name="Minimal" version="12" release="72.1" epoch="0" arch="x86_64" vendor="SUSE LLC &lt;https://www.suse.com/&gt;" summary="Minimal System (Appliances)" repo="@System" installed="true" uservisible="true"><description>This is the minimal SUSE Linux Enterprise runtime system. It is really a minimal system, you can login and a shell will be started, that&apos;s all. It is intended as base for Appliances. Support for this minimal pattern is only possible as part of an OEM agreement or after upgrading the system to the Server Base pattern</description></pattern>
</pattern-list>
</stream>
EOF
        expect(system).to receive(:run_command).
          with("zypper", "--non-interactive", "-xq", "--no-refresh", "patterns", "-i",
            stdout: :capture).
          and_raise(
            Cheetah::ExecutionFailed.new(
              nil,
              OpenStruct.new(exitstatus: 106),
              stdout,
              nil
            )
          )
        patterns_inspector.inspect(filter)
        expect(description.patterns.first).to eq(
          Machinery::Pattern.new(
            name: "Minimal",
            version: "12",
            release: "72.1"
          )
        )
      end

      it "returns patterns_system zypper" do
        expect(system).to receive(:run_command).and_return(zypper_output)
        patterns_inspector.inspect(filter)
        patterns_system = description.patterns.attributes["patterns_system"]
        expect(patterns_system).to eq("zypper")
      end
    end

    context "on a tasksel based OS" do
      before(:each) do
        allow(system).to receive(:has_command?).with("zypper").and_return(false)
        allow(system).to receive(:has_command?).with("dpkg").and_return(true)
        allow(system).to receive(:has_command?).with("tasksel").and_return(true)
      end

      it "parses the patterns list into a Hash" do
        expect(system).to receive(:run_command).
          with("tasksel", "--list-tasks", stdout: :capture).
          and_return(tasksel_output)
        patterns_inspector.inspect(filter)

        expect(description.patterns.size).to eql(5)
        expect(description.patterns.first).to eql(
          Machinery::Pattern.new(
            name: "dns-server"
          )
        )

        expect(patterns_inspector.summary).to include("Found 5 patterns")
      end

      it "returns patterns_system tasksel" do
        expect(system).to receive(:run_command).and_return(tasksel_output)
        patterns_inspector.inspect(filter)
        expect(description.patterns.attributes["patterns_system"]).to eq("tasksel")
      end
    end

    it "returns an empty array when no tasksel is installed on a deb based system
        and shows an informational message" do
      allow(system).to receive(:has_command?).with("zypper").and_return(false)
      allow(system).to receive(:has_command?).with("dpkg").and_return(true)
      allow(system).to receive(:has_command?).with("tasksel").and_return(false)

      patterns_inspector.inspect(filter)
      expect(patterns_inspector.summary).to eq(
        "For a patterns (tasks) inspection please install the package tasksel " \
        "on the inspected system."
      )
      expect(description.patterns).to eql(Machinery::PatternsScope.new)
    end

    it "returns an empty array when no zypper or dpkg are installed and shows
        an unsupported message" do
      allow(system).to receive(:has_command?).with("zypper").and_return(false)
      allow(system).to receive(:has_command?).with("dpkg").and_return(false)

      patterns_inspector.inspect(filter)
      expect(patterns_inspector.summary).to eq(
        "Patterns or tasks are not supported on this system."
      )
      expect(description.patterns).to eql(Machinery::PatternsScope.new)
    end
  end
end
