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


describe Machinery::InspectTask, "#inspect_system" do
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
    allow_any_instance_of(Machinery::RemoteSystem).to receive(:connect)
    allow_any_instance_of(Machinery::DockerSystem).to receive(:validate_image_name)
    allow_any_instance_of(Machinery::DockerSystem).to receive(:create_container)
    allow(inspect_task).to receive(:set_system_locale)
  end

  let(:inspect_task) { Machinery::InspectTask.new }
  let(:store) { Machinery::SystemDescriptionStore.new }
  let(:description) { Machinery::SystemDescription.new(name, store) }
  let(:name) { "name" }
  let(:system) { Machinery::RemoteSystem.new("example.com") }
  let(:local_system) { Machinery::LocalSystem.new }
  let(:docker_system) { Machinery::DockerSystem.new("foo") }

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

  it "gathers the system environment before running the actual inspection" do
    expect(inspect_task).to receive(:set_system_locale)
    expect(Inspector).to receive(:for).at_least(:once).times.with("foo").and_return(FooInspector)

    inspect_task.inspect_system(store, system, name, current_user_non_root, ["foo"], Machinery::Filter.new)
  end

  it "runs the proper inspector when a scope is given" do
    expect(Inspector).to receive(:for).at_least(:once).times.with("foo").and_return(FooInspector)

    inspect_task.inspect_system(store, system, name, current_user_non_root, ["foo"], Machinery::Filter.new)
  end

  it "saves the inspection data after each inspection and not just at the end" do
    expect_any_instance_of(Machinery::SystemDescription).to receive(:save).at_least(:once).times

    inspect_task.inspect_system(store, system, name, current_user_non_root,
      ["foo", "bar"], Machinery::Filter.new)
  end

  it "creates a proper system description" do
    description = inspect_task.inspect_system(
      store,
      system,
      name,
      current_user_non_root,
      ["foo"],
      Machinery::Filter.new
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
        inspect_task.inspect_system(store, system, name, current_user_non_root,
          ["foo"], Machinery::Filter.new)
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
        inspect_task.inspect_system(store, system, name, current_user_non_root, ["foo"], Machinery::Filter.new)
      }.to raise_error(RuntimeError)
    end
  end

  describe "root check" do
    describe "when root is required" do
      before(:each) do
        expect(local_system).to receive(:requires_root?).and_return(true)
        allow(inspect_task).to receive(:set_system_locale)
      end

      it "raises an exception we don't run as root" do
        expect {
          inspect_task.inspect_system(store, local_system, name, current_user_non_root,
            ["foo"], Machinery::Filter.new)
        }.to raise_error(Machinery::Errors::MissingRequirement)
      end

      it "doesn't raise an exception when we run as root" do
        allow(Inspector).to receive(:all) { [] }

        expect {
          inspect_task.inspect_system(store, local_system, name, current_user_root,
            ["foo"], Machinery::Filter.new)
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
          inspect_task.inspect_system(store, system, name, current_user_non_root, ["foo"],
            Machinery::Filter.new)
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
        system,
        name,
        current_user_non_root,
        ["foo"],
        Machinery::Filter.new("/foo=bar,baz")
      )
    end

    it "stores the filters in the system description" do
      description = inspect_task.inspect_system(
        store,
        system,
        name,
        current_user_non_root,
        ["foo"],
        Machinery::Filter.new("/foo=bar,baz")
      )

      expected = ["/foo=bar,baz"]
      expect(description.filter_definitions("inspect")).to eq(expected)
    end

    it "only sets filters for scopes that were inspected" do
      description = Machinery::SystemDescription.new(name, store)
      expect(Machinery::SystemDescription).to receive(:load).and_return(description)

      description.set_filter_definitions("inspect", Machinery::Filter.new(["/foo=bar", "/baz=qux"]).to_array)

      description = inspect_task.inspect_system(
        store,
        system,
        name,
        current_user_non_root,
        ["foo"],
        Machinery::Filter.new(["/foo=baz", "/baz=somethingelse"])
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
        system,
        name,
        current_user_non_root,
        ["foo"],
        Machinery::Filter.new(["/foo/files/name=baz", "/baz=somethingelse"])
      )

      expect(captured_machinery_output).to include("Found 2 elements.")
    end

    it "applies the filter to the generated system description" do
      expect_any_instance_of(Machinery::Filter).
        to receive(:apply!).with(an_instance_of(Machinery::SystemDescription))

      inspect_task.inspect_system(
        store,
        system,
        name,
        current_user_non_root,
        ["foo"],
        Machinery::Filter.new(["/foo/files/name=baz"])
      )
    end
  end
end
