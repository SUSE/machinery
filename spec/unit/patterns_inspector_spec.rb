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

describe PatternsInspector do
  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
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

  let(:patterns_inspector) { PatternsInspector.new(system, description) }
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
      end

      it "parses the patterns list into a Hash" do
        expect(system).to receive(:run_command).
          with("zypper", "-xq", "--no-refresh", "patterns", "-i", stdout: :capture).
          and_return(zypper_output)
        patterns_inspector.inspect(filter)

        expect(description.patterns.size).to eql(2)
        expect(description.patterns.first).to eq(
          Pattern.new(
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
        expect(description.patterns).to eql(PatternsScope.new)
      end

      it "returns sorted data" do
        expect(system).to receive(:run_command).and_return(zypper_output)

        patterns_inspector.inspect(filter)
        names = description.patterns.map(&:name)
        expect(names).to eq(names.sort)
      end

      it "raises an error if zypper is locked" do
        expect(system).to receive(:run_command).
          with("zypper", "-xq", "--no-refresh", "patterns", "-i",
            stdout: :capture).
          and_raise(
            Cheetah::ExecutionFailed.new(
              nil,
              nil,
              "System management is locked by the application with pid 5480 (zypper).",
              nil
            )
          )
        expect { patterns_inspector.inspect(filter) }.to raise_error(
          Machinery::Errors::ZypperFailed, /Zypper is locked./)
      end
    end

    context "on a tasksel based OS" do
      before(:each) do
        allow(system).to receive(:has_command?).with("zypper").and_return(false)
        allow(system).to receive(:has_command?).with("tasksel").and_return(true)
      end

      it "parses the patterns list into a Hash" do
        expect(system).to receive(:run_command).
          with("tasksel", "--list-tasks", stdout: :capture).
          and_return(tasksel_output)
        patterns_inspector.inspect(filter)

        expect(description.patterns.size).to eql(5)
        expect(description.patterns.first).to eql(
          Pattern.new(
            name: "dns-server"
          )
        )

        expect(patterns_inspector.summary).to include("Found 5 patterns")
      end
    end

    it "returns an empty array when no zypper or tasksel is installed and shows an unsupported message" do
      allow(system).to receive(:has_command?).with("zypper").and_return(false)
      allow(system).to receive(:has_command?).with("tasksel").and_return(false)

      summary = patterns_inspector.inspect(filter)
      expect(summary).to eq("Patterns are not supported on this system.")
      expect(description.patterns).to eql(PatternsScope.new)
    end
  end
end
