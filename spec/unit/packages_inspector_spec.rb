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

describe PackagesInspector, ".inspect" do
  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
  }
  let(:filter) { nil }
  let(:system) {
    double(
      requires_root?: false,
      host: "example.com",
      check_requirement: nil
    )
  }
  let(:packages_inspector) { PackagesInspector.new(system, description) }

  context "rpm inspection" do
    let(:package_example) {
      <<EOF
zypper|1.9.16|22.2|x86_64|openSUSE|4a87f6b9ceae5d40a411fe52d0f17050$
rpm|4.11.1|6.5.1|x86_64|openSUSE|7dfdd742a9b7d60c75bf4844d294716d$
EOF
    }
    let(:expected_packages) {
      PackagesScope.new(
        [
          RpmPackage.new(
            name: "rpm",
            version: "4.11.1",
            release: "6.5.1",
            arch: "x86_64",
            vendor: "openSUSE",
            checksum: "7dfdd742a9b7d60c75bf4844d294716d"
          ),
          RpmPackage.new(
            name: "zypper",
            version: "1.9.16",
            release: "22.2",
            arch: "x86_64",
            vendor: "openSUSE",
            checksum: "4a87f6b9ceae5d40a411fe52d0f17050"
          )
        ],
        package_system: "rpm"
      )
    }
    let(:rpm_command) {
      ["rpm", "-qa", "--qf", "%{NAME}|%{VERSION}|%{RELEASE}|%{ARCH}|%{VENDOR}|%{FILEMD5S}$",
        stdout: :capture]
    }

    before(:each) do
      expect(system).to receive(:has_command?).with("rpm").and_return(true)
    end

    def inspect_data(data = package_example)
      expect(system).to receive(:run_command) { data }

      packages_inspector.inspect(filter)
      description.packages
    end

    it "returns a local SystemDescription containing rpm as one package" do
      expect(inspect_data).to eq(expected_packages)
    end

    it "returns a remote SystemDescription containing rpm as one package" do
      expect(inspect_data(package_example)).to eq(expected_packages)
    end

    it "ignores fake rpm packages with the name gpg-pubkey" do
      data = "gpg-pubkey|39db7c82|1.0$\n#{package_example}"
      expect(inspect_data(data)).to eq(expected_packages)
    end

    it "returns a summary" do
      expect(system).to receive(:check_requirement) { true }
      expect(system).to receive(:run_command) { package_example }

      packages_inspector.inspect(filter)
      expect(packages_inspector.summary).to include("Found 2 packages")
    end

    it "returns sorted data" do
      names = inspect_data.map(&:name)
      expect(names).to eq(names.sort)
    end
  end

  context "dpkg inspection" do
    let(:dpkg_output) {
      <<EOF
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                                                   Version                          Architecture                     Description
+++-======================================================-================================-================================-==================================================================================================================
ii  accountsservice:amd64                                  0:0.6.35-foo-0ubuntu7.2          amd64                            query and manipulate user account information
ii  adduser                                                3.113+nmu3ubuntu3                all                              add and remove users and groups
un  udev                                                   3.113+nmu3ubuntu3                all                              add and remove users and groups
EOF
    }
    let(:apt_cache_output) {
      <<EOF
Package: accountsservice
Priority: standard
Section: gnome
Installed-Size: 428
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Original-Maintainer: Alessio Treglia <alessio@debian.org>
Architecture: amd64
Version: 0:0.6.35-foo-0ubuntu7.2
Depends: dbus, libaccountsservice0 (= 0.6.35-0ubuntu7.2), libc6 (>= 2.4), libgcr-base-3-1 (>= 3.8.0), libglib2.0-0 (>= 2.37.3), libpam0g (>= 0.99.7.1), libpolkit-gobject-1-0 (>= 0.99)
Suggests: gnome-control-center
Filename: pool/main/a/accountsservice/accountsservice_0.6.35-0ubuntu7.2_amd64.deb
Size: 60388
MD5sum: e44935e8ff4d5c086500d4e956e0e852
SHA1: e38b1479bfb605c2ff18befe8f97ce206fe46269
SHA256: 668e02bce93ac1d3ab63d70569b3d60b803ad67333151bf4bb007acdcd717cce
Description-en: query and manipulate user account information
 The AccountService project provides a set of D-Bus
 interfaces for querying and manipulating user account
 information and an implementation of these interfaces,
 based on the useradd, usermod and userdel commands.
Description-md5: 8aeed0a03c7cd494f0c4b8d977483d7e
Homepage: http://cgit.freedesktop.org/accountsservice/
Bugs: https://bugs.launchpad.net/ubuntu/+filebug
Origin: Ubuntu
Supported: 5y
Task: standard, kubuntu-active, kubuntu-active, mythbuntu-frontend, mythbuntu-desktop, mythbuntu-backend-slave, mythbuntu-backend-master

Package: adduser
Priority: required
Section: admin
Installed-Size: 644
Maintainer: Ubuntu Core Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Original-Maintainer: Debian Adduser Developers <adduser-devel@lists.alioth.debian.org>
Architecture: all
Version: 3.113+nmu3ubuntu3
Replaces: manpages-it (<< 0.3.4-2), manpages-pl (<= 20051117-1)
Depends: perl-base (>= 5.6.0), passwd (>= 1:4.0.12), debconf | debconf-2.0
Suggests: liblocale-gettext-perl, perl-modules, ecryptfs-utils (>= 67-1)
Filename: pool/main/a/adduser/adduser_3.113+nmu3ubuntu3_all.deb
Size: 169360
MD5sum: 98c532cd738cfce59d448ed96ea5c8e7
SHA1: a64caa75eee209bacbc39cbbcb058db80e5042af
SHA256: 1461ce364a68db36190a6981ad9e3889c8a5286e809e45c6e34a720905de46a4
Description-en: add and remove users and groups
 This package includes the 'adduser' and 'deluser' commands for creating
 and removing users.
 .
  - 'adduser' creates new users and groups and adds existing users to
    existing groups;
  - 'deluser' removes users and groups and removes users from a given
    group.
 .
 Adding users with 'adduser' is much easier than adding them manually.
 Adduser will choose appropriate UID and GID values, create a home
 directory, copy skeletal user configuration, and automate setting
 initial values for the user's password, real name and so on.
 .
 Deluser can back up and remove users' home directories
 and mail spool or all the files they own on the system.
 .
 A custom script can be executed after each of the commands.
 .
  Development mailing list:
    http://lists.alioth.debian.org/mailman/listinfo/adduser-devel/
Description-md5: 7965b5cd83972a254552a570bcd32c93
Multi-Arch: foreign
Homepage: http://alioth.debian.org/projects/adduser/
Bugs: https://bugs.launchpad.net/ubuntu/+filebug
Origin: Ubuntu
Supported: 5y
Task: minimal

EOF
    }
    let(:expected_packages) {
      PackagesScope.new(
        [
        ],
        package_system: "dpkg"
      )
    }
    subject {
      packages_inspector.inspect(filter)
    }

    before(:each) do
      allow(system).to receive(:has_command?).with("rpm").and_return(false)
      allow(system).to receive(:has_command?).with("dpkg").and_return(true)

      allow(system).to receive(:run_command).with("dpkg", "-l", any_args).and_return(dpkg_output)
      allow(system).to receive(:run_command).with("apt-cache", "show", any_args).
        and_return(apt_cache_output)
    end

    it "sets the proper package_system" do
      expect(subject.packages.package_system).to eq("dpkg")
    end

    it "inspects the packages" do
      expected = PackagesScope.new(
        [
          DpkgPackage.new(
            name: "accountsservice:amd64",
            version: "0:0.6.35-foo",
            release: "0ubuntu7.2",
            arch: "amd64",
            checksum: "e44935e8ff4d5c086500d4e956e0e852",
            vendor: "Ubuntu"
          ),
          DpkgPackage.new(
            name: "adduser",
            version: "3.113+nmu3ubuntu3",
            release: "",
            arch: "all",
            checksum: "98c532cd738cfce59d448ed96ea5c8e7",
            vendor: "Ubuntu"
          )
        ],
        package_system: "dpkg"
      )
      expect(subject.packages).to eq(expected)
    end
  end
end
