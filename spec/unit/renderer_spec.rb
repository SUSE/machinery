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

class FooScope < Machinery::Object
  include Machinery::Scope
end

class FooRenderer < Renderer
  def content(description)
    puts description.foo.data
  end

  def compare_content_changed(changed_elements)
    puts "#{changed_elements.first} <> #{changed_elements.last}"
  end

  def display_name
    "Foo"
  end
end

class BarBazScope < Machinery::Object
  include Machinery::Scope
end

class BarBazRenderer < Renderer
  def content(description)
    heading("bar")

    puts("new line")
    list("My list") do
      item("List Item 1")
      item("List Item 2") do
        puts("Item puts")
      end
    end

    list do
      item("Item of a list with nil string")
    end

    list "" do
      item("Item of a list with empty string")
    end
  end

  def display_name
    "Bar baz"
  end
end

describe Renderer do
  let(:description1_without_data) {
    create_test_description(json: "{}", name: "name1")
  }
  let(:description2_without_data) {
    create_test_description(json: "{}", name: "name2")
  }
  let(:description_common_without_data) {
    create_test_description(json: "{}", name: "common")
  }
  let(:description1_with_data) {
    create_test_description(json: '{ "foo": { "data": "data1" } }', name: "name1")
  }
  let(:description2_with_data) {
    create_test_description(json: '{ "foo": { "data": "data2" } }', name: "name2")
  }
  let(:description_common_with_data) {
    create_test_description(json: '{ "foo": { "data": "data_common" } }', name: "name2")
  }

  let(:output_data_none) { "" }
  let(:output_data_missing) { <<-EOT }
# Foo

Only in 'name2':
  data2

In both with different attributes ('name1' <> 'name2'):
  one <> One

  EOT
  let(:output_data_only_common) { <<-EOT }
# Foo

Common to both systems:
  data_common

  EOT
  let(:output_data_all_without_common) { <<-EOT }
# Foo

Only in 'name1':
  data1

Only in 'name2':
  data2

In both with different attributes ('name1' <> 'name2'):
  one <> One

  EOT
  let(:output_data_all_with_common) { <<-EOT }
# Foo

Only in 'name1':
  data1

Only in 'name2':
  data2

In both with different attributes ('name1' <> 'name2'):
  one <> One

Common to both systems:
  data_common

  EOT

  describe ".for" do
    it "returns the requested Renderer" do
      expect(Renderer.for("foo")).to be_a(FooRenderer)
      expect(Renderer.for("bar_baz")).to be_a(BarBazRenderer)
    end
  end

  describe ".all" do
    it "returns all loaded Renderers" do
      renderers = Renderer.all

      expect(renderers.find{|i| i.is_a?(FooRenderer)}).to_not be_nil
      expect(renderers.find{|i| i.is_a?(BarBazRenderer)}).to_not be_nil
    end
  end

  describe "#scope" do
    it "returns the un-camelcased name" do
      expect(BarBazRenderer.new.scope).to eql("bar_baz")
    end
  end

  describe "#render" do
    let(:renderer) { BarBazRenderer.new }
    let(:description) {
      SystemDescription.new("foo", SystemDescriptionStore.new)
    }
    let(:date) { "2014-02-07T14:04:45Z" }
    let(:date_human) { Time.parse(date).localtime.strftime "%Y-%m-%d %H:%M:%S" }
    let(:host) { "192.168.122.216" }
    let(:description_with_meta) {
      create_test_description(json: <<-EOF)
        {
          "bar_baz": [],
          "meta": {
            "format_version": 2,
            "bar_baz": {
              "modified": "#{date}",
              "hostname": "#{host}"
            }
          }
        }
      EOF
    }

    it "calls specialized do_render method" do
      expect(renderer).to receive(:content)

      renderer.render(description)
    end

    it "renders" do
      expected = <<EOF
# bar

  new line
  My list:
    * List Item 1
    * List Item 2
      Item puts

  * Item of a list with nil string

  * Item of a list with empty string

EOF
      expect(renderer.render(description)).to eq(expected)
    end

    it "removes :list elements from the structure stack" do
      def renderer.content(_description)
        list("some list") do
          item("some item")
        end
      end

      renderer.render(description)
      expect(renderer.instance_variable_get("@stack")).to be_empty
    end

    it "raises an exception when a list is empty" do
      def renderer.content(_description)
        list("some list")
      end

      expect {
        renderer.render(description)
      }.to raise_error(Renderer::InvalidStructureError)
    end

    it "raises an exception when an item is created outside a list" do
      def renderer.content(_description)
        item("some item")
      end

      expect {
        renderer.render(description)
      }.to raise_error(Renderer::InvalidStructureError)
    end

    it "renders a scope of a system description with a date and a hostname" do
      def renderer.content(_description)
      end

      expected = <<EOF
# Bar baz [192.168.122.216] (#{date_human})

EOF
      expect(renderer.render(description_with_meta)).to eq(expected)
    end

    it "indents string with newlines properly" do
      def renderer.content(_description)
        puts "line 1\nline 2"
      end

      expect(renderer.render(description)).to include("  line 1\n  line 2")
    end
  end

  describe "#render_comparison" do
    subject { FooRenderer.new }

    context "when not showing common properties" do
      let(:options) { { show_all: false } }

      it "renders nothing when there is no scope data in all descriptions" do
        output = subject.render_comparison(
          description1_without_data,
          description2_without_data,
          nil,
          description_common_without_data,
          options
        )

        expect(output).to eq(output_data_none)
      end

      it "renders error message when there is no scope data in at least one description" do
        output = subject.render_comparison(
          description1_without_data,
          description2_with_data,
          ["one", "One"],
          description_common_without_data,
          options
        )

        expect(output).to eq(output_data_missing)
      end

      it "renders correct output when there is scope data in all descriptions" do
        output = subject.render_comparison(
          description1_with_data,
          description2_with_data,
          ["one", "One"],
          description_common_without_data,
          options
        )

        expect(output).to eq(output_data_all_without_common)
      end
    end

    context "when showing common properties" do
      let(:options) { { show_all: true } }

      it "renders nothing when there is no scope data in all descriptions" do
        output = subject.render_comparison(
          description1_without_data,
          description2_without_data,
          nil,
          description_common_without_data,
          options
        )

        expect(output).to eq(output_data_none)
      end

      it "renders correct output when there is no scope data in the common description" do
        output = subject.render_comparison(
          description1_with_data,
          description2_with_data,
          ["one", "One"],
          description_common_without_data,
          options
        )

        expect(output).to eq(output_data_all_without_common)
      end

      it "renders correct output when there is scope data in the common description" do
        output = subject.render_comparison(
          description1_without_data,
          description2_without_data,
          nil,
          description_common_with_data,
          options
        )

        expect(output).to eq(output_data_only_common)
      end

      it "renders correct output when there is scope data in all descriptions" do
        output = subject.render_comparison(
          description1_with_data,
          description2_with_data,
          ["one", "One"],
          description_common_with_data,
          options
        )

        expect(output).to eq(output_data_all_with_common)
      end
    end

    it "uses #do_render_comparison_only_in and #do_render_comparison_common for rendering" do
      expect(subject).to receive(:compare_content_only_in) do |description|
        expect(description).to eq(description1_with_data)
      end

      expect(subject).to receive(:compare_content_only_in) do |description|
        expect(description).to eq(description2_with_data)
      end

      expect(subject).to receive(:compare_content_common) do |description|
        expect(description).to eq(description_common_with_data)
      end

      subject.render_comparison(
        description1_with_data,
        description2_with_data,
        ["one", "One"],
        description_common_with_data,
        show_all: true
      )
    end

    it "sets the options" do
      passed_options = { show_all: true }

      expect(subject).to receive(:content) do
        options = subject.instance_variable_get(:@options)

        expect(options).to eq(passed_options)
      end.exactly(3).times

      subject.render_comparison(
        description1_with_data,
        description2_with_data,
        ["one", "One"],
        description_common_with_data,
        passed_options
      )
    end
  end

  describe "#compare_content_only_in" do
    it "falls back to #content by default" do
      expect(subject).to receive(:content)

      subject.compare_content_only_in(description1_with_data)
    end
  end

  describe "#compare_content_common" do
    it "falls back to #content by default" do
      expect(subject).to receive(:content)

      subject.compare_content_common(description1_with_data)
    end
  end
end
