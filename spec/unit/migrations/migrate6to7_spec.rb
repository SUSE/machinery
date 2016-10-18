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
require File.join(Machinery::ROOT, "schema/migrations/migrate6to7")

describe Machinery::Migrate6To7 do
  initialize_system_description_factory_store

  let(:description_hash) {
    JSON.parse(<<-EOT)
      {
        "unmanaged_files": {
          "_attributes": {
            "extracted": true
          },
          "_elements": [
            {
              "name": "/etc/.pwd.lock",
              "type": "file",
              "user": "root",
              "group": "root",
              "size": 0,
              "mode": "600"
            },
            {
              "name": "/etc/ImageVersion",
              "type": "file",
              "user": "root",
              "group": "root",
              "size": 25,
              "mode": "644"
            }
          ]
        },
        "meta": {
          "format_version": 6
        }
      }
    EOT
  }
  let(:description_base) { system_description_factory_store.description_path("description") }

  before(:each) do
    migration = Machinery::Migrate6To7.new(description_hash, description_base)
    migration.migrate
  end

  it "ads the has_metadata attribute with the value of the extracted attribute" do
    expect(description_hash["unmanaged_files"]["_attributes"]["has_metadata"]).to be(true)
  end
end
