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

RSpec.describe "Scope Buttons", type: :feature do
  initialize_system_description_factory_store

  let(:store) { system_description_factory_store }

  before(:each) do
    Server.set :system_description_store, store
  end

  context "when scrolling down in show view" do
    before(:each) do
      description
    end

    let(:description) {
      create_test_description(
        scopes:        ["os", "packages", "repositories", "services"],
        name:          "name",
        store:         store,
        store_on_disk: true
      )
    }

    it "also move down" do
      visit("/name")

      within("#content_container") do
        coordinates_before = get_coordinates(".scope_logo_big:first-of-type")
        page.execute_script("window.scrollBy(0,10)")
        coordinates_after = get_coordinates(".scope_logo_big:first-of-type")
        expect(coordinates_before[0]).to eq(coordinates_after[0])
        expect(coordinates_before[1]).to eq(coordinates_after[1] + 10)
      end
    end
  end

  context "when scrolling down in compare view" do
    before(:each) do
      description_a
      description_b
    end

    let(:description_a) {
      create_test_description(
        scopes:        ["os", "packages", "repositories"],
        name:          "description_a",
        store:         store,
        store_on_disk: true
      )
    }
    let(:description_b) {
      create_test_description(
        scopes:        ["os", "packages", "repositories", "services"],
        name:          "description_b",
        store:         store,
        store_on_disk: true
      )
    }

    it "also move down" do
      visit("/compare/description_a/description_b")

      within("#content_container") do
        coordinates_before = get_coordinates(".scope_logo_big:first-of-type")
        page.execute_script("window.scrollBy(0,10)")
        coordinates_after = get_coordinates(".scope_logo_big:first-of-type")
        expect(coordinates_before[0]).to eq(coordinates_after[0])
        expect(coordinates_before[1]).to eq(coordinates_after[1] + 10)
      end
    end
  end
end
