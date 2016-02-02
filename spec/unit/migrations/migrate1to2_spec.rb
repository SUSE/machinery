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

require_relative "../spec_helper"
require File.join(Machinery::ROOT, "schema/migrations/migrate1to2")

describe Migrate1To2 do
  initialize_system_description_factory_store

  let(:description_hash) {
    JSON.parse(<<-EOT)
      {
        "config_files": [
          {
            "name": "/etc/default/grub",
            "package_name": "grub2",
            "package_version": "2.02~beta2",
            "status": "changed",
            "changes": [
              "mode",
              "md5"
            ],
            "user": "root",
            "group": "root",
            "mode": "600"
          },
          {
            "name": "/etc/postfix/main.cf",
            "package_name": "postfix",
            "package_version": "2.11.0",
            "status": "changed",
            "changes": [
              "md5"
            ],
            "user": "root",
            "group": "root",
            "mode": "644"
          }
        ],
        "changed_managed_files": [
          {
            "name": "/lib/mkinitrd/scripts/setup-done.sh",
            "package_name": "mkinitrd",
            "package_version": "2.4.2",
            "status": "changed",
            "changes": [
              "mode"
            ],
            "mode": "555",
            "user": "root",
            "group": "root"
          }
        ],
        "unmanaged_files": [
          {
            "name": "/boot/0xfcdaa824",
            "type": "file",
            "user": "root",
            "group": "root",
            "size": 0,
            "mode": "644"
          },
          {
            "name": "/root/.ssh/",
            "type": "dir",
            "user": "root",
            "group": "root",
            "size": 616,
            "mode": "700",
            "files": 2
          }
        ],
        "groups": [
          {
            "name": "+",
            "password": "",
            "users": []
          }
        ],
        "meta": {
          "format_version": 1
        }
      }
    EOT
  }
  let(:description_base) { system_description_factory_store.description_path("description") }

  it "sets the extracted flag to false if the files weren't extracted" do
    migration = Migrate1To2.new(description_hash, description_base)
    migration.migrate

    expect(description_hash["config_files"]["extracted"]).to be(false)
    expect(description_hash["changed_managed_files"]["extracted"]).to be(false)
    expect(description_hash["unmanaged_files"]["extracted"]).to be(false)
  end

  it "sets the extracted flag to true if the files were extracted" do
    [
      "config_files",
      "changed_managed_files",
      "unmanaged_files"
    ].each do |scope|
      FileUtils.mkdir_p(File.join(description_base, scope))
    end

    migration = Migrate1To2.new(description_hash, description_base)
    migration.migrate

    expect(description_hash["config_files"]["extracted"]).to be(true)
    expect(description_hash["changed_managed_files"]["extracted"]).to be(true)
    expect(description_hash["unmanaged_files"]["extracted"]).to be(true)
  end

  it "puts the old file list into the files attributes" do
    config_files = description_hash["config_files"]
    changed_managed_files = description_hash["changed_managed_files"]
    unmanaged_files = description_hash["unmanaged_files"]

    migration = Migrate1To2.new(description_hash, description_base)
    migration.migrate

    expect(description_hash["config_files"]["files"]).to match_array(config_files)
    expect(description_hash["changed_managed_files"]["files"]).to match_array(changed_managed_files)
    expect(description_hash["unmanaged_files"]["files"]).to match_array(unmanaged_files)
  end

  it "makes sure that NIS group placeholders have a GID" do
    expect(description_hash["groups"].first.has_key?("gid")).to be(false)

    migration = Migrate1To2.new(description_hash, description_base)
    migration.migrate

    expect(description_hash["groups"].first.has_key?("gid")).to be(true)
  end
end
