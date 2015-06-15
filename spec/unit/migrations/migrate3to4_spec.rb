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
require File.join(Machinery::ROOT, "schema/migrations/migrate3to4")

describe Migrate3To4 do
  initialize_system_description_factory_store

  let(:description_hash) {
    JSON.parse(<<-EOT)
      {
        "changed_managed_files": {
          "extracted": false,
          "files": [
            {
              "name": "/etc/deleted",
              "package_name": "mdadm",
              "package_version": "3.3",
              "status": "changed",
              "changes": [
                "deleted"
              ]
            },
            {
              "name": "/etc/file",
              "package_name": "mdadm",
              "package_version": "3.3",
              "status": "changed",
              "changes": ["md5", "size"],
              "user": "user",
              "group": "group",
              "mode": "644"
            },
            {
              "name": "/etc/dir/",
              "package_name": "mdadm",
              "package_version": "3.3",
              "status": "changed",
              "changes": ["group"],
              "user": "user",
              "group": "group",
              "mode": "644"
            }
          ]
        },
        "config_files": {
          "extracted": true,
          "files": [
            {
              "name": "/etc/deleted config",
              "package_name": "mdadm",
              "package_version": "3.3",
              "status": "changed",
              "changes": [
                "deleted"
              ]
            },
            {
              "name": "/etc/file",
              "package_name": "cron",
              "package_version": "4.1",
              "status": "changed",
              "changes": ["md5"],
              "user": "root",
              "group": "root",
              "mode": "644"
            },
            {
              "name": "/etc/dir/",
              "package_name": "mdadm",
              "package_version": "3.3",
              "status": "changed",
              "changes": ["group"],
              "user": "user",
              "group": "group",
              "mode": "755"
            }
          ]
        },
        "meta": {
          "format_version": 3
        }
      }
    EOT
  }
  let(:description_base) { system_description_factory_store.description_path("description") }

  describe "when the scopes were extracted" do
    before(:each) do
      FileUtils.mkdir_p(File.join(description_base, "config_files", "etc", "dir"))
      FileUtils.mkdir_p(File.join(description_base, "config_files", "empty"))
      FileUtils.touch(File.join(description_base, "config_files", "etc", "file"))
      FileUtils.mkdir_p(File.join(description_base, "changed_managed_files", "etc", "dir"))
      FileUtils.mkdir_p(File.join(description_base, "changed_managed_files", "empty"))
      FileUtils.touch(File.join(description_base, "changed_managed_files", "etc", "file"))

      migration = Migrate3To4.new(description_hash, description_base)
      migration.migrate
    end

    it "removes empty directories" do
      expect(File.exists?(File.join(description_base, "config_files", "empty"))).to be(false)
      expect(File.exists?(File.join(description_base, "changed_managed_files", "empty"))).
        to be(false)
    end

    it "adds type entries to config and changed-managed files" do
      expect(description_hash["config_files"]["files"][0]["type"]).to be(nil)
      expect(description_hash["config_files"]["files"][1]["type"]).to eq("file")
      expect(description_hash["config_files"]["files"][2]["type"]).to eq("dir")

      expect(description_hash["changed_managed_files"]["files"][0]["type"]).to be(nil)
      expect(description_hash["changed_managed_files"]["files"][1]["type"]).to eq("file")
      expect(description_hash["changed_managed_files"]["files"][2]["type"]).to eq("dir")
    end
  end

  describe "when the scopes were not extracted" do
    before(:each) do
      migration = Migrate3To4.new(description_hash, description_base)
      migration.migrate
    end

    it "adds type entries to config and changed-managed files" do
      expect(description_hash["config_files"]["files"][0]["type"]).to be(nil)
      expect(description_hash["config_files"]["files"][1]["type"]).to eq("file")
      expect(description_hash["config_files"]["files"][2]["type"]).to eq("dir")

      expect(description_hash["changed_managed_files"]["files"][0]["type"]).to be(nil)
      expect(description_hash["changed_managed_files"]["files"][1]["type"]).to eq("file")
      expect(description_hash["changed_managed_files"]["files"][2]["type"]).to eq("dir")
    end
  end
end
