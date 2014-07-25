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

require_relative "spec_helper"

describe OsInspector do
  let(:description) {
    SystemDescription.new("systemname", {}, SystemDescriptionStore.new)
  }
  subject(:inspector) { OsInspector.new }

  def expect_read_file(inspector, system, file, content)
    expect(inspector).to receive(:read_file_if_exists).with(
      system, file).and_return(content)
  end

  describe ".inspect" do
    it "reads a file from the inspected system" do
      system = double
      result = "Welcome to openSUSE 13.1 \"Bottle\" - Kernel \r (\l)."
      filename = "spec/data/os/openSUSE13.1/etc/issue"

      expect(system).to receive(:run_command).with(
        "sh", "-c", "if [ -e #{filename} ]; then cat #{filename} ; fi",
        :stdout => :capture).and_return(result)

      expect(inspector.read_file_if_exists(system, filename)).to eq(result)
    end

    it "determines the architecture of the inspected system" do
      system = double
      result = "x86_64"

      expect(system).to receive(:run_command).with(
        "uname", "-m", :stdout => :capture).and_return(result)
      expect(inspector.determine_arch(system)).to eq(result)
    end

    it "returns data about the operation system on a system with os-release" do
      system = double
      os_release_file = File.read("spec/data/os/openSUSE13.1/etc/os-release")
      os_release_name = "/etc/os-release"
      issue_file = File.read("spec/data/os/openSUSE13.1/etc/issue")
      issue_name = "/etc/issue"

      expect(system).to receive(:check_requirement)
      expect_read_file(inspector, system, os_release_name, os_release_file)
      expect_read_file(inspector, system, issue_name, issue_file)
      expect(inspector).to receive(:determine_arch).with(system).and_return("x86_64")

      summary = inspector.inspect(system, description)

      expect(description.os).to eq(
        OsScope.new(
          name: "openSUSE 13.1 (Bottle)",
          version: "13.1 (Bottle)",
          version_id: "13.1",
          pretty_name: "openSUSE 13.1 (Bottle)",
          id: "opensuse",
          ansi_color: "0;32",
          cpe_name: "cpe:/o:opensuse:opensuse:13.1",
          bug_report_url: "https://bugs.opensuse.org",
          home_url: "https://opensuse.org/",
          id_like: "suse",
          architecture: "x86_64"
        )
      )
      expect(summary).to include("openSUSE")
    end

    it "returns data about the operation system on a system with suse-release" do
      system = double
      suse_release_file = File.read("spec/data/os/SLES11/etc/SuSE-release")
      suse_release_name = "/etc/SuSE-release"

      expect(system).to receive(:check_requirement)
      expect_read_file(inspector, system, "/etc/os-release", "")
      expect_read_file(inspector, system, suse_release_name, suse_release_file)
      expect_read_file(inspector, system, "/etc/issue", "")
      expect(inspector).to receive(:determine_arch).with(system).and_return("x86_64")

      summary = inspector.inspect(system, description)

      expect(description.os.name).to eq "SUSE Linux Enterprise Server 11"
      expect(description.os.version).to eq "11 SP3"
      expect(description.os.architecture).to eq "x86_64"
      expect(summary).to include("SUSE Linux Enterprise Server")
    end

    it "returns data containing additional version information if available" do
      system = double
      os_release_file = File.read("spec/data/os/SLES12/etc/os-release")
      os_release_name = "/etc/os-release"
      issue_file = File.read("spec/data/os/SLES12/etc/issue")
      issue_name = "/etc/issue"

      expect(system).to receive(:check_requirement)
      expect_read_file(inspector, system, os_release_name, os_release_file)
      expect_read_file(inspector, system, issue_name, issue_file)
      expect(inspector).to receive(:determine_arch).with(system).and_return("x86_64")

      inspector.inspect(system, description)

      expect(description.os.version).to eq("12 Beta 1")
    end

    it "returns correct data if additonal version information contains double digits" do
      system = double
      suse_release_file = File.read("spec/data/os/SLES11/etc/SuSE-release")
      suse_release_name = "/etc/SuSE-release"
      issue_file = File.read("spec/data/os/SLES11/etc/issue")
      issue_name = "/etc/issue"

      expect(system).to receive(:check_requirement)
      expect_read_file(inspector, system, "/etc/os-release", "")
      expect_read_file(inspector, system, suse_release_name, suse_release_file)
      expect_read_file(inspector, system, issue_name, issue_file)
      expect(inspector).to receive(:determine_arch).with(system).and_return("x86_64")

      inspector.inspect(system, description)

      expect(description.os.version).to eq("11 SP3 Beta 10")
    end

    it "returns data containing nil when the operation system cannot be determined" do
      system = double

      expect(system).to receive(:check_requirement)
      expect_read_file(inspector, system, "/etc/os-release", "")
      expect_read_file(inspector, system, "/etc/SuSE-release", "")

      inspector.inspect(system, description)

      expect(description.os.name).to eq nil
      expect(description.os.version).to eq nil
      expect(description.os.architecture).to eq nil
    end
  end
end
