# Copyright (c) 2013-2015 SUSE LLC
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

RSpec::Steps.steps "Showing a system description in HTML format", type: :feature do
  before(:all) do
    Server.set :system_description_store, SystemDescriptionStore.new(
      File.join(Machinery::ROOT, "spec/data/descriptions/jeos/"))
  end

  it "opens the page" do
    visit("/opensuse131")
    expect(page.status_code).to eq(200)
  end

  it "renders the package list" do
    within("#packages_container") do
      find("tr", text: "DirectFB 1.6.3 4.1.3")
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
end
