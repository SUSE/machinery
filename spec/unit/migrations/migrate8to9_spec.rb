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
require File.join(Machinery::ROOT, "schema/migrations/migrate8to9")

describe Migrate8To9 do
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
          "format_version": 8,
          "config_files": {
            "modified": "2014-12-04T14:57:58Z",
            "hostname": "localhost"
          },
          "filters": {
            "inspect": [
              "/unmanaged_files/files/name=/etc/passwd",
              "/changed_config_files/files/name=/etc/sudoers",
              "/changed_managed_files/files/name=/bin/something",
              "/unmanaged_files/name=/tmp",
              "/services/services/name=ModemManager.service"
            ]
          }
        }
      }
    EOT
  }
  let(:description_base) { system_description_factory_store.description_path("description") }

  it "removes obsolete elements from filter path" do
    expected = [
      "/unmanaged_files/name=/etc/passwd",
      "/changed_config_files/name=/etc/sudoers",
      "/changed_managed_files/name=/bin/something",
      "/unmanaged_files/name=/tmp",
      "/services/name=ModemManager.service"
    ]
    migration = Migrate8To9.new(description_hash, description_base)
    migration.migrate

    expect(description_hash["meta"]["filters"]["inspect"]).to match_array(expected)
  end
end
