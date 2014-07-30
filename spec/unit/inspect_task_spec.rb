# Copyright (c) 2013-2014 SUSE LLC
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


describe InspectTask, "#inspect_system" do
  class SimpleInspectTaskScope < Machinery::Scope
    contains Machinery::Object
  end

  class FooInspector < Inspector
    def inspect(system, description, options = nil)
      result = SimpleInspectTaskScope.new("bar" => "baz")

      description.foo = result
      "summary"
    end
  end

  before :each do
    allow_any_instance_of(SystemDescriptionStore).to receive(:save)
  end

  let(:inspect_task) { InspectTask.new }
  let(:store) { SystemDescriptionStore.new }
  let(:name) { "name" }
  let(:host) { "example.com" }


  let(:current_user_root) {
    current_user = double
    allow(current_user).to receive(:is_root?).and_return(true)
    current_user
  }

  let(:current_user_non_root) {
    current_user = double
    allow(current_user).to receive(:is_root?).and_return(false)
    current_user
  }

  it "runs the proper inspector when a scope is given" do
    expect(Inspector).to receive(:for).with("foo").and_return(FooInspector.new)

    inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"])
  end

  it "creates a proper system description" do
    description = inspect_task.inspect_system(
      store,
      host,
      name,
      current_user_non_root,
      ["foo"]
    )

    expect(description.foo).to eql(SimpleInspectTaskScope.new("bar" => "baz"))
  end

  it "raises an exception when an inspector is unknown" do
    expect {
      inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["doesnotexist"]
      )
    }.to raise_error(Machinery::Errors::UnknownInspector, /not supported.*doesnotexist/)
  end

  it "raises an exception when an inspector fails" do
    description = SystemDescription.new("foo")
    failed_inspection = {:foo => "foo"}
    allow(inspect_task).to receive(:build_description).and_return([description, failed_inspection])
    expect {
      inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"])
    }.to raise_error(Machinery::Errors::ScopeFailed)
  end

  describe "root check" do
    it "raises an exception when inspected system requires root and we don't run as root" do
      expect {
        inspect_task.inspect_system(store, "localhost", name, current_user_non_root, ["foo"])
      }.to raise_error(Machinery::Errors::MissingSystemRequirement)
    end

    it "doesn't raise an exception when inspected system doesn't require root and we don't run as root" do
      allow(Inspector).to receive(:all) { [] }

      expect {
        inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"])
      }.not_to raise_error
    end

    it "doesn't raise an exception when inspected system does requires root and we run as root" do
      allow(Inspector).to receive(:all) { [] }

      expect {
        inspect_task.inspect_system(store, "localhost", name, current_user_root, ["foo"])
      }.not_to raise_error
    end
  end
end
