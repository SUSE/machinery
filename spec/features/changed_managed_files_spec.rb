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

RSpec.describe "Changed Managed Files", type: :feature do
  initialize_system_description_factory_store

  let(:store) { system_description_factory_store }

  before(:each) do
    Server.set :system_description_store, store
  end

  context "when showing a system description" do
    before(:each) do
      description
    end

    context "when changed managed files are empty" do
      let(:description) {
        create_test_description(
          extracted_scopes: ["empty_changed_managed_files"],
          name: "name",
          store: store,
          store_on_disk: true
        )
      }

      it "shows a message" do
        visit("/name")

        expect(find("#changed_managed_files_container")).
          to have_content("There are no changed managed files.")
      end
    end
  end
end
