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

describe CompareTask do
  describe "#compare" do
    class CompareTaskFooScope < Machinery::Scope; contains Machinery::Array; end
    class CompareTaskBarScope < Machinery::Scope; contains Machinery::Array; end
    class CompareTaskBazScope < Machinery::Scope; contains Machinery::Array; end
    class CompareTaskFoobarScope < Machinery::Scope; contains Machinery::Array; end

    class CompareTaskFooRenderer < Renderer
      def do_render
        @system_description["compare-task-foo"].each do |e|
          puts e
        end
      end

      def display_name
        "Foo"
      end
    end

    class CompareTaskBarRenderer < Renderer
      def do_render
        @system_description["compare-task-bar"].each do |e|
          puts e
        end
      end

      def display_name
        "Bar"
      end
    end

    class CompareTaskBazRenderer < Renderer
      def do_render
        @system_description["compare-task-baz"].each do |e|
          puts e
        end
      end

      def display_name
        "Baz"
      end
    end

    class CompareTaskFoobarRenderer < Renderer
      def do_render
        @system_description["compare-task-foobar"].each do |e|
          puts e
        end
      end

      def display_name
        "Foobar"
      end
    end

    subject { CompareTask.new }

    let(:description1) {
      SystemDescription.from_json("name1", <<-EOT)
        {
          "compare-task-foo": ["foo_data1"],
          "compare-task-bar": ["bar_data1"],
          "compare-task-baz": ["baz_data1"]
        }
      EOT
    }

    let(:description2) {
      SystemDescription.from_json("name2", <<-EOT)
        {
          "compare-task-foo": ["foo_data2"],
          "compare-task-bar": ["bar_data2"],
          "compare-task-baz": ["baz_data2"]
        }
      EOT
    }

    let(:description3) {
      SystemDescription.from_json("name3", <<-EOT)
        {
          "compare-task-bar": ["bar_data3"],
          "compare-task-foobar": ["foobar_data3"]
        }
      EOT
    }

    let(:description4) {
      SystemDescription.from_json("name4", <<-EOT)
        {
          "compare-task-foo": ["foo_data4"],
          "compare-task-foobar": ["foobar_data4"]
        }
      EOT
    }

    let(:output_different) {
      <<-EOT
# Foo

Only in 'name1':
  foo_data1

Only in 'name2':
  foo_data2

# Bar

Only in 'name1':
  bar_data1

Only in 'name2':
  bar_data2

# Baz

Only in 'name1':
  baz_data1

Only in 'name2':
  baz_data2

      EOT
    }

    let(:output_same_show_all_true) {
      <<-EOT
Compared descriptions are identical.
# Foo

Common to both systems:
  foo_data1

# Bar

Common to both systems:
  bar_data1

# Baz

Common to both systems:
  baz_data1

      EOT
    }

    let(:output_missing) {
      <<-EOT
# Foo
  Unable to compare, no data in 'name3'

# Bar
  Unable to compare, no data in 'name4'

# Baz
  Unable to compare, no data in 'name3', 'name4'

# Foobar

Only in 'name3':
  foobar_data3

Only in 'name4':
  foobar_data4

      EOT
    }

    let(:output_missing_same) {
      <<-EOT
Compared descriptions are identical.
# Foo
  Unable to compare, no data in 'name3', 'name3'

# Baz
  Unable to compare, no data in 'name3', 'name3'

      EOT
    }

    let(:output_same_show_all_false) {
      "Compared descriptions are identical.\n"
    }

    def setup_renderers
      allow(Renderer).to receive(:for).
        with("compare-task-foo").
        and_return(CompareTaskFooRenderer.new)
      allow(Renderer).to receive(:for).
        with("compare-task-bar").
        and_return(CompareTaskBarRenderer.new)
      allow(Renderer).to receive(:for).
        with("compare-task-baz").
        and_return(CompareTaskBazRenderer.new)
      allow(Renderer).to receive(:for).
        with("compare-task-foobar").
        and_return(CompareTaskFoobarRenderer.new)
    end

    describe "when the descriptions are different" do
      it "produces correct output" do
        setup_renderers

        allow($stdout).to receive(:tty?).and_return(false)

        expect($stdout).to receive(:puts).with(output_different)

        subject.compare(
          description1,
          description2,
          ["compare-task-foo", "compare-task-bar", "compare-task-baz"]
        )
      end

      it "prints a message when a description is incomplete" do
        setup_renderers

        allow($stdout).to receive(:tty?).and_return(false)

        expect($stdout).to receive(:puts).with(output_missing)

        subject.compare(
          description3,
          description4,
          ["compare-task-foo", "compare-task-bar", "compare-task-baz", "compare-task-foobar"]
        )
      end
    end

    describe "when the descriptions are the same" do
      before :each do
        setup_renderers

        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "produces correct output when :show_all is set to false" do
        expect($stdout).to receive(:puts).with(output_same_show_all_false)

        subject.compare(
          description1,
          description1,
          ["compare-task-foo", "compare-task-bar", "compare-task-baz"],
          show_all: false
        )
      end

      it "produces correct output when :show_all is set to true" do
        expect($stdout).to receive(:puts).with(output_same_show_all_true)

        subject.compare(
          description1,
          description1,
          ["compare-task-foo", "compare-task-bar", "compare-task-baz"],
          show_all: true
        )
      end

      it "produces correct output when scopes are missing" do
        expect($stdout).to receive(:puts).with(output_missing_same)

        subject.compare(
          description3,
          description3,
          ["compare-task-foo", "compare-task-bar", "compare-task-baz"]
        )
      end
    end

    it "raises an exception for unknown scope" do
      allow($stdout).to receive(:tty?).and_return(false)

      expect {
        subject.compare(description1, description2, ["unknown"])
      }.to raise_error(Machinery::Errors::UnknownRenderer)
    end
  end
end
