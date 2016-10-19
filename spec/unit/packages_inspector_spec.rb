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

describe Machinery::PackagesInspector, ".inspect" do
  let(:description) {
    Machinery::SystemDescription.new("systemname", Machinery::SystemDescriptionStore.new)
  }
  let(:filter) { nil }
  let(:system) {
    double(
      requires_root?: false,
      host: "example.com",
      check_requirement: nil
    )
  }
  let(:packages_inspector) { Machinery::PackagesInspector.new(system, description) }

  context "rpm inspection" do
    let(:package_example) {
      <<EOF
zypper|1.9.16|22.2|x86_64|openSUSE|4a87f6b9ceae5d40a411fe52d0f17050$
rpm|4.11.1|6.5.1|x86_64|openSUSE|7dfdd742a9b7d60c75bf4844d294716d$
EOF
    }
    let(:expected_packages) {
      Machinery::PackagesScope.new(
        [
          Machinery::RpmPackage.new(
            name: "rpm",
            version: "4.11.1",
            release: "6.5.1",
            arch: "x86_64",
            vendor: "openSUSE",
            checksum: "7dfdd742a9b7d60c75bf4844d294716d"
          ),
          Machinery::RpmPackage.new(
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
    let(:dpkg_output_lenny) {
      <<EOF
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Cfg-files/Unpacked/Failed-cfg/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Hold/Reinst-required/X=both-problems (Status,Err: uppercase=bad)
||/ Name                           Version                        Description
+++-==============================-==============================-============================================================================
ii  acpi                           1.1-2                          displays information on ACPI devices
ii  acpi-support-base              0.109-11                       scripts for handling base ACPI events such as the power button

EOF
    }
    let(:apt_cache_output) {
      <<EOF
Package: accountsservice
Status: install ok installed
Priority: optional
Section: admin
Installed-Size: 428
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Architecture: amd64
Version: 0.6.35-foo-0ubuntu7.2
Depends: dbus, libaccountsservice0 (= 0.6.35-0ubuntu7.2), libc6 (>= 2.4), libgcr-base-3-1 (>= 3.8.0), libglib2.0-0 (>= 2.37.3), libpam0g (>= 0.99.7.1), libpolkit-gobject-1-0 (>= 0.99)
Suggests: gnome-control-center
Conffiles:
 /etc/dbus-1/system.d/org.freedesktop.Accounts.conf 06247d62052029ead7d9ec1ef9457f42
 /etc/pam.d/accountsservice a9d93f9b24383a48cc01743d8185aa98
Description-en: query and manipulate user account information
 The AccountService project provides a set of D-Bus
 interfaces for querying and manipulating user account
 information and an implementation of these interfaces,
 based on the useradd, usermod and userdel commands.
Description-md5: 8aeed0a03c7cd494f0c4b8d977483d7e
Homepage: http://cgit.freedesktop.org/accountsservice/
Original-Maintainer: Alessio Treglia <alessio@debian.org>

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

    let(:apt_cache_output_lenny) {
      <<EOF
Package: acpi
Priority: optional
Section: utils
Installed-Size: 92
Maintainer: Debian Acpi Team <pkg-acpi-devel@lists.alioth.debian.org>
Architecture: amd64
Version: 1.1-2
Depends: libc6 (>= 2.7-1)
Filename: pool/main/a/acpi/acpi_1.1-2_amd64.deb
Size: 14906
MD5Sum: 4b6244862999c8eada941fed696e90b5
SHA1: 9394b51e62b2c279ea2bcc1c7c42ebfa3ca9f86a
SHA256: f9c81d00702609e98f2ca4c6eb2de68837adeaa53e7f9c8df1773fa5742b7b96
Description: displays information on ACPI devices
 Attempts to replicate the functionality of the 'old' apm command on
 ACPI systems, including battery and thermal information. Does not support
 ACPI suspending, only displays information about ACPI devices.
Tag: admin::power-management, hardware::power, hardware::power:acpi, interface::commandline, role::program, scope::utility, use::viewing
Task: laptop

Package: acpi-support-base
Priority: optional
Section: admin
Installed-Size: 88
Maintainer: Bart Samwel <bart@samwel.tk>
Architecture: all
Source: acpi-support
Version: 0.109-11
Replaces: acpi-support (<< 0.109-1)
Depends: acpid (>= 1.0.4), console-utilities
Suggests: acpi-support
Filename: pool/main/a/acpi-support/acpi-support-base_0.109-11_all.deb
Size: 22496
MD5Sum: 22b1b206b7ae9357b3f66f662d061e57
SHA1: 5a4e13cd6442776758e2a5b6518a7eeddd8cc5e2
SHA256: 9c5741ef039518eb78cdb5c7bc3e87d63b608027aa006e98491bc1fe2e26e74a
Description: scripts for handling base ACPI events such as the power button
 This package contains scripts to react to various base ACPI events
 such as the power button. For more extensive ACPI support, including support
 for suspend-to-RAM and for various laptop features, install the package
 "acpi-support".
Tag: admin::power-management, hardware::power, hardware::power:acpi, role::app-data, special::auto-inst-parts

EOF
    }
    let(:expected_packages) {
      Machinery::PackagesScope.new(
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
      expected = Machinery::PackagesScope.new(
        [
          Machinery::DpkgPackage.new(
            name: "accountsservice:amd64",
            version: "0:0.6.35-foo",
            release: "0ubuntu7.2",
            arch: "amd64",
            checksum: "",
            vendor: ""
          ),
          Machinery::DpkgPackage.new(
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

    context "on a Debian Lenny system" do
      it "inspects the packages" do
        allow(system).to receive(:run_command).with("dpkg", "-l", any_args)
          .and_return(dpkg_output_lenny)
        expect(system).to receive(:run_command).with(
          "apt-cache", "show", "acpi=1.1-2", "acpi-support-base=0.109-11", any_args
        ).and_raise(
          Cheetah::ExecutionFailed.new(
            nil,
            2,
            "",
            "W: Unable to locate package acpi=1.1-2\nE: No packages found"
          )
        )
        expect(system).to receive(:run_command).with(
          "apt-cache", "show", "acpi", "acpi-support-base", any_args
        ).and_return(apt_cache_output_lenny)

        expected = PackagesScope.new(
          [
            DpkgPackage.new(
              name: "acpi",
              version: "1.1",
              release: "2",
              arch: "amd64",
              checksum: "4b6244862999c8eada941fed696e90b5",
              vendor: ""
            ),
            DpkgPackage.new(
              name: "acpi-support-base",
              version: "0.109",
              release: "11",
              arch: "all",
              checksum: "22b1b206b7ae9357b3f66f662d061e57",
              vendor: ""
            )
          ],
          package_system: "dpkg"
        )
        expect(subject.packages).to eq(expected)
      end
    end
  end
end
