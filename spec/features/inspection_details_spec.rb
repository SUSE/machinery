# Copyright (c) 2015 SUSE LLC
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
require_relative "feature_spec_helper"

RSpec.describe "Inspection Details", type: :feature do
  initialize_system_description_factory_store

  let(:store) { system_description_factory_store }
  let(:description) {
    create_test_description(
      store: store,
      store_on_disk: true,
      json: json
    )
  }

  before(:each) do
    description
    Server.set :system_description_store, store
  end

  context "when no filters where applied at the time of inspection" do
    let(:json) { <<-EOF
      {
        "environment": {
          "locale": "en_US.utf8"
        },
        "meta": {
          "format_version": 5,
          "filters": {
            "inspect": []
          }
        }
      }
      EOF
    }
    it "displays all used filters" do
      visit("/description")

      click_on("(inspection details)")

      expect(find("#filters")).to have_content("Filters used during Inspection")
      expect(find("#filters")).to have_content("No filters were used.")
    end
  end

  context "when filters where applied at the time of inspection" do
    let(:json) { <<-EOF
      {
        "environment": {
          "locale": "en_US.utf8"
        },
        "meta": {
          "format_version": 5,
          "filters": {
            "inspect": [
              "/unmaanged_files/files/name=/etc/passwd"
            ]
          }
        }
      }
      EOF
    }
    it "displays all used filters" do
      visit("/description")

      click_on("(inspection details)")

      expect(find("#filters")).to have_content("Filters used during Inspection")
      expect(find("#filters")).to have_content("/unmaanged_files/files/name=/etc/passwd")
    end
  end

end
