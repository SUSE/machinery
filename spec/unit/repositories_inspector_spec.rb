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

describe RepositoriesInspector do
  let(:system) {
    double
  }

  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
  }

  describe "zypper repositories" do
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
        <repo alias="SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Pool" name="SLES12-Pool" type="rpm-md" priority="99" enabled="1" autorefresh="0" gpgcheck="1">
        <url>https://updates.suse.com/SUSE/Products/SLE-SERVER/12/x86_64/product?5bcc650926e7f0c7ef4858047a5c1351f4239abe4dc5aafc7361cc2b47c1c13d21e53b8150115ffdd717636c1a26862f8e4ae463bbb1f318fea4234fe7202173edaf71db08671ff733d5a5695b1bd052deae102819327f8ac6ec4e</url>
        </repo>
        </repo-list>
        </stream>
      EOF
    }
    let(:zypper_output_details) {
      <<-EOF
Weird zypper warning message which shouldn't mess up the repository parsing.
#  | Alias               | Name                        | Enabled | Refresh | Priority | Type   | URI                                                                     | Service
---+---------------------+-----------------------------+---------+---------+----------+--------+-------------------------------------------------------------------------+--------
1 | repo-oss            | openSUSE-Oss                | Yes     | Yes     |   23     | yast2  | http://download.opensuse.org/distribution/13.1/repo/oss/                |
2 | repo-update         | openSUSE-Update             | Yes     | Yes     |   47     | rpm-md | http://download.opensuse.org/update/13.1/                               |
3 | nu_novell_com:SLES11-SP3-Pool                    | SLES11-SP3-Pool                                  | Yes     | Yes     |   99     | rpm-md | https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials             | nu_novell_com
4 | SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Pool              | SLES12-Pool              | Yes     | No      |   99     | rpm-md | https://updates.suse.com/SUSE/Products/SLE-SERVER/12/x86_64/product?5bcc650926e7f0c7ef4858047a5c1351f4239abe4dc5aafc7361cc2b47c1c13d21e53b8150115ffdd717636c1a26862f8e4ae463bbb1f318fea4234fe7202173edaf71db08671ff733d5a5695b1bd052deae102819327f8ac6ec4e                   | SUSE_Linux_Enterprise_Server_12_x86_64
      EOF
    }
    let(:expected_repo_list) {
      RepositoriesScope.new([
        Repository.new(
          alias: "nu_novell_com:SLES11-SP3-Pool",
          name: "SLES11-SP3-Pool",
          type: "rpm-md",
          enabled: true,
          autorefresh: true,
          gpgcheck: true,
          priority: 99,
          url: "https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials",
          username: "d4c0246d79334fa59a9ffe625fffef1d",
          password: "0a0918c876ef4a1d9c352e5c47421235",
          package_manager: "zypp"
        ),
        Repository.new(
          alias: "SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Pool",
          name: "SLES12-Pool",
          type: "rpm-md",
          enabled: true,
          autorefresh: false,
          gpgcheck: true,
          priority: 99,
          url: "https://updates.suse.com/SUSE/Products/SLE-SERVER/12/x86_64/product?5bcc650926e7f0c7ef4858047a5c1351f4239abe4dc5aafc7361cc2b47c1c13d21e53b8150115ffdd717636c1a26862f8e4ae463bbb1f318fea4234fe7202173edaf71db08671ff733d5a5695b1bd052deae102819327f8ac6ec4e",
          username: "SCC_d91435cca69a232114cf2e14aa830ad5",
          password: "2fdcb7499fd46842",
          package_manager: "zypp"
        ),
        Repository.new(
          alias: "repo-oss",
          name: "openSUSE-Oss",
          type: "yast2",
          enabled: true,
          autorefresh: true,
          gpgcheck: true,
          priority: 22,
          url: "http://download.opensuse.org/distribution/13.1/repo/oss/",
          package_manager: "zypp"
        ),
          Repository.new(
          alias: "repo-update",
          name: "openSUSE-Update",
          type: "rpm-md",
          enabled: false,
          autorefresh: false,
          gpgcheck: false,
          priority: 47,
          url: "http://download.opensuse.org/update/13.1/",
          package_manager: "zypp"
        )
      ])
    }
    let(:credentials_directories) { "NCCcredentials\nSCCcredentials\n" }
    let(:ncc_credentials) {
      <<-EOF
username=d4c0246d79334fa59a9ffe625fffef1d
password=0a0918c876ef4a1d9c352e5c47421235
      EOF
    }
    let(:scc_credentials) {
      <<-EOF
username=SCC_d91435cca69a232114cf2e14aa830ad5
password=2fdcb7499fd46842
      EOF
    }
    let(:credential_dir) { "/etc/zypp/credentials.d/" }

    before(:each) do
      allow(system).to receive(:has_command?).with("zypper").and_return(true)
    end

    def setup_expectation_zypper_xml(system, output)
      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "--xmlout",
        "repos",
        "--details",
        stdout: :capture
      ).and_return(output)
    end

    def setup_expectation_zypper_details(system, output)
      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "repos",
        "--details",
        stdout: :capture
      ).and_return(output)
    end

    def setup_expectation_zypper_details_exit_6(system)
      # zypper exits with 6 (ZYPPER_EXIT_NO_REPOS) when there are no repos
      status = double
      allow(status).to receive(:exitstatus).and_return(6)
      zypper_exception = Cheetah::ExecutionFailed.new("zypper", status, "", "")
      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "repos",
        "--details",
        stdout: :capture
      ).and_raise(zypper_exception)
    end

    it "returns data about repositories when requirements are fulfilled" do
      setup_expectation_zypper_xml(system, zypper_output_xml)
      setup_expectation_zypper_details(system, zypper_output_details)

      expect(system).to receive(:run_command).with(
        "bash", "-c",
        "test -d '#{credential_dir}' && ls -1 '#{credential_dir}' || echo ''",
        stdout: :capture
      ).and_return(credentials_directories)

      expect(system).to receive(:run_command).with(
        "cat",
        "/etc/zypp/credentials.d/NCCcredentials",
        stdout: :capture
      ).and_return(ncc_credentials)

      expect(system).to receive(:run_command).with(
        "cat",
        "/etc/zypp/credentials.d/SCCcredentials",
        stdout: :capture
      ).and_return(scc_credentials)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to match_array(expected_repo_list)
      expect(summary).to include("Found 4 repositories")
    end

    it "returns an empty array if there are no repositories" do
      zypper_empty_output_xml = <<-EOF
        <?xml version='1.0'?>
        <stream>
        <repo-list>
        </repo-list>
        </stream>
      EOF
      zypper_empty_output_details = "No repositories defined. Use the " \
        "'zypper addrepo' command to add one or more repositories."

      setup_expectation_zypper_xml(system, zypper_empty_output_xml)
      setup_expectation_zypper_details(system, zypper_empty_output_details)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to eq(RepositoriesScope.new([]))
      expect(summary).to include("Found 0 repositories")
    end

    it "returns an empty array if zypper exits with ZYPPER_EXIT_NO_REPOS" do
      zypper_empty_output_xml = <<-EOF
        <?xml version='1.0'?>
        <stream>
        <repo-list>
        </repo-list>
        </stream>
      EOF

      setup_expectation_zypper_xml(system, zypper_empty_output_xml)
      setup_expectation_zypper_details_exit_6(system)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to eq(RepositoriesScope.new([]))
      expect(summary).to include("Found 0 repositories")
    end

    it "raise an error when requirements are not fulfilled" do
      allow(system).to receive(:has_command?).with("zypper").and_return(false)
      allow(system).to receive(:has_command?).with("yum").and_return(false)

      inspector = RepositoriesInspector.new
      expect { inspector.inspect(system, description) }.to raise_error(
        Machinery::Errors::MissingRequirement, /Need either the binary 'zypper' or 'yum'/
      )
    end

    it "returns sorted data" do
      setup_expectation_zypper_xml(system, zypper_output_xml)
      setup_expectation_zypper_details(system, zypper_output_details)
      expect(system).to receive(:run_command) { credentials_directories }
      expect(system).to receive(:run_command) { ncc_credentials }
      expect(system).to receive(:run_command) { scc_credentials }

      inspector = RepositoriesInspector.new

      inspector.inspect(system, description)
      names = description.repositories.map(&:name)

      expect(names).to eq(names.sort)
    end
  end

  describe "yum repositories" do
    let(:expected_yum_extractor_output) {
      output = <<-EOF
"Loaded plugins: priorities"
[{"name": "added from: http://download.opensuse.org/repositories/Virtualization:/Appliances/RedHat_RHEL-6/", "url": "http://download.opensuse.org/repositories/Virtualization:/Appliances/RedHat_RHEL-6/", "enabled": true, "alias": "download.opensuse.org_repositories_Virtualization_Appliances_RedHat_RHEL-6_", "gpgcheck": true, "package_manager": "yum", "type": "rpm-md"}, {"name": "Red Hat Enterprise Linux 6Server - x86_64 - Source", "url": "ftp://ftp.redhat.com/pub/redhat/linux/enterprise/6Server/en/os/SRPMS/", "enabled": false, "alias": "rhel-source", "gpgcheck": true, "package_manager": "yum", "type": "rpm-md"}]
EOF
      output.chomp
    }

    let(:faulty_yum_extractor_output) {<<-EOF
broken json
output
EOF
    }

    let(:unsupported_metalink_repo) {<<-EOF
[{"package_manager": "yum", "name": "Fedora 21 - x86_64", "url": "", "enabled": true, "alias": "fedora", "gpgcheck": true, "type": "rpm-md"}]
EOF
    }

    let(:expected_yum_repo_list) {
      RepositoriesScope.new([
        Repository.new(
          name: "added from: http://download.opensuse.org/repositories/Virtualization:/Appliances/RedHat_RHEL-6/",
          url: "http://download.opensuse.org/repositories/Virtualization:/Appliances/RedHat_RHEL-6/",
          enabled: true,
          alias: "download.opensuse.org_repositories_Virtualization_Appliances_RedHat_RHEL-6_",
          gpgcheck: true,
          type: "rpm-md",
          package_manager: "yum"
        ),
        Repository.new(
          name: "Red Hat Enterprise Linux 6Server - x86_64 - Source",
          url: "ftp://ftp.redhat.com/pub/redhat/linux/enterprise/6Server/en/os/SRPMS/",
          enabled: false,
          alias: "rhel-source",
          gpgcheck: true,
          type: "rpm-md",
          package_manager: "yum"
        )
      ])
    }

    before(:each) do
      allow(system).to receive(:has_command?).with("zypper").and_return(false)
      allow(system).to receive(:has_command?).with("yum").and_return(true)
    end

    it "inspects repos" do
      expect(system).to receive(:run_command).and_return(expected_yum_extractor_output)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to match_array(expected_yum_repo_list)
      expect(summary).to include("Found 2 repositories")
    end

    it "throws an error if the python output is not parseable by json" do
      expect(system).to receive(:run_command).and_return(faulty_yum_extractor_output)

      inspector = RepositoriesInspector.new
      expect { inspector.inspect(system, description) }.to raise_error(
        Machinery::Errors::InspectionFailed, /Extraction of YUM repositories failed./
      )
    end

    # We don't support Yum Metalink repositories atm
    it "throws an Machinery AnalysisFailed error when the url is empty" do
      expect(system).to receive(:run_command).and_return(unsupported_metalink_repo)

      inspector = RepositoriesInspector.new
      expect { inspector.inspect(system, description) }.to raise_error(
        Machinery::Errors::InspectionFailed, /Yum repository baseurl is missing/
      )
    end
  end
end
