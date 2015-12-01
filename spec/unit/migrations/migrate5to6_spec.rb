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

require_relative "../spec_helper"
require File.join(Machinery::ROOT, "schema/migrations/migrate5to6.rb")

describe Migrate5To6 do
  initialize_system_description_factory_store

  let(:description_hash) {
    JSON.parse(<<-EOT)
      {
        "packages": [
          {
            "name": "aaa_base",
            "version": "13.1",
            "release": "16.17.1",
            "arch": "x86_64",
            "vendor": "openSUSE",
            "checksum": "542cc67d16b48ea0c37b32dfb02d913c"
          },
          {
            "name": "adjtimex",
            "version": "1.29",
            "release": "2.1.2",
            "arch": "x86_64",
            "vendor": "openSUSE",
            "checksum": "6fe8798263f38820e050b3912f41b2a4"
          },
          {
            "name": "autofs",
            "version": "5.0.7",
            "release": "19.1.1",
            "arch": "x86_64",
            "vendor": "openSUSE",
            "checksum": "4db96ab66a6398ae27ee24eb793659dd"
          }
        ],
        "changed_managed_files": {
          "extracted": true,
          "files": [
            {
              "name": "/etc/cron.daily/mdadm",
              "package_name": "mdadm",
              "package_version": "3.3",
              "status": "changed",
              "error_message": "foo error message",
              "changes": [
                "deleted"
              ],
              "type": "file"
            }
          ]
        },
        "config_files": {
          "extracted": true,
          "files": [
            {
              "name": "/etc/auto.master",
              "package_name": "autofs",
              "package_version": "5.0.7",
              "status": "changed",
              "changes": [
                "md5"
              ],
              "user": "root",
              "group": "root",
              "mode": "644",
              "type": "file"
            }
          ]
        },
        "unmanaged_files": {
          "extracted": true,
          "files": [
            {
              "name": "/boot/backup_mbr2",
              "type": "file"
            }
          ]
        },
        "services": {
          "init_system": "systemd",
          "services": [
            {
              "name": "mysql.service",
              "state": "enabled"
            }
          ]
        },
        "users": [
          {
            "name": "the_element",
            "password": "x",
            "uid": 1,
            "gid": 1,
            "comment": "bin",
            "home": "/bin",
            "shell": "/bin/bash",
            "encrypted_password": "*",
            "last_changed_date": 16563
          }
        ],
        "groups": [
          {
            "name": "the_element",
            "password": "x",
            "gid": 17,
            "users": [

            ]
          }
        ],
        "patterns": [
          {
            "name": "the_element",
            "version": "20141007",
            "release": "2.1"
          }
        ],
        "repositories": [
          {
            "package_manager": "zypp",
            "alias": "download.opensuse.org-oss",
            "name": "download.opensuse.org-oss",
            "type": "yast2",
            "url": "http://download.opensuse.org/distribution/13.1/repo/oss/",
            "enabled": true,
            "autorefresh": true,
            "gpgcheck": true,
            "priority": 99
          },
          {
            "package_manager": "zypp",
            "alias": "download.opensuse.org-update",
            "name": "download.opensuse.org-update",
            "type": "rpm-md",
            "url": "http://download.opensuse.org/update/13.1/",
            "enabled": true,
            "autorefresh": true,
            "gpgcheck": true,
            "priority": 99
          }
        ],
        "meta": {
          "format_version": 5
        }
      }
    EOT
  }
  let(:description_yum_hash) {
    JSON.parse(<<-EOT)
      {
        "repositories": [
          {
            "package_manager": "yum",
            "name": "Red Hat Enterprise Linux 6Server - x86_64 - Source",
            "url": "ftp://ftp.redhat.com/pub/redhat/linux/enterprise/6Server/en/os/SRPMS/",
            "enabled": false,
            "alias": "rhel-source",
            "gpgcheck": true,
            "type": "rpm-md"
          },
        ],
        "meta": {
          "format_version": 5
        }
      }
    EOT
  }
  let(:description_base) { system_description_factory_store.description_path("description") }

  before(:each) do
    migration = Migrate5To6.new(description_hash, description_base)
    migration.migrate
  end

  describe "packages" do
    it "adds the 'package_system' attribute" do
      expect(description_hash["packages"]["_attributes"]["package_system"]).to eq("rpm")
    end

    it "moves the packages to packages" do
      package_names = description_hash["packages"]["_elements"].map do |package|
        package["name"]
      end
      expect(package_names).to eq(["aaa_base", "adjtimex", "autofs"])
    end
  end

  describe "repositories" do
    it "adds the 'repository_system' attribute" do
      expect(description_hash["repositories"]["_attributes"]["repository_system"]).to eq("zypp")
    end

    it "moves the repositories to repositories" do
      repository_names = description_hash["repositories"]["_elements"].map do |repository|
        repository["name"]
      end
      expect(repository_names).to eq(["download.opensuse.org-oss", "download.opensuse.org-update"])
    end

    it "removes the package_manager type" do
      expect(description_hash["repositories"]["_elements"].first["package_manager"]).to be(nil)
    end
  end

  ["changed_managed_files", "config_files", "unmanaged_files"].each do |scope|
    describe scope do
      it "moves the 'extracted' attribute" do
        expect(description_hash[scope]["_attributes"]["extracted"]).to eq(true)
      end
      it "moves the 'files' array" do
        expect(description_hash[scope]["_elements"].length).to eq(1)
      end
    end
  end

  ["changed_managed_files", "config_files"].each do |scope|
    it "moves the 'changes' array" do
      expect(description_hash[scope]["_elements"][0]["changes"]["_elements"].length).to eq(1)
    end
  end

  it "migrates the services scope" do
    expect(description_hash["services"]["_elements"].first["name"]).to eq("mysql.service")
    expect(description_hash["services"]["_attributes"]["init_system"]).to eq("systemd")
  end

  ["users", "groups", "patterns"].each do |scope|
    it "migrates #{scope}" do
      expect(description_hash[scope]["_elements"].first["name"]).to eq("the_element")
    end
  end
end
