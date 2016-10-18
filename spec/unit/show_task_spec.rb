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

require_relative "spec_helper"


describe Machinery::ShowTask, "#show" do
  capture_machinery_output

  let(:show_task) { Machinery::ShowTask.new }
  let(:system_description) {
    Machinery::SystemDescription.new("foo", Machinery::SystemDescriptionMemoryStore.new)
  }
  let(:description_with_packages) {
    create_test_description(scopes: ["empty_packages"])
  }
  let(:description_without_vendor) {
    create_test_description(scopes: ["package_without_vendor"])
  }
  let(:description_without_user_comment) {
    create_test_description(scopes: ["users_without_comment"])
  }

  it "runs the proper renderer when a scope is given" do
    renderer = double
    expect(renderer).to receive(:render).and_return("bar")
    expect(Renderer).to receive(:for).with("packages").and_return(renderer)

    show_task.show(system_description, ["packages"], Filter.new, no_pager: true)
  end

  it "prints a note about the 'N/A' tag for package vendor attribute" do
    show_task.show(description_without_vendor, ["packages"], Filter.new, no_pager: true)
    expect(captured_machinery_output).to include("missing package vendor")
  end

  it "prints a note about the 'N/A' tag for user comments attribute" do
    show_task.show(description_without_user_comment, ["users"], Filter.new, no_pager: true)
    expect(captured_machinery_output).to include("missing user info, user ID or group ID")
  end

  it "prints scopes missing from the system description" do
    scope = "packages"
    show_task.show(system_description, [scope], Filter.new, no_pager: true)

    expect(captured_machinery_output).to include("requested scopes were not inspected")
    expect(captured_machinery_output).to include("packages")
  end

  it "does not show a message about missing scopes if there are none" do
    scope = "packages"
    show_task.show(description_with_packages, [scope], Filter.new, no_pager: true)

    expect(captured_machinery_output).to_not include("requested scopes were not inspected")
  end

  it "opens the system description in the web browser" do
    expect(Machinery::LocalSystem).
      to receive(:validate_existence_of_command).with("xdg-open", "xdg-utils")
    expect(Cheetah).to receive(:run).with("xdg-open", "http://0.0.0.0:3000/foo")
    expect(Html).to receive(:run_server) do |_store, _options, &block|
      block.call
      double(join: nil)
    end

    show_task.show(
      system_description, ["packages"], Filter.new, show_html: true, ip: "0.0.0.0", port: 3000
    )
  end

  it "passes along a sorted scope list" do
    expected_scope_list = ["os", "packages", "users"]

    expect(show_task).to receive(:show_console).with(system_description, expected_scope_list, {})
    show_task.show(system_description, ["packages", "users", "os"], Filter.new)
  end
end
