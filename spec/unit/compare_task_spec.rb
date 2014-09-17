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
    class CompareTaskFooScope < Machinery::Array; end
    class CompareTaskBarScope < Machinery::Array; end
    class CompareTaskBazScope < Machinery::Array; end
    class CompareTaskFoobarScope < Machinery::Array; end

    class CompareTaskFooRenderer < Renderer
      def do_render
        @system_description["compare_task_foo"].each do |e|
          puts e
        end
      end

      def display_name
        "Foo"
      end
    end

    class CompareTaskBarRenderer < Renderer
      def do_render
        @system_description["compare_task_bar"].each do |e|
          puts e
        end
      end

      def display_name
        "Bar"
      end
    end

    class CompareTaskBazRenderer < Renderer
      def do_render
        @system_description["compare_task_baz"].each do |e|
          puts e
        end
      end

      def display_name
        "Baz"
      end
    end

    class CompareTaskFoobarRenderer < Renderer
      def do_render
        @system_description["compare_task_foobar"].each do |e|
          puts e
        end
      end

      def display_name
        "Foobar"
      end
    end

    subject { CompareTask.new }

    let(:description1) {
      create_test_description(json: <<-EOT, name: "name1")
        {
          "compare_task_foo": ["foo_data1"],
          "compare_task_bar": ["bar_data1"],
          "compare_task_baz": ["baz_data1"]
        }
      EOT
    }

    let(:description2) {
      create_test_description(json: <<-EOT, name: "name2")
        {
          "compare_task_foo": ["foo_data2"],
          "compare_task_bar": ["bar_data2"],
          "compare_task_baz": ["baz_data2"]
        }
      EOT
    }

    let(:description3) {
      create_test_description(json: <<-EOT, name: "name3")
        {
          "compare_task_bar": ["bar_data3"],
          "compare_task_foobar": ["foobar_data3"]
        }
      EOT
    }

    let(:description4) {
      create_test_description(json: <<-EOT, name: "name4")
        {
          "compare_task_foo": ["foo_data4"],
          "compare_task_foobar": ["foobar_data4"]
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
        with("compare_task_foo").
        and_return(CompareTaskFooRenderer.new)
      allow(Renderer).to receive(:for).
        with("compare_task_bar").
        and_return(CompareTaskBarRenderer.new)
      allow(Renderer).to receive(:for).
        with("compare_task_baz").
        and_return(CompareTaskBazRenderer.new)
      allow(Renderer).to receive(:for).
        with("compare_task_foobar").
        and_return(CompareTaskFoobarRenderer.new)
    end

    describe "when the descriptions are different" do
      it "produces correct output" do
        setup_renderers

        allow($stdout).to receive(:tty?).and_return(false)

        expect(Machinery::Ui).to receive(:print_output).with(output_different, anything)

        subject.compare(
          description1,
          description2,
          ["compare_task_foo", "compare_task_bar", "compare_task_baz"]
        )
      end

      it "prints a message when a description is incomplete" do
        setup_renderers

        allow($stdout).to receive(:tty?).and_return(false)

        expect(Machinery::Ui).to receive(:print_output).with(output_missing, anything)

        subject.compare(
          description3,
          description4,
          ["compare_task_foo", "compare_task_bar", "compare_task_baz", "compare_task_foobar"]
        )
      end
    end

    describe "when the descriptions are the same" do
      before :each do
        setup_renderers

        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "produces correct output when :show_all is set to false" do
        expect(Machinery::Ui).to receive(:print_output).with(output_same_show_all_false, anything)

        subject.compare(
          description1,
          description1,
          ["compare_task_foo", "compare_task_bar", "compare_task_baz"],
          show_all: false
        )
      end

      it "produces correct output when :show_all is set to true" do
        expect(Machinery::Ui).to receive(:print_output).with(output_same_show_all_true, anything)

        subject.compare(
          description1,
          description1,
          ["compare_task_foo", "compare_task_bar", "compare_task_baz"],
          show_all: true
        )
      end

      it "produces correct output when scopes are missing" do
        expect(Machinery::Ui).to receive(:print_output).with(output_missing_same, anything)

        subject.compare(
          description3,
          description3,
          ["compare_task_foo", "compare_task_bar", "compare_task_baz"]
        )
      end
    end
  end

  describe "compare os scopes" do
    it "shows two different os scopes" do
      system_description1 = create_test_description(json: <<-EOT, name: "one")
        {
          "os": {
            "name": "openSUSE",
            "version": "12.2",
            "architecture": "x86_64"
          }
        }
      EOT

      system_description2 = create_test_description(json: <<-EOT, name: "two")
        {
          "os": {
            "name": "openSUSE",
            "version": "13.1",
            "architecture": "x86_64"
          }
        }
      EOT

      expected_output = <<EOT
# Operating system

Only in 'one':
  Name: openSUSE
  Version: 12.2
  Architecture: x86_64

Only in 'two':
  Name: openSUSE
  Version: 13.1
  Architecture: x86_64

EOT
      output = CompareTask.new.render_comparison(system_description1,
        system_description2, ["os"])

      expect(output).to eq expected_output
    end

    it "shows two identical os scopes" do
      system_description1 = create_test_description(json: <<-EOT, name: "one")
        {
          "os": {
            "name": "openSUSE",
            "version": "12.2",
            "architecture": "x86_64"
          }
        }
      EOT

      system_description2 = create_test_description(json: <<-EOT, name: "two")
        {
          "os": {
            "name": "openSUSE",
            "version": "12.2",
            "architecture": "x86_64"
          }
        }
      EOT

      output = CompareTask.new.render_comparison(system_description1,
        system_description2, ["os"])

      expect(output).to eq "Compared descriptions are identical.\n"
    end
  end

  describe "compare packages scope" do
    it "shows that a package has been added to a list" do
      system_description1 = create_test_description(json: <<-EOT, name: "one")
        {
          "packages": [
             {
               "name": "bash",
               "version": "4.2",
               "release": "68.1.5",
               "arch": "x86_64",
               "vendor": "openSUSE",
               "checksum": "2a3d5b29179daa1e65e391d0a0c1442d"
             },
             {
               "name": "kernel",
               "version": "3",
               "release": "1",
               "arch": "x86_64",
               "vendor": "openSUSE",
               "checksum": "7dfdd742a9b7d60c75bf4844d294716d"
             }
           ]
        }
      EOT

      system_description2 = create_test_description(json: <<-EOT, name: "two")
        {
          "packages": [
             {
               "name": "bash",
               "version": "4.2",
               "release": "68.1.5",
               "arch": "x86_64",
               "vendor": "openSUSE",
               "checksum": "2a3d5b29179daa1e65e391d0a0c1442d"
             }
           ]
        }
      EOT

      expected_output = <<EOT
# Packages

Only in 'one':
  * kernel-3-1.x86_64 (openSUSE)

EOT
      output = CompareTask.new.render_comparison(system_description1,
        system_description2, ["packages"])

      expect(output).to eq expected_output
    end

    it "shows that a package has been changed in a list" do
      system_description1 = create_test_description(json: <<-EOT, name: "one")
        {
          "packages": [
             {
               "name": "bash",
               "version": "4.2",
               "release": "68.1.5",
               "arch": "x86_64",
               "vendor": "openSUSE",
               "checksum": "2a3d5b29179daa1e65e391d0a0c1442d"
             },
             {
               "name": "kernel",
               "version": "3",
               "release": "1",
               "arch": "x86_64",
               "vendor": "openSUSE",
               "checksum": "7dfdd742a9b7d60c75bf4844d294716d"
             }
           ]
        }
      EOT

      system_description2 = create_test_description(json: <<-EOT, name: "two")
        {
          "packages": [
             {
               "name": "bash",
               "version": "4.2",
               "release": "68.1.5",
               "arch": "x86_64",
               "vendor": "openSUSE",
               "checksum": "2a3d5b29179daa1e65e391d0a0c1442d"
             },
             {
               "name": "kernel",
               "version": "4",
               "release": "1",
               "arch": "x86_64",
               "vendor": "openSUSE",
               "checksum": "7dfdd742a9b7d60c75bf4844d294716d"
             }
           ]
        }
      EOT

      expected_output = <<EOT
# Packages

Only in 'one':
  * kernel-3-1.x86_64 (openSUSE)

Only in 'two':
  * kernel-4-1.x86_64 (openSUSE)

EOT
      output = CompareTask.new.render_comparison(system_description1,
        system_description2, ["packages"])

      expect(output).to eq expected_output
    end
  end
end
