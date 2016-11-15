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
require File.join(Machinery::ROOT, "schema/migrations/migrate7to8")

describe Machinery::Migrate7To8 do
  initialize_system_description_factory_store

  let(:description_hash) {
    JSON.parse(<<-EOT)
      {
        "config_files": {
          "_attributes": {
            "extracted": true
          },
          "_elements": [
            {
              "name": "/etc/crontab",
              "package_name": "cronie",
              "package_version": "1.4.12",
              "status": "changed",
              "changes": [
                "md5"
              ],
              "user": "root",
              "group": "root",
              "mode": "600"
            }
          ]
        },
        "meta": {
          "format_version": 7,
          "config_files": {
            "modified": "2014-12-04T14:57:58Z",
            "hostname": "localhost"
          }
        }
      }
    EOT
  }
  let(:description_base) { system_description_factory_store.description_path("description") }

  it "renames the config_files extraction directory to changed_config_files" do
    FileUtils.mkdir_p(File.join(description_base, "config_files"))

    migration = Machinery::Migrate7To8.new(description_hash, description_base)
    migration.migrate

    expect(File.directory?(File.join(description_base, "config_files"))).to be(false)
    expect(File.directory?(File.join(description_base, "changed_config_files"))).to be(true)
  end

  it "renames the config_file_diffs to changed_config_files_diffs" do
    FileUtils.mkdir_p(File.join(description_base, "analyze", "config_file_diffs"))

    migration = Machinery::Migrate7To8.new(description_hash, description_base)
    migration.migrate

    expect(
      File.directory?(File.join(description_base, "analyze", "config_file_diffs"))
    ).to be(false)
    expect(
      File.directory?(File.join(description_base, "analyze", "changed_config_files_diffs"))
    ).to be(true)
  end

  context "renames the config_files scope to changed_config_files" do
    before(:each) do
      migration = Machinery::Migrate7To8.new(description_hash, description_base)
      migration.migrate
    end

    it "in inspection data" do
      expect(description_hash["config_files"]).to be(nil)
      expect(description_hash["changed_config_files"]).not_to be(nil)
    end

    it "in meta data" do
      expect(description_hash["meta"]["config_files"]).to be(nil)
      expect(description_hash["meta"]["changed_config_files"]).not_to be(nil)
    end
  end
end
