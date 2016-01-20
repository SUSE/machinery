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

RSpec.describe "Alert Message", type: :feature do
  initialize_system_description_factory_store

  let(:store) { system_description_factory_store }

  before(:each) do
    Server.set :system_description_store, store
  end

  context "inside the landing page" do
    before(:each) do
      description
    end

    let(:description) {
      create_test_description(
        name:          "name",
        store:         store,
        store_on_disk: true,
        format_version: 1
      )
    }

    it "closes" do
      visit("/")

      expect(page.has_selector?("#alert_container")).to be_truthy

      within("#alert_container") do
        find(".dismiss").click
      end

      expect(page.has_selector?("#alert_container")).to be_falsy
    end
  end

  context "inside the compare view" do
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

    it "closes" do
      visit("/compare/description_a/description_b")

      expect(page.has_selector?("#alert_container")).to be_truthy

      within("#alert_container") do
        find(".dismiss").click
      end

      expect(page.has_selector?("#alert_container")).to be_falsy
    end
  end
end
