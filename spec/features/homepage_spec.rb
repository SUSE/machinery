require_relative "feature_spec_helper"

RSpec::Steps.steps "Showing the home/list page", type: :feature do
  before(:all) do
    Server.set :system_description_store, SystemDescriptionStore.new(
      File.join(Machinery::ROOT, "spec/data/descriptions/jeos/")
    )
  end

  it "opens the landing page" do
    visit("/")
    expect(page.status_code).to eq(200)
  end

  it "starts with the modal view to select a description open" do
    expect(page).to have_content("Select a description")
  end

  it "doesn't allow the user to close the modal" do
    expect(page).to have_button("Close", disabled: true)
    expect(page).to have_css("button.close[disabled]")
  end
end
