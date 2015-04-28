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

require_relative "spec_helper"


describe InspectTask, "#inspect_system" do
  include FakeFS::SpecHelpers
  silence_machinery_output

  class SimpleInspectTaskList < Machinery::Array
    has_elements class: Machinery::Object
  end

  class SimpleInspectTaskScope < Machinery::Object
    include Machinery::Scope
    has_property :files, class: SimpleInspectTaskList
  end

  class FooInspector < Inspector
    def initialize(_system, description)
      @description = description
    end

    def inspect(_filter, _options = nil)
      result = SimpleInspectTaskScope.new(
        files: SimpleInspectTaskList.new([
          Machinery::Object.new(name: "foo"),
          Machinery::Object.new(name: "bar"),
          Machinery::Object.new(name: "baz"),
        ])
      )

      @description.foo = result
    end

    def summary
      "Found #{@description.foo.files.length} elements."
    end
  end

  class BarInspector < Inspector
    def initialize(_system, description)
      @description = description
    end

    def inspect(_filter, _options = nil)
      result = SimpleInspectTaskScope.new("bar" => "baz")

      @description.bar = result
    end

    def summary
      "summary"
    end
  end

  before :each do
    allow(System).to receive(:for).and_return(system)
  end

  let(:inspect_task) { InspectTask.new }
  let(:store) { SystemDescriptionStore.new }
  let(:description) { SystemDescription.new(name, store) }
  let(:name) { "name" }
  let(:host) { "example.com" }
  let(:system) {
    system = double(
      :requires_root? => false,
      :host           => "example.com"
    )
    allow(system).to receive(:remote_user=)
    system
  }

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
    expect(Inspector).to receive(:for).at_least(:once).times.with("foo").and_return(FooInspector)

    inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"], Filter.new)
  end

  it "saves the inspection data after each inspection and not just at the end" do
    expect_any_instance_of(SystemDescription).to receive(:save).at_least(:once).times

    inspect_task.inspect_system(store, host, name, current_user_non_root,
      ["foo", "bar"], Filter.new)
  end

  it "uses the specified remote user to access the system" do
    expect(Inspector).to receive(:for).at_least(:once).times.with("foo").and_return(FooInspector)
    expect(System).to receive(:for).with(anything, "machinery")

    inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"], Filter.new,
      remote_user: "machinery")
  end

  it "creates a proper system description" do
    description = inspect_task.inspect_system(
      store,
      host,
      name,
      current_user_non_root,
      ["foo"],
      Filter.new
    )

    expected = SimpleInspectTaskScope.new(
      files: SimpleInspectTaskList.new([
        Machinery::Object.new(name: "foo"),
        Machinery::Object.new(name: "bar"),
        Machinery::Object.new(name: "baz"),
      ])
    )
    expect(description.foo).to eql(expected)
  end

  describe "in case of inspection errors" do
    capture_machinery_output

    it "raises Machinery::Errors::ScopeFailed on 'expected errors'" do
      expect_any_instance_of(FooInspector).to receive(:inspect).
        and_raise(Machinery::Errors::SshConnectionFailed, "This is an SSH error")

      expect {
        inspect_task.inspect_system(store, host, name, current_user_non_root,
          ["foo"], Filter.new)
      }.to raise_error(
        Machinery::Errors::InspectionFailed,
        /Errors while inspecting foo:\n -> This is an SSH error/
      )
      expect(captured_machinery_output).to include(
        <<-EOF

Inspecting foo...
 -> Inspection failed!
        EOF
      )
    end

    it "bubbles up 'unexpected errors'" do
      expect_any_instance_of(FooInspector).to receive(:inspect).and_raise(RuntimeError)

      expect {
        inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"], Filter.new)
      }.to raise_error(RuntimeError)
    end
  end

  describe "root check" do
    describe "when root is required" do
      before(:each) do
        expect(system).to receive(:requires_root?).and_return(true)
      end

      it "raises an exception we don't run as root" do
        expect {
          inspect_task.inspect_system(store, "localhost", name, current_user_non_root,
            ["foo"], Filter.new)
        }.to raise_error(Machinery::Errors::MissingRequirement)
      end

      it "doesn't raise an exception when we run as root" do
        allow(Inspector).to receive(:all) { [] }

        expect {
          inspect_task.inspect_system(store, "localhost", name, current_user_root,
            ["foo"], Filter.new)
        }.not_to raise_error
      end
    end

    describe "when root is not required" do
      before(:each) do
        expect(system).to receive(:requires_root?).and_return(false)
      end

      it "doesn't raise an exception when we don't run as root" do
        allow(Inspector).to receive(:all) { [] }

        expect {
          inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"], Filter.new)
        }.not_to raise_error
      end
    end
  end

  context "with filters" do
    capture_machinery_output

    it "passes the filters to the inspectors" do
      expect(Inspector).to receive(:for).at_least(:once).times.and_return(FooInspector)

      expect_any_instance_of(FooInspector).to receive(:inspect) do |inspector, filter, _options|
        expect(filter.element_filters.length).to eq(1)
        expect(filter.element_filters["/foo"].matchers).
          to eq("=" => [["bar", "baz"]])

        inspector.description.foo = SimpleInspectTaskScope.new(files: SimpleInspectTaskList.new)
      end

      inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        Filter.new("/foo=bar,baz")
      )
    end

    it "stores the filters in the system description" do
      description = inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        Filter.new("/foo=bar,baz")
      )

      expected = ["/foo=bar,baz"]
      expect(description.filter_definitions("inspect")).to eq(expected)
    end

    it "only sets filters for scopes that were inspected" do
      description = SystemDescription.new(name, store)
      expect(SystemDescription).to receive(:load).and_return(description)

      description.set_filter_definitions("inspect", Filter.new(["/foo=bar", "/baz=qux"]).to_array)

      description = inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        Filter.new(["/foo=baz", "/baz=somethingelse"])
      )

      expected = [
        "/foo=baz",
        "/baz=qux"
      ]
      expect(description.filter_definitions("inspect")).to match_array(expected)
    end

    it "asks for the summary only after filtering" do
      inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        Filter.new(["/foo/files/name=baz", "/baz=somethingelse"])
      )

      expect(captured_machinery_output).to include("Found 2 elements.")
    end

    it "applies the filter to the generated system description" do
      expect_any_instance_of(Filter).to receive(:apply!).with(an_instance_of(SystemDescription))

      inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        Filter.new(["/foo/files/name=baz"])
      )
    end
  end
end
