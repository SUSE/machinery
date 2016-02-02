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

RSpec::Steps.steps "Showing the landing page", type: :feature do
  before(:all) do
    Server.set :system_description_store, SystemDescriptionStore.new(
      File.join(Machinery::ROOT, "spec/data/descriptions/jeos/")
    )
  end

  it "opens the landing page" do
    visit("/")
    expect(page.status_code).to eq(200)
  end

  it "shows the table with all system descriptions" do
    within("#content_container") do
      find("th", text: "Last update")
    end
  end

  it "shows the table with system description opensuse131" do
    within("#content_container") do
      find("td", text: "opensuse131")
    end
  end

  it "filters the results" do
    expect(page.all(".filterable tbody tr").size).to eq(3)

    fill_in "filter", with: "leap"

    expect(page.all(".filterable tbody tr").size).to eq(1)

    click_link("Reset")

    expect(page.all(".filterable tbody tr").size).to eq(3)
  end
end
