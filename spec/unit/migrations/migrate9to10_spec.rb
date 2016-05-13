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
require File.join(Machinery::ROOT, "schema/migrations/migrate9to10")

describe Migrate9To10 do
  initialize_system_description_factory_store

  let(:description_hash) {
    JSON.parse(<<-EOT)
      {
        "unmanaged_files": {
          "_attributes": {
            "extracted": false,
            "has_metadata": true
          },
          "_elements": [
            {
              "name": "/etc/tarball with spaces/",
              "type": "dir",
              "user": "root",
              "group": "root",
              "size": 12345,
              "mode": "755",
              "files": 16
            }
          ]
        },
        "meta": {
          "format_version": 9,
          "unmanaged_files": {
            "modified": "2014-12-04T14:57:58Z",
            "hostname": "localhost"
          }
        }
      }
    EOT
  }
  let(:description_hash_without_meta_data) {
    JSON.parse(<<-EOT)
      {
        "unmanaged_files": {
          "_attributes": {
            "extracted": false,
            "has_metadata": false
          },
          "_elements": [
            {
              "name": "/etc/tarball with spaces/",
              "type": "dir"
            }
          ]
        },
        "meta": {
          "format_version": 9,
          "unmanaged_files": {
            "modified": "2014-12-04T14:57:58Z",
            "hostname": "localhost"
          }
        }
      }
    EOT
  }
  let(:description_base) { system_description_factory_store.description_path("description") }

  it "renames the attribute 'files' of unmanaged dirs to 'file_objects'" do
    migration = Migrate9To10.new(description_hash, description_base)
    migration.migrate

    expect(description_hash["unmanaged_files"]["_elements"].first["file_objects"]).to eq(16)
    expect(description_hash["unmanaged_files"]["_elements"].first.key?("files")).to be(false)
  end

  it "does not change unmanaged files without meta data" do
    original = Marshal.load(Marshal.dump(description_hash_without_meta_data))
    migration = Migrate9To10.new(description_hash_without_meta_data, description_base)
    migration.migrate
    expect(original).to eq(description_hash_without_meta_data)
  end
end
