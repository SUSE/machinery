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

  class SimpleInspectTaskScope < Machinery::Object
    include Machinery::ScopeMixin
  end

  class FooInspector < Inspector
    def inspect(_system, description, _filter, _options = nil)
      result = SimpleInspectTaskScope.new("bar" => "baz")

      description.foo = result
      "summary"
    end
  end

  class BarInspector < Inspector
    def inspect(_system, description, _filter, _options = nil)
      result = SimpleInspectTaskScope.new("bar" => "baz")

      description.bar = result
      "summary"
    end
  end

  before :each do
    allow(System).to receive(:for).and_return(system)
  end

  let(:inspect_task) { InspectTask.new }
  let(:store) { SystemDescriptionStore.new }
  let(:name) { "name" }
  let(:host) { "example.com" }
  let(:system) {
    double(
      :requires_root? => false,
      :host           => "example.com"
    )
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
    expect(Inspector).to receive(:for).with("foo").and_return(FooInspector.new)

    inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"], "")
  end

  it "saves the inspection data after each inspection and not just at the end" do
    expect_any_instance_of(SystemDescription).to receive(:save).twice

    inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo", "bar"], "")
  end

  it "creates a proper system description" do
    description = inspect_task.inspect_system(
      store,
      host,
      name,
      current_user_non_root,
      ["foo"],
      ""
    )

    expect(description.foo).to eql(SimpleInspectTaskScope.new("bar" => "baz"))
  end

  describe "in case of inspection errors" do
    capture_machinery_output

    it "raises Machinery::Errors::ScopeFailed on 'expected errors'" do
      expect_any_instance_of(FooInspector).to receive(:inspect).
        and_raise(Machinery::Errors::SshConnectionFailed, "This is an SSH error")

      expect {
        inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"], "")
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
        inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"], "")
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
          inspect_task.inspect_system(store, "localhost", name, current_user_non_root, ["foo"], "")
        }.to raise_error(Machinery::Errors::MissingRequirement)
      end

      it "doesn't raise an exception when we run as root" do
        allow(Inspector).to receive(:all) { [] }

        expect {
          inspect_task.inspect_system(store, "localhost", name, current_user_root, ["foo"], "")
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
          inspect_task.inspect_system(store, host, name, current_user_non_root, ["foo"], "")
        }.not_to raise_error
      end
    end
  end

  describe "with the :skip_files option" do
    it "maps it to an unmanaged_files filter" do
      inspector = FooInspector.new
      expect(Inspector).to receive(:for).and_return(inspector)

      expect(inspector).to receive(:inspect) do |_system, description, filter, _options|
        expect(filter.element_filters.length).to eq(1)
        expect(filter.element_filters["/unmanaged_files/files/name"].matchers).
          to eq(["/foo/bar"])

        description.foo = SimpleInspectTaskScope.new
        ""
      end

      inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        "",
        skip_files: "/foo/bar"
      )
    end
  end

  context "with filters" do
    it "passes the filters to the inspectors" do
      inspector = FooInspector.new
      expect(Inspector).to receive(:for).and_return(inspector)

      expect(inspector).to receive(:inspect) do |_system, description, filter, _options|
        expect(filter.element_filters.length).to eq(1)
        expect(filter.element_filters["/foo"].matchers).
          to eq(["bar", "baz"])

        description.foo = SimpleInspectTaskScope.new
        ""
      end

      inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        "\"/foo=bar,baz\""
      )
    end

    it "stores the filters in the system description" do
      description = inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        "\"/foo=bar,baz\""
      )

      expected = ["/foo=bar,baz"]
      expect(description.filters["inspect"].to_array).to eq(expected)
    end

    it "only sets filters for scopes that were inspected" do
      description = SystemDescription.new(name, store)
      expect(SystemDescription).to receive(:load).and_return(description)

      description.set_filter("inspect", Filter.new("/foo=bar,/baz=qux"))

      description = inspect_task.inspect_system(
        store,
        host,
        name,
        current_user_non_root,
        ["foo"],
        "\"/foo=baz\""
      )

      expected = [
        "/foo=baz",
        "/baz=qux"
      ]
      expect(description.filters["inspect"].to_array).to match_array(expected)
    end
  end
end
