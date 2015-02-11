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
require File.join(Machinery::ROOT, "schema/migrations/migrate2to3")

describe Migrate2To3 do
  initialize_system_description_factory_store

  let(:description_hash) {
    JSON.parse(<<-EOT)
      {
        "config_files": {
          "extracted": true,
          "files": [
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
        "repositories": [
          {
            "alias": "download.opensuse.org-oss",
            "name": "Main Repository (OSS)",
            "type": "yast2",
            "url": "http://download.opensuse.org/distribution/13.2/repo/oss/",
            "enabled": true,
            "autorefresh": true,
            "gpgcheck": true,
            "priority": 99
          }
        ],
        "meta": {
          "format_version": 2
        }
      }
    EOT
  }
  let(:description_base) { system_description_factory_store.description_path("description") }

  it "moves config-file-diffs to analyze/config_file_diffs" do
    FileUtils.mkdir_p(File.join(description_base, "config-file-diffs", "etc"))

    migration = Migrate2To3.new(description_hash, description_base)
    migration.migrate

    expect(
      File.directory?(File.join(description_base, "analyze", "config_file_diffs", "etc"))
    ).to be(true)
  end

  it "adds zypp as package_manager attribute to repositories" do
    expected_hash = {
      "alias" => "download.opensuse.org-oss",
      "name" => "Main Repository (OSS)",
      "type" => "yast2",
      "url" => "http://download.opensuse.org/distribution/13.2/repo/oss/",
      "enabled" => true,
      "autorefresh" => true,
      "gpgcheck" => true,
      "priority" => 99,
      "package_manager" => "zypp"
    }
    migration = Migrate2To3.new(description_hash, description_base)
    migration.migrate

    expect(description_hash["repositories"].first).to eq(expected_hash)
  end
end
