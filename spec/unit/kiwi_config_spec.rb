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

describe KiwiConfig do
  include FakeFS::SpecHelpers

  let(:name) { "name" }
  let(:store) { SystemDescriptionStore.new("/.machinery") }
  let(:empty_system_description) { SystemDescription.new }
  let(:system_description_with_content) {
    json = <<-EOF
      {
        "packages": [
          {
            "name": "kernel-desktop",
            "version": "3.7.10",
            "release": "1.0"
          },
          {
            "name": "kernel-desktop-base",
            "version": "3.7.10",
            "release": "1.0"
          }
        ],
        "repositories": [
          {
            "alias": "nodejs_alias",
            "name": "nodejs",
            "type": "rpm-md",
            "url": "http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/",
            "enabled": true,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 1
          },
          {
            "alias": "openSUSE-13.1-1.7_alias",
            "name": "openSUSE-13.1-1.7",
            "type": "yast2",
            "url": "cd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0",
            "enabled": false,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 2
          },
          {
            "alias": "repo_without_type_alias",
            "name": "repo_without_type",
            "type": null,
            "url": "http://repo_without_type",
            "enabled": true,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 3
          },
          {
            "alias": "disabled_repo_alias",
            "name": "disabled_repo",
            "type": null,
            "url": "http://disabled_repo",
            "enabled": false,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 3
          },
          {
            "alias": "autorefresh_enabled_alias",
            "name": "autorefresh_enabled",
            "type": null,
            "url": "http://autorefreshed_repo",
            "enabled": true,
            "autorefresh": true,
            "gpgcheck": true,
            "priority": 2
          },
          {
            "alias": "dvd_entry_alias",
            "name": "dvd_entry",
            "type": "yast2",
            "url": "dvd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0",
            "enabled": true,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 2
          },
          {
            "alias": "NCCRepo",
            "name": "NCC Repository",
            "type": "yast2",
            "url": "https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-x86_64?credentials=NCCcredentials",
            "enabled": true,
            "autorefresh": true,
            "gpgcheck": true,
            "priority": 2
          }
        ],
        "patterns" : [
          {
            "name": "Minimal",
            "version": "11",
            "release": "38.44.33"
          }
        ],
        "users": [
          {
            "name":               "root",
            "password":           "x",
            "uid":                0,
            "gid":                0,
            "comment":            "root",
            "home":               "/root",
            "shell":              "/bin/bash",
            "encrypted_password": "$1$Qf2FvbHa$sQCyvYhJKsCqAoTcK21eN1",
            "last_changed_date":  16125
          },
          {
            "name":               "lp",
            "password":           "x",
            "uid":                4,
            "gid":                7,
            "comment":            "Printing daemon",
            "home":               "/var/spool/lpd",
            "shell":              "/bin/false",
            "encrypted_password": "*",
            "last_changed_date":  16125,
            "min_days":           1,
            "max_days":           2,
            "warn_days":          3,
            "disable_days":       4,
            "disabled_date":      5
          }
        ],
        "groups": [
          {
            "name": "root",
            "password": "x",
            "gid": 0,
            "users": []
          },
          {
            "name": "tftp",
            "password": "x",
            "gid": 7,
            "users": ["dnsmasq", "tftp"]
          }
        ],
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP3",
          "architecture": "x86_64"
        }
      }
    EOF
    SystemDescription.from_json(name, json, store)
  }

  let(:system_description_with_sysvinit_services) {
    json = <<-EOF
      {
        "packages": [
          {
            "name": "kernel-desktop-base",
            "version": "3.7.10",
            "release": "1.0"
          }
        ],
        "repositories": [
          {
            "alias": "nodejs_alias",
            "name": "nodejs",
            "type": "rpm-md",
            "url": "http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/",
            "enabled": true,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 1
          }
        ],
        "services": {
          "init_system": "sysvinit",
          "services": [
            {
              "name": "autoyast",
              "state": "off"
            },
            {
              "name": "setserial",
              "state": "on"
            }
          ]
        },
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP3",
          "architecture": "x86_64"
        }

      }
    EOF
    SystemDescription.from_json(name, json, store)
  }

  let(:system_description_with_systemd_services) {
    json = <<-EOF
      {
        "packages": [
          {
            "name": "kernel-desktop-base",
            "version": "3.7.10",
            "release": "1.0"
          }
        ],
        "repositories": [
          {
            "alias": "nodejs_alias",
            "name": "nodejs",
            "type": "rpm-md",
            "url": "http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/",
            "enabled": true,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 1
          }
        ],
        "services": {
          "init_system": "systemd",
          "services": [
            {
              "name": "network.service",
              "state": "enabled"
            },
            {
              "name": "kexec-load.service",
              "state": "disabled"
            },
            {
              "name": "ldconfig.service",
              "state": "masked"
            },
            {
              "name": "static.service",
              "state": "static"
            },
            {
              "name": "linked.service",
              "state": "linked"
            },
            {
              "name": "enabled_runtime.service",
              "state": "enabled-runtime"
            },
            {
              "name": "linked_runtime.service",
              "state": "linked-runtime"
            },
            {
              "name": "masked_runtime.service",
              "state": "masked-runtime"
            }
          ]
        },
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP3",
          "architecture": "x86_64"
        }
      }
    EOF
    SystemDescription.from_json(name, json, store)
  }

  let(:system_description_with_modified_files) {
    json = <<-EOF
      {
        "packages": [
          {
            "name": "kernel-desktop-base",
            "version": "3.7.10",
            "release": "1.0"
          }
        ],
        "repositories": [
          {
            "alias": "nodejs_alias",
            "name": "nodejs",
            "type": "rpm-md",
            "url": "http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/",
            "enabled": true,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 1
          }
        ],
        "config_files": [
          {
            "name": "/usr/share/fonts/encodings/encodings.dir",
            "package_name": "xorg-x11-fonts-core",
            "package_version": "7.4",
            "changes": [
              "md5"
            ],
            "uid": 0,
            "gid": 0,
            "user": "user",
            "group": "group",
            "mode": "644"
          },
          {
            "name": "/etc/inittab",
            "package_name": "aaa_base",
            "package_version": "11",
            "changes": [
              "md5"
            ],
            "uid": 0,
            "gid": 0,
            "user": "root",
            "group": "root",
            "mode": "644"
          },
          {
            "name": "/tmp/deleted_config",
            "package_name": "aaa_base",
            "package_version": "11",
            "changes": [
              "deleted"
            ]
          }
        ],
        "changed_managed_files": [
          {
            "name": "/tmp/managed/one",
            "package_name": "xorg-x11-fonts-core",
            "package_version": "7.4",
            "status": "changed",
            "changes": [
              "md5"
            ],
            "uid": 0,
            "gid": 0,
            "user": "user",
            "group": "group",
            "mode": "644"
          },
          {
            "name": "/var/managed_two",
            "package_name": "aaa_base",
            "package_version": "11",
            "status": "changed",
            "changes": [
              "md5"
            ],
            "uid": 0,
            "gid": 0,
            "user": "root",
            "group": "root",
            "mode": "644"
          },
          {
            "name": "/tmp/deleted_changed_managed",
            "package_name": "aaa_base",
            "package_version": "11",
            "status": "changed",
            "changes": [
              "deleted"
            ]
          }
        ],
        "unmanaged_files": [
          {
            "name": "/boot/backup_mbr",
            "type": "file",
            "user": "root",
            "group": "root",
            "size": 512,
            "mode": "644"
          }
        ],
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP3",
          "architecture": "x86_64"
        }
      }
    EOF
    SystemDescription.from_json(name, json, store)
  }

  before(:each) do
    FakeFS::FileSystem.clone(File.join(Machinery::ROOT, "kiwi_helpers"))
    ["config_files", "changed_managed_files", "unmanaged_files"].each do |scope|
      system_description_with_content.initialize_file_store(scope)
    end
  end

  describe "#initialize" do
    it "raises exception when OS is not supported for building" do
      system_description_with_content.os.name = "openSUSE 13.1 (Bottle)"
      expect {
        KiwiConfig.new(system_description_with_content)
      }.to raise_error(
         Machinery::Errors::KiwiExportFailed,
         /openSUSE 13.1/
      )
    end

    it "applies the packages to the kiwi config" do
      config = KiwiConfig.new(system_description_with_content)

      users = config.xml.xpath("/image/users/user")
      expect(users.count).to eq(1)
      expect(users[0].attr("home")).to eq("/root")
      packages = config.xml.xpath("/image/packages/package")
      expect(packages.count).to eq(2)
      expect(packages[0].attr("name")).to eq("kernel-desktop")
      expect(packages[1].attr("name")).to eq("kernel-desktop-base")
    end

    it "applies the patterns to the kiwi config" do
      config = KiwiConfig.new(system_description_with_content)
      patterns = config.xml.xpath("/image/packages/namedCollection")

      expect(patterns.count).to eq(1)
      expect(patterns[0].attr("name")).to eq("Minimal")
    end

    it "applies the repositories to the kiwi config" do
      config = KiwiConfig.new(system_description_with_content)

      repositories = config.xml.xpath("/image/repository")

      # enabled web based repositories go to config.xml if they have a type
      expect(repositories.count).to eq(2)
      expect(repositories[0].attr("type")).to eq("rpm-md")
      expect(repositories[0].children[0].attr("path")).to \
        eq("http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/")
      expect(repositories[0].attr("priority")).to eq("1")

      # all repositories go to config.sh
      expect(config.sh.scan(/zypper -n ar/).count).to eq(6)
      expect(config.sh.scan(/zypper -n mr/).count).to eq(6)

      expect(config.sh).to include("zypper -n ar --name='nodejs' --type='rpm-md' 'http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/' 'nodejs_alias'\n")
      expect(config.sh).to include("zypper -n mr --priority=1 'nodejs'\n")
      expect(config.sh).to include("zypper -n ar --name='openSUSE-13.1-1.7' --type='yast2' --disable 'cd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0' 'openSUSE-13.1-1.7_alias'\n")
      expect(config.sh).to include("zypper -n mr --priority=2 'openSUSE-13.1-1.7'\n")

      # repositories without a type have no "--type" option
      expect(config.sh).to include("zypper -n ar --name='repo_without_type' 'http://repo_without_type' 'repo_without_type_alias'\n")

      # disabled repositories have a "--disabled" option
      expect(config.sh).to include("zypper -n ar --name='disabled_repo' --disable 'http://disabled_repo' 'disabled_repo_alias'\n")

      # autorefreshed repositories have a "--refresh" option
      expect(config.sh).to include("zypper -n ar --name='autorefresh_enabled' --refresh 'http://autorefreshed_repo' 'autorefresh_enabled_alias'\n")

      # NCC repositories are not added to the system, just used for building
      expect(config.sh).not_to include("https://nu.novell.com/")
    end

    it "applies sysvinit services to kiwi config" do
      config = KiwiConfig.new(system_description_with_sysvinit_services)

      expect(config.sh).to include("chkconfig setserial on\n")
      expect(config.sh).to include("chkconfig autoyast off\n")
    end

    it "writes a proper description" do
      config = KiwiConfig.new(system_description_with_sysvinit_services)

      author = config.xml.xpath("/image/description/author").children.text
      contact = config.xml.xpath("/image/description/contact").children.text
      specification = config.xml.xpath("/image/description/specification").children.text

      expect(author).to eq("Machinery")
      expect(contact).to eq("")
      expect(specification).to eq("Description of system 'name' exported by Machinery")
    end

    it "applies systemd services to kiwi config" do
      config = KiwiConfig.new(system_description_with_systemd_services)

      expect(config.sh).to include("systemctl enable network")
      expect(config.sh).to include("systemctl disable kexec-load")
      expect(config.sh).to include("systemctl mask ldconfig")

      # static, linked and *runtime states should be ignored
      expect(config.sh).not_to match(/systemctl static /)
      expect(config.sh).not_to match(/systemctl linked /)
      expect(config.sh).not_to match(/systemctl \w+-runtime /)
    end

    it "raises an error if the systemd service state is unknown" do
      system_description_with_systemd_services.services.services.first["state"] = "not_known"
      expect {
        KiwiConfig.new(system_description_with_systemd_services)
      }.to raise_error(Machinery::Errors::KiwiExportFailed, /not_known/)
    end

    it "sets the target distribution and bootloader for SLES11" do
      expect(system_description_with_content.os.name).to include("Server 11")
      config = KiwiConfig.new(system_description_with_content)
      type_node = config.xml.xpath("/image/preferences/type")[0]

      expect(type_node["boot"]).to eq("vmxboot/suse-SLES11")
      expect(type_node["bootloader"]).to eq("grub")
    end

    it "sets the target distribution and bootloader for SLES12" do
      system_description_with_content.os.name = "SUSE Linux Enterprise Server 12"
      config = KiwiConfig.new(system_description_with_content)
      type_node = config.xml.xpath("/image/preferences/type")[0]

      expect(type_node["boot"]).to eq("vmxboot/suse-SLES12")
      expect(type_node["bootloader"]).to eq("grub2")
    end

    it "sets the image format to qcow2" do
      config = KiwiConfig.new(system_description_with_content)
      type_node = config.xml.xpath("/image/preferences/type")[0]

      expect(type_node["format"]).to eq("qcow2")
    end

    it "throws an error if changed config files are part of the system description but don't exist on the filesystem" do
      scope = "config_files"
      system_description_with_modified_files.remove_file_store(scope)
      expect {
        KiwiConfig.new(system_description_with_modified_files)
      }.to raise_error(Machinery::Errors::SystemDescriptionError,
        /#{Cli.internal_to_cli_scope_names(scope).join(",")}/)
    end

    it "throws an error if changed managed files are part of the system description but don't exist on the filesystem" do
      scope = "changed_managed_files"
      system_description_with_modified_files.remove_file_store(scope)
      expect {
        KiwiConfig.new(system_description_with_modified_files)
      }.to raise_error(Machinery::Errors::SystemDescriptionError,
        /#{Cli.internal_to_cli_scope_names(scope).join(",")}/)
    end

    it "throws an error if unmanaged files are part of the system description but don't exist on the filesystem" do
      scope = "unmanaged_files"
      system_description_with_modified_files.remove_file_store(scope)
      expect {
        KiwiConfig.new(system_description_with_modified_files)
      }.to raise_error(Machinery::Errors::SystemDescriptionError,
        /#{Cli.internal_to_cli_scope_names(scope).join(",")}/)
    end

    it "applies 'pre-process' config" do
      config = KiwiConfig.new(
        system_description_with_content,
        enable_ssh: true
      )
      expect(config.sh).to include("suseInsertService sshd")
    end
  end

  describe "#write" do
    it "writes the config to the specified file" do
      config = KiwiConfig.new(system_description_with_content)

      location = "/tmp/some/path"
      expect(File).to receive(:write).
        with(File.join(location, "config.xml"),
          /<package name="kernel-desktop"\/>/
        )
      expect(File).to receive(:write).
        with(File.join(location, "config.sh"),
          /zypper -n ar.*repo_without_type/
        )
      allow(File).to receive(:write)

      config.write(location)
    end

    it "applies 'pre-process' config" do
      allow(File).to receive(:write)

      config = KiwiConfig.new(
          system_description_with_content,
          enable_ssh: true
      )
      config.write("/foo")

      expect(config.sh).to include("suseInsertService sshd")
    end

    it "applies 'post-process' config" do
      config = KiwiConfig.new(
          system_description_with_content,
          enable_dhcp: true
      )

      expect(config).to receive(:enable_dhcp)
      config.write("/foo")
    end

    it "enables dhcp on SLES11 with the enable_dhcp option" do
      allow($stdout).to receive(:puts)
      network_config = "/root/etc/sysconfig/network/ifcfg-eth0"

      config = KiwiConfig.new(
          system_description_with_content,
          enable_dhcp: true
      )
      config.write("/")

      expect(
        File.exists?("/root/etc/udev/rules.d/70-persistent-net.rules")
      ).to be(false)
      expect(File.exists?(network_config)).to be(true)

      expect(File.read(network_config)).to include("BOOTPROTO='dhcp'")
    end

    it "enables dhcp on SLES12 with the enable_dhcp option" do
      allow($stdout).to receive(:puts)
      network_config = "/root/etc/sysconfig/network/ifcfg-lan0"
      system_description_with_content.os.name = "SUSE Linux Enterprise Server 12"

      config = KiwiConfig.new(
          system_description_with_content,
          enable_dhcp: true
      )
      config.write("/")

      expect(
        File.exists?("/root/etc/udev/rules.d/70-persistent-net.rules")
      ).to be(true)
      expect(File.exists?(network_config)).to be(true)

      expect(File.read(network_config)).to include("BOOTPROTO='dhcp'")
    end


    it "uses the name of the description as image name" do
      config = KiwiConfig.new(system_description_with_content)

      location = "/tmp/some/path"
      expect(File).to receive(:write).
        with(File.join(location, "config.xml"),
          /<image .* name="#{system_description_with_content.name}"/
        )
      allow(File).to receive(:write)

      config.write(location)
    end

    it "adds a readme to the kiwi export" do
      allow($stdout).to receive(:puts)

      config = KiwiConfig.new(
          system_description_with_content
      )
      config.write("/")

      expect(File.exists?("/README.md")).to be(true)

      expect(File.read("/README.md")).to include(
        "README for Kiwi export from Machinery"
      )
    end

    describe "with extracted files" do
      let(:config_1) { "/usr/share/fonts/encodings/encodings.dir" }
      let(:config_2) { "/etc/inittab" }
      let(:changed_managed_1) { "/tmp/managed/one" }
      let(:changed_managed_2) { "/var/managed_two" }
      let(:output_location) { "/tmp/some_path" }
      let(:config) { KiwiConfig.new(system_description_with_modified_files) }
      let(:manifest_path) { store.description_path(name) }

      before(:each) do
        # prepare fakefs
        [config_1, config_2].each do |file|
          FileUtils.mkdir_p(File.join(manifest_path, "config_files", File.dirname(file)))
          FileUtils.touch(File.join(manifest_path, "config_files", file))
        end

        [changed_managed_1, changed_managed_2].each do |file|
          FileUtils.mkdir_p(File.join(manifest_path, "changed_managed_files", File.dirname(file)))
          FileUtils.touch(File.join(manifest_path, "changed_managed_files", file))
        end

        FileUtils.mkdir_p(output_location)
      end

      it "copies the changed config files to the template root directory" do
        config.write(output_location)

        # expect config file attributes to be set via config.sh
        expect(config.sh.scan(/chmod/).count).to eq(4)
        expect(config.sh.scan(/chown/).count).to eq(4)
        expect(config.sh).to include("chmod 644 '#{config_1}'\n")
        expect(config.sh).to include("chown user:group '#{config_1}'\n")
        # expect config files to be stored in the template root directory
        expect(File.exists?(File.join(output_location, "root", config_1))).to be(true)
        expect(File.exists?(File.join(output_location, "root", config_2))).to be(true)
      end

      it "copies the changed managed files to the template root directory" do
        config.write(output_location)

        # expect config file attributes to be set via config.sh
        expect(config.sh).to include("chmod 644 '#{changed_managed_1}'\n")
        expect(config.sh).to include("chown user:group '#{changed_managed_1}'\n")

        # expect config files to be stored in the template root directory
        expect(File.exists?(File.join(output_location, "root", changed_managed_1))).to be(true)
        expect(File.exists?(File.join(output_location, "root", changed_managed_2))).to be(true)
      end

      it "copies the unmanaged files tarballs into the root directory" do
        FileUtils.mkdir_p(File.join(manifest_path, "unmanaged_files", "var", "log"))
        FileUtils.touch(File.join(manifest_path, "unmanaged_files", "var", "log", "news.tgz"))
        FileUtils.touch(File.join(manifest_path, "unmanaged_files", "files.tgz"))

        config.write(output_location)

        expect(File.exists?("/tmp/some_path/root/tmp/unmanaged_files/files.tgz")).to be(true)
        expect(File.exists?("/tmp/some_path/root/tmp/unmanaged_files/var/log/news.tgz")).to be(true)

        expect(config.sh).to match(/find \/tmp\/unmanaged_files.*tar/)

        # expect filter to be present
        expect(File.exists?("/tmp/some_path/root/tmp/unmanaged_files_build_excludes")).to be(true)
        expect(config.sh).to match(/tar.*-X '\/tmp\/unmanaged_files_build_excludes' /)
      end

      it "deletes deleted config and changed managed files" do
        expect(config.sh).to include("rm -rf '/tmp/deleted_config'")
        expect(config.sh).to include("rm -rf '/tmp/deleted_changed_managed'")
      end
    end

    it "generates a script for merging the users and groups" do
      config = KiwiConfig.new(system_description_with_content)

      location = "/tmp/some/path"
      FileUtils.mkdir_p(location)

      config.write(location)

      script_path = File.join(location, "root", "tmp", "merge_users_and_groups.pl")

      expect(config.sh).to include("perl /tmp/merge_users_and_groups.pl /etc/passwd /etc/shadow /etc/group")
      expect(File.exists?(script_path)).to be(true)

      script = File.read(script_path)
      expect(script).to include("['root:x:0:0:root:/root:/bin/bash', 'root:$1$Qf2FvbHa$sQCyvYhJKsCqAoTcK21eN1:16125::::::']")
      expect(script).to include("['lp:x:4:7:Printing daemon:/var/spool/lpd:/bin/false', 'lp:*:16125:1:2:3:4:5:']")
      expect(script).to include("'root:x:0:'")
      expect(script).to include("'tftp:x:7:dnsmasq,tftp'")
    end

    it "calls kiwi helpers" do
      config = KiwiConfig.new(system_description_with_content)

      location = "/tmp/some/path"
      FileUtils.mkdir_p(location)
      config.write(location)

      [
        "baseMount",
        "suseConfig",
        "suseSetupProduct",
        "suseImportBuildKey",
        "baseCleanMount"
      ].each do |helper|
        expect(config.sh).to include(helper)
      end
    end
  end
end
