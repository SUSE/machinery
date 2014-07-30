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

describe RepositoriesInspector do
  let(:description) {
    SystemDescription.new("systemname", {}, SystemDescriptionStore.new)
  }

  describe ".inspect" do
    let(:zypper_output_xml) {
      <<-EOF
        <?xml version='1.0'?>
        <stream>
        <repo-list>
        <repo alias="repo-update" name="openSUSE-Update" type="rpm-md" enabled="0" autorefresh="0" gpgcheck="0">
        <url>http://download.opensuse.org/update/13.1/</url>
        </repo>
        <repo alias="repo-oss" name="openSUSE-Oss" type="yast2" enabled="1" autorefresh="1" gpgcheck="1" priority="22">
        <url>http://download.opensuse.org/distribution/13.1/repo/oss/</url>
        </repo>
        <repo alias="nu_novell_com:SLES11-SP3-Pool" name="SLES11-SP3-Pool" type="rpm-md" enabled="1" autorefresh="1" gpgcheck="1">
        <url>https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials</url>
        </repo>
        </repo-list>
        </stream>
      EOF
    }
    let(:zypper_output_detail) {
      <<-EOF
Weird zypper warning message which shouldn't mess up the repository parsing.
#  | Alias               | Name                        | Enabled | Refresh | Priority | Type   | URI                                                                     | Service
---+---------------------+-----------------------------+---------+---------+----------+--------+-------------------------------------------------------------------------+--------
 8 | repo-oss            | openSUSE-Oss                | Yes     | Yes     |   23     | yast2  | http://download.opensuse.org/distribution/13.1/repo/oss/                |
10 | repo-update         | openSUSE-Update             | Yes     | Yes     |   47     | rpm-md | http://download.opensuse.org/update/13.1/                               |
15 | nu_novell_com:SLES11-SP3-Pool                    | SLES11-SP3-Pool                                  | Yes     | Yes     |   99     | rpm-md | https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials             | nu_novell_com
      EOF
    }
    let(:expected_repo_list) {
      RepositoriesScope.new([
        Repository.new(
          alias: "nu_novell_com:SLES11-SP3-Pool",
          name: "SLES11-SP3-Pool",
          repo_type: "rpm-md",
          enabled: true,
          autorefresh: true,
          gpgcheck: true,
          priority: 99,
          url: "https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials",
          username: "d4c0246d79334fa59a9ffe625fffef1d",
          password: "0a0918c876ef4a1d9c352e5c47421235"
        ),
          Repository.new(
          alias: "repo-oss",
          name: "openSUSE-Oss",
          repo_type: "yast2",
          enabled: true,
          autorefresh: true,
          gpgcheck: true,
          priority: 22,
          url: "http://download.opensuse.org/distribution/13.1/repo/oss/"
        ),
          Repository.new(
          alias: "repo-update",
          name: "openSUSE-Update",
          repo_type: "rpm-md",
          enabled: false,
          autorefresh: false,
          gpgcheck: false,
          priority: 47,
          url: "http://download.opensuse.org/update/13.1/"
        )
      ])
    }
    let(:credentials_directories) { "NCCcredentials\n" }
    let(:ncc_credentials) {
      <<-EOF
username=d4c0246d79334fa59a9ffe625fffef1d
password=0a0918c876ef4a1d9c352e5c47421235
      EOF
    }
    let(:credential_dir) { "/etc/zypp/credentials.d/" }


    it "returns data about repositories when requirements are fulfilled" do
      system = double
      expect(system).to receive(:check_requirement).with(
        "zypper", "--version"
      )
      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "--xmlout",
        "repos",
        "--details",
        :stdout => :capture
      ).and_return(zypper_output_xml)

      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "repos",
        "--details",
        :stdout => :capture
      ).and_return(zypper_output_detail)

      expect(system).to receive(:run_command).with(
        "bash", "-c",
        "test -d '#{credential_dir}' && ls -1 '#{credential_dir}' || echo ''",
        :stdout => :capture
      ).and_return(credentials_directories)

      expect(system).to receive(:run_command).with(
        "cat",
        "/etc/zypp/credentials.d/NCCcredentials",
        :stdout => :capture
      ).and_return(ncc_credentials)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to eq(expected_repo_list)
      expect(summary).to include("Found 3 repositories")
    end

    it "returns an empty array if there are no repositories" do
      system = double
      zypper_empty_output_xml = <<-EOF
        <?xml version='1.0'?>
        <stream>
        <repo-list>
        </repo-list>
        </stream>
      EOF
      zypper_empty_output_detail = "No repositories defined. Use the " \
        "'zypper addrepo' command to add one or more repositories."

      expect(system).to receive(:check_requirement).with(
        "zypper", "--version"
      )
      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "--xmlout",
        "repos",
        "--details",
        :stdout => :capture
      ).and_return(zypper_empty_output_xml)

      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "repos",
        "--details",
        :stdout => :capture
      ).and_return(zypper_empty_output_detail)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to eq(RepositoriesScope.new([]))
      expect(summary).to include("Found 0 repositories")
    end


    it "raise an error when requirements are not fulfilled" do
      system = double
      expect(system).to receive(:check_requirement).with(
        "zypper", "--version"
      ).and_raise(Machinery::Errors::MissingSystemRequirement)

      inspector = RepositoriesInspector.new
      expect{inspector.inspect(system, description)}.to raise_error(
        Machinery::Errors::MissingSystemRequirement)
    end

    it "returns sorted data" do
      system = double
      expect(system).to receive(:check_requirement) { true }
      expect(system).to receive(:run_command) { zypper_output_xml }
      expect(system).to receive(:run_command) { zypper_output_detail }
      expect(system).to receive(:run_command) { credentials_directories }
      expect(system).to receive(:run_command) { ncc_credentials }

      inspector = RepositoriesInspector.new

      inspector.inspect(system, description)
      names = description.repositories.map(&:name)

      expect(names).to eq(names.sort)
    end
  end
end
