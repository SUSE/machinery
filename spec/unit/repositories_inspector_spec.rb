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

describe Machinery::RepositoriesInspector do
  capture_machinery_output
  let(:system) {
    double
  }
  let(:description) {
    Machinery::SystemDescription.new("systemname", Machinery::SystemDescriptionStore.new)
  }
  let(:filter) { nil }
  let(:inspector) { Machinery::RepositoriesInspector.new(system, description) }

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
      Machinery::RepositoriesScope.new(
        [
          Machinery::ZyppRepository.new(
            alias: "nu_novell_com:SLES11-SP3-Pool",
            name: "SLES11-SP3-Pool",
            type: "rpm-md",
            enabled: true,
            autorefresh: true,
            gpgcheck: true,
            priority: 99,
            url: "https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials",
            username: "d4c0246d79334fa59a9ffe625fffef1d",
            password: "0a0918c876ef4a1d9c352e5c47421235"
          ),
          Machinery::ZyppRepository.new(
            alias: "SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Pool",
            name: "SLES12-Pool",
            type: "rpm-md",
            enabled: true,
            autorefresh: false,
            gpgcheck: true,
            priority: 99,
            url: "https://updates.suse.com/SUSE/Products/SLE-SERVER/12/x86_64/product?5bcc650926e7f0c7ef4858047a5c1351f4239abe4dc5aafc7361cc2b47c1c13d21e53b8150115ffdd717636c1a26862f8e4ae463bbb1f318fea4234fe7202173edaf71db08671ff733d5a5695b1bd052deae102819327f8ac6ec4e",
            username: "SCC_d91435cca69a232114cf2e14aa830ad5",
            password: "2fdcb7499fd46842"
          ),
          Machinery::ZyppRepository.new(
            alias: "repo-oss",
            name: "openSUSE-Oss",
            type: "yast2",
            enabled: true,
            autorefresh: true,
            gpgcheck: true,
            priority: 22,
            url: "http://download.opensuse.org/distribution/13.1/repo/oss/"
          ),
          Machinery::ZyppRepository.new(
            alias: "repo-update",
            name: "openSUSE-Update",
            type: "rpm-md",
            enabled: false,
            autorefresh: false,
            gpgcheck: false,
            priority: 47,
            url: "http://download.opensuse.org/update/13.1/"
          )
        ],
        repository_system: "zypp"
      )
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
        stdout: :capture, privileged: true
      ).and_return(ncc_credentials)

      expect(system).to receive(:run_command).with(
        "cat",
        "/etc/zypp/credentials.d/SCCcredentials",
        stdout: :capture, privileged: true
      ).and_return(scc_credentials)

      inspector.inspect(filter)
      expect(description.repositories).to eq(expected_repo_list)
      expect(inspector.summary).to include("Found 4 repositories")
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

      inspector.inspect(filter)
      expect(description.repositories).
        to eq(Machinery::RepositoriesScope.new([], repository_system: "zypp"))
      expect(inspector.summary).to include("Found 0 repositories")
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

      inspector.inspect(filter)
      expect(description.repositories).
        to eq(Machinery::RepositoriesScope.new([], repository_system: "zypp"))
      expect(inspector.summary).to include("Found 0 repositories")
    end

    it "raise an error when requirements are not fulfilled" do
      allow(system).to receive(:has_command?).with("zypper").and_return(false)
      allow(system).to receive(:has_command?).with("yum").and_return(false)
      allow(system).to receive(:has_command?).with("dpkg").and_return(false)

      expect { inspector.inspect(filter) }.to raise_error(
        Machinery::Errors::MissingRequirement, /Need either the binary 'zypper', 'yum' or 'apt'/
      )
    end

    it "returns sorted data" do
      setup_expectation_zypper_xml(system, zypper_output_xml)
      setup_expectation_zypper_details(system, zypper_output_details)
      expect(system).to receive(:run_command) { credentials_directories }
      expect(system).to receive(:run_command) { ncc_credentials }
      expect(system).to receive(:run_command) { scc_credentials }

      inspector.inspect(filter)
      names = description.repositories.map(&:name)

      expect(names).to eq(names.sort)
    end
  end

  describe "yum repositories" do
    let(:expected_yum_extractor_output) {
      output = <<-EOF
"Loaded plugins: priorities"
[{"name": "CentOS-6Server - Base", "url": [], "gpgkey": ["http://mirror.centos.org/centos/RPM-GPG-KEY-centos4"], "enabled": true, "alias": "base", "mirrorlist": "http://mirrorlist.centos.org/?release=6Server&arch=x86_64&repo=os", "gpgcheck": true, "type": "rpm-md"},{"name": "added from: http://download.opensuse.org/repositories/Virtualization:/Appliances/RedHat_RHEL-6/", "url": ["http://download.opensuse.org/repositories/Virtualization:/Appliances/RedHat_RHEL-6/"], "gpgkey": [], "enabled": false, "alias": "download.opensuse.org_repositories_Virtualization_Appliances_RedHat_RHEL-6_", "mirrorlist": "", "gpgcheck": false, "type": "rpm-md"}]
EOF
      output.chomp
    }

    let(:faulty_yum_extractor_output) {<<-EOF
broken json
output
EOF
    }

    let(:expected_yum_repo_list) {
      Machinery::RepositoriesScope.new(
        [
          Machinery::YumRepository.new(
            name: "CentOS-6Server - Base",
            url: [],
            mirrorlist: "http://mirrorlist.centos.org/?release=6Server&arch=x86_64&repo=os",
            enabled: true,
            alias: "base",
            gpgcheck: true,
            gpgkey: ["http://mirror.centos.org/centos/RPM-GPG-KEY-centos4"],
            type: "rpm-md"
          ),
          Machinery::YumRepository.new(
            name: "added from: http://download.opensuse.org/repositories/Virtualization:/Appliances/RedHat_RHEL-6/",
            url: ["http://download.opensuse.org/repositories/Virtualization:/Appliances/RedHat_RHEL-6/"],
            mirrorlist: "",
            enabled: false,
            alias: "download.opensuse.org_repositories_Virtualization_Appliances_RedHat_RHEL-6_",
            gpgcheck: false,
            gpgkey: [],
            type: "rpm-md"
          )
        ],
        repository_system: "yum"
      )
    }

    before(:each) do
      allow(system).to receive(:has_command?).with("zypper").and_return(false)
      allow(system).to receive(:has_command?).with("yum").and_return(true)
    end

    it "inspects repos" do
      expect(system).to receive(:run_command).and_return(expected_yum_extractor_output)

      inspector.inspect(filter)
      expect(description.repositories).to eq(expected_yum_repo_list)
      expect(inspector.summary).to include("Found 2 repositories")
    end

    it "throws an error if the python output is not parseable by json" do
      expect(system).to receive(:run_command).and_return(faulty_yum_extractor_output)

      expect { inspector.inspect(filter) }.to raise_error(
        Machinery::Errors::InspectionFailed, /Extraction of YUM repositories failed./
      )
    end

    it "handles failing of the python yum api gracefully" do
      expect(system).to receive(:run_command).and_raise(
        Cheetah::ExecutionFailed.new(nil, nil, nil, "Some error")
      )

      expect { inspector.inspect(filter) }.to raise_error(
        Machinery::Errors::InspectionFailed, /Extraction of YUM repositories failed:\nSome error/
      )
    end
  end

  describe "apt repositories" do
    let(:cat_sources_list) {
      output = <<-EOF
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb cdrom:[Debian GNU/Linux 7.9.0 _Wheezy_ - Official amd64 DVD Binary-1 20150905-14:38]/ wheezy contrib main
deb http://us.archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu trusty-security main   #testcomment
deb-src   http://repo-with-spaces-and-tabs.com/ubuntu   trusty-security component1    component2
EOF
      output.chomp
    }

    let(:cat_sources_list_d) {
      output = <<-EOF
deb http://ppa.launchpad.net/LP-BENUTZER/PPA-NAME/ubuntu trusty main
# deb-src http://ppa.launchpad.net/LP-BENUTZER/PPA-NAME/ubuntu trusty main
deb http://ppa.launchpad.net/LP-BENUTZER/PPA-NAME2/ubuntu trusty/binary-$(ARCH)/
deb-src   http://repo-with-spaces-and-tabs.com/ubuntu   trusty-security component1    component2
EOF
      output.chomp
    }

    let(:expected_apt_repo_list) {
      Machinery::RepositoriesScope.new(
        [
          Machinery::AptRepository.new(
            type: "deb",
            url: "cdrom:[Debian GNU/Linux 7.9.0 _Wheezy_ - Official amd64 DVD Binary-1 20150905-14:38]/",
            distribution: "wheezy",
            components: ["contrib", "main"]
          ),
          Machinery::AptRepository.new(
            type: "deb",
            url: "http://us.archive.ubuntu.com/ubuntu/",
            distribution: "trusty-backports",
            components: ["main", "restricted", "universe", "multiverse"]
          ),
          Machinery::AptRepository.new(
            type: "deb",
            url: "http://security.ubuntu.com/ubuntu",
            distribution: "trusty-security",
            components: ["main"]
          ),
          Machinery::AptRepository.new(
            type: "deb-src",
            url: "http://repo-with-spaces-and-tabs.com/ubuntu",
            distribution: "trusty-security",
            components: ["component1", "component2"]
          ),
          Machinery::AptRepository.new(
            type: "deb",
            url: "http://ppa.launchpad.net/LP-BENUTZER/PPA-NAME/ubuntu",
            distribution: "trusty",
            components: ["main"]
          ),
          Machinery::AptRepository.new(
            type: "deb",
            url: "http://ppa.launchpad.net/LP-BENUTZER/PPA-NAME2/ubuntu",
            distribution: "trusty/binary-$(ARCH)/",
            components: []
          )
        ],
        repository_system: "apt"
      )
    }

    before(:each) do
      allow(system).to receive(:has_command?).with("zypper").and_return(false)
      allow(system).to receive(:has_command?).with("yum").and_return(false)
      allow(system).to receive(:has_command?).with("dpkg").and_return(true)
    end

    it "inspects repos" do
      expect(system).to receive(:read_file).with(
        "/etc/apt/sources.list"
      ).and_return(cat_sources_list)
      expect(system).to receive(:run_command).with(
        "bash", "-c", "cat /etc/apt/sources.list.d/*.list", any_args
      ).and_return(cat_sources_list_d)

      inspector.inspect(filter)
      expect(description.repositories).to eq(expected_apt_repo_list)
      expect(inspector.summary).to include("Found 6 repositories")
    end

    it "can handle an empty /etc/apt/sources.list.d/ directory" do
      expect(system).to receive(:read_file).with(
        "/etc/apt/sources.list"
      ).and_return(cat_sources_list)
      expect(system).to receive(:run_command).with(
        "bash", "-c", "cat /etc/apt/sources.list.d/*.list", any_args
      ).and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect { inspector.inspect(filter) }.not_to raise_error
      expect(inspector.summary).to include("Found 4 repositories")
    end

    it "shows a warning for each found rfc822 style repository but parses the rest" do
      cat_sources_list_new = cat_sources_list
      cat_sources_list_new += <<-EOF

  Types: deb deb-src
  URIs: http://example.com
  Suites: stable testing
  Sections: component1 component2
  Description: short
   long long long
  [option1]: [option1-value]

  Types: deb
  URIs: http://another.example.com
  Suites: experimental
  Sections: component1 component2
  Enabled: no
  Description: short
   long long long
  [option1]: [option1-value]
EOF
      expect(system).to receive(:read_file).with(
        "/etc/apt/sources.list"
      ).and_return(cat_sources_list_new)
      expect(system).to receive(:run_command).with(
        "bash", "-c", "cat /etc/apt/sources.list.d/*.list", any_args
      ).and_return(cat_sources_list_d)

      inspector.inspect(filter)
      expect(captured_machinery_output.scan(
        /Warning: An unsupported rfc822 style repository was found, which will be ignored/
      ).count).to eq(2)
      expect(description.repositories).to eq(expected_apt_repo_list)
    end
  end
end
