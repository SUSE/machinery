require_relative "feature_spec_helper"

RSpec::Steps.steps "Showing the home/list page", type: :feature do
  before(:all) do
    Server.set :system_description_store, Machinery::SystemDescriptionStore.new(
      File.join(Machinery::ROOT, "spec/data/descriptions/jeos/")
    )
  end

  it "opens the homepage" do
    visit("/")
    expect(page.status_code).to eq(200)
  end

  it "starts with the modal view to select a description open" do
    expect(page).to have_content("Select a description")
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
    expect(page.all(".description-filterable tbody tr").size).to eq(2)

    fill_in "descriptions-filter", with: "leap"

    expect(page.all(".description-filterable tbody tr").size).to eq(1)

    click_link("Reset")

    expect(page.all(".description-filterable tbody tr").size).to eq(2)
  end
end
