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

describe OsInspector do
  include FakeFS::SpecHelpers

  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
  }
  let(:system) { LocalSystem.new }
  let(:filter) { nil }
  subject(:inspector) { OsInspector.new(system, description) }

  before(:each) do
    Dir.mkdir("/etc")
  end

  describe "#get_os_from_os_release" do
    it "gets os info from os-release file" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSE13.1/etc/os-release",
        "/etc/os-release")

      os = inspector.send(:get_os_from_os_release)

      expect(os).to eq(
        OsOpenSuse13_1.new(
          name: "openSUSE 13.1 (Bottle)",
          version: "13.1 (Bottle)"
        )
      )
    end

    it "gets os info from os-release file for new Tumbleweed syntax" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSETumbleweedNewSyntax/etc/os-release",
        "/etc/os-release")

      os = inspector.send(:get_os_from_os_release)

      expect(os).to be_an_instance_of(OsOpenSuseTumbleweed)
      expect(os.name).to eq("openSUSE Tumbleweed")
      expect(os.version).to match(/[0-9]{8}/)
    end

    it "gets os info from RHEL7 os-release file" do
      FakeFS::FileSystem.clone("spec/data/os/rhel7/etc/os-release",
        "/etc/os-release")

      os = inspector.send(:get_os_from_os_release)

      expect(os).to eq(
        OsUnknown.new(
          name: "Red Hat Enterprise Linux Server 7.0 (Maipo)",
          version: "7.0 (Maipo)"
        )
      )
    end
  end

  describe "#get_os_from_suse_release" do
    it "gets os info from SuSE-release file" do
      FakeFS::FileSystem.clone("spec/data/os/SLES11/etc/SuSE-release",
        "/etc/SuSE-release")
      os = inspector.send(:get_os_from_suse_release)

      expect(os.name).to eq "SUSE Linux Enterprise Server 11"
      expect(os.version).to eq "11 SP3"
    end

    it "gets os info from SuSE-release file for the new Tumbleweed syntax" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSETumbleweedNewSyntax/etc/SuSE-release",
        "/etc/SuSE-release")
      os = inspector.send(:get_os_from_suse_release)

      expect(os.name).to eq "openSUSE Tumbleweed"
      expect(os.version).to match(/[0-9]{8}/)
    end
  end

  describe "#get_os_from_redhat_release" do
    it "gets os info from redhat release file" do
      FakeFS::FileSystem.clone("spec/data/os/rhel6/etc/redhat-release",
        "/etc/redhat-release")
      os = inspector.send(:get_os_from_redhat_release)

      expect(os.name).to eq "Red Hat Enterprise Linux Server"
      expect(os.version).to eq "6.5 (Santiago)"
    end
  end

  describe ".inspect" do
    it "returns data about the operation system on a system with os-release" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSE13.1/etc/os-release",
        "/etc/os-release")
      FakeFS::FileSystem.clone("spec/data/os/openSUSE13.1/etc/issue",
        "/etc/issue")

      expect(system).to receive(:arch).and_return("x86_64")

      inspector.inspect(filter)

      expect(description.os).to eq(
        OsOpenSuse13_1.new(
          name: "openSUSE 13.1 (Bottle)",
          version: "13.1 (Bottle)",
          architecture: "x86_64"
        )
      )
      expect(inspector.summary).to include("openSUSE")
    end

    it "returns data about the operation system on a system with redhat-release" do
      FakeFS::FileSystem.clone("spec/data/os/rhel6/etc/redhat-release",
        "/etc/redhat-release")

      expect(system).to receive(:arch).and_return("x86_64")

      inspector.inspect(filter)

      expect(description.os.name).to eq "Red Hat Enterprise Linux Server"
      expect(description.os.version).to eq "6.5 (Santiago)"
      expect(description.os.architecture).to eq "x86_64"
      expect(inspector.summary).to include("Red Hat Enterprise Linux Server")
    end

    it "returns data about the operation system on a system with suse-release" do
      FakeFS::FileSystem.clone("spec/data/os/SLES11/etc/SuSE-release",
        "/etc/SuSE-release")

      expect(system).to receive(:arch).and_return("x86_64")

      inspector.inspect(filter)

      expect(description.os.name).to eq "SUSE Linux Enterprise Server 11"
      expect(description.os.version).to eq "11 SP3"
      expect(description.os.architecture).to eq "x86_64"
      expect(inspector.summary).to include("SUSE Linux Enterprise Server")
    end

    it "is able to recognize the rolling openSUSE release Tumbleweed" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSETumbleweed/etc/os-release",
        "/etc/os-release")

      expect(system).to receive(:arch).and_return("x86_64")

      inspector.inspect(filter)

      expect(description.os.name).to eq "openSUSE Tumbleweed"
      expect(description.os.version).to eq("20160909")
      expect(description.os.architecture).to eq "x86_64"
      expect(inspector.summary).to include("openSUSE Tumbleweed")
      expect(description.os).to be_a(OsOpenSuseTumbleweed)
    end

    it "is able to recognize the openSUSE release Leap" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSELeap/etc/os-release",
        "/etc/os-release")

      expect(system).to receive(:arch).and_return("x86_64")

      inspector.inspect(filter)

      expect(description.os.name).to eq "openSUSE Leap"
      expect(description.os.version).to eq("42.1")
      expect(description.os.architecture).to eq "x86_64"
      expect(inspector.summary).to include("openSUSE Leap")
      expect(description.os).to be_a(OsOpenSuseLeap)
    end

    it "is able to recognize SLES11SP4" do
      FakeFS::FileSystem.clone("spec/data/os/SLES11SP4/etc/",
        "/etc/")

      expect(system).to receive(:arch).and_return("x86_64")

      inspector.inspect(filter)

      expect(description.os.name).to eq "SUSE Linux Enterprise Server 11"
      expect(description.os.version).to eq("11 SP4")
      expect(description.os.architecture).to eq "x86_64"
      expect(inspector.summary).to include("SUSE Linux Enterprise Server 11")
      expect(description.os).to be_a(OsSles11)
    end

    it "returns data containing additional version information if available" do
      FakeFS::FileSystem.clone("spec/data/os/SLES12/etc/os-release",
        "/etc/os-release")
      FakeFS::FileSystem.clone("spec/data/os/SLES12/etc/issue",
        "/etc/issue")

      expect(system).to receive(:arch).and_return("x86_64")

      inspector.inspect(filter)

      expect(description.os.version).to eq("12 Beta 1")
    end

    it "returns correct data if additonal version information contains double digits" do
      FakeFS::FileSystem.clone("spec/data/os/SLES11/etc/SuSE-release",
        "/etc/SuSE-release")
      FakeFS::FileSystem.clone("spec/data/os/SLES11/etc/issue",
        "/etc/issue")

      expect(system).to receive(:arch).and_return("x86_64")

      inspector.inspect(filter)

      expect(description.os.version).to eq("11 SP3 Beta 10")
    end

    it "returns correct data if a legacy openSUSE version is inspected" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSE11.2/etc/SuSE-release",
        "/etc/SuSE-release")
      FakeFS::FileSystem.clone("spec/data/os/openSUSE11.2/etc/issue",
        "/etc/issue")

      expect(system).to receive(:arch).and_return("i586")

      inspector.inspect(filter)

      expect(description.os.version).to eq("11.2")
      expect(description.os.name).to eq("openSUSE 11.2")
    end

    it "returns correct data if an unsupported SLES (marked as Dummy) is inspected" do
      FakeFS::FileSystem.clone("spec/data/os/dummy/etc/os-release",
        "/etc/os-release")
      FakeFS::FileSystem.clone("spec/data/os/dummy/etc/issue",
        "/etc/issue")

      expect(system).to receive(:arch).and_return("i586")

      inspector.inspect(filter)

      expect(description.os).to eq(
        OsUnknown.new(
          name: "Dummy",
          version: nil,
          architecture: "i586"
        )
      )
    end

    it "throws exception when the operation system cannot be determined" do
      expect {
        inspector.inspect(filter)
      }.to raise_error(
        Machinery::Errors::UnknownOs,
        "Unable to determine the operating system. There does not seem to be an" \
          " /etc/os-release file."
      )
    end
  end
end
