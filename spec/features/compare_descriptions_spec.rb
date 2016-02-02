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

require_relative "feature_spec_helper"

RSpec::Steps.steps "Comparing two system descriptions in HTML format", type: :feature do
  before(:all) do
    Server.set :system_description_store, SystemDescriptionStore.new(
      File.join(Machinery::ROOT, "spec/data/descriptions/jeos/"))
  end

  it "opens the page" do
    visit("/compare/opensuse131/opensuse132")
    expect(page).to have_content("Comparing 'opensuse131' with 'opensuse132'")
  end

  it "shows the comparison" do
    within("#packages_container") do
      find("tr", text: "DirectFB 1.6.3 4.1.3")
      expect(page).to have_content("aaa_base (version: 13.1 ↔ 13.2+git20140911.61c1681)")
    end
  end

  it "collapses and expands scopes" do
    within("#packages_container") do
      find(".toggle").click
      expect(page).to have_no_selector(".scope_content table")

      find(".toggle").click
      expect(page).to have_selector(".scope_content table")
    end
  end

  it "expands a collapsed scope if both is clicked" do
    # Note: this reload is a workaround for some poltergeist/phantomjs issue with scrolling to
    # anchors
    visit("/compare/opensuse131/opensuse132")

    within(".scope-navigation") do
      find_link("G").click
    end

    within("#groups_container") do
      expect(page).to have_selector(".scope_content table")
      find(".toggle").trigger("click")
      expect(page).to have_no_selector(".scope_content table")
      expect(page).to have_no_selector(".hide-common-elements")

      find(".show-common-elements").trigger("click")
      expect(page).to have_selector(".scope_content table")
      expect(page).to have_selector(".hide-common-elements")
    end
  end

  it "expands a collapsed scope if `changed` is clicked" do
    # Note: this reload is a workaround for some poltergeist/phantomjs issue with scrolling to
    # anchors
    visit("/compare/opensuse131/opensuse132")

    within(".scope-navigation") do
      find_link("G").click
    end

    within("#groups_container") do
      expect(page).to have_selector(".scope_content table")
      find(".toggle").trigger("click")
      expect(page).to have_no_selector(".scope_content table")

      find(".show-changed-elements").trigger("click")
      expect(page).to have_selector(".scope_content table")
    end
  end
end
