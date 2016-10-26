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

describe Machinery::Filter do
  capture_machinery_output
  describe ".parse_filter_definitions" do
    it "parses array of definitions" do
      element_filter = Machinery::Filter.parse_filter_definitions(["/foo=bar", "/baz=qux"])
      expect(element_filter.keys.length).to eq(2)
      expect(element_filter["/foo"].matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => ["bar"])
      expect(element_filter["/baz"].matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => ["qux"])
    end

    it "parses definition with multiple matcher" do
      element_filter = Machinery::Filter.parse_filter_definitions("/foo=bar,baz")
      expect(element_filter.keys.length).to eq(1)
      expect(element_filter["/foo"].matchers).
        to eq(Machinery::Filter::OPERATOR_EQUALS => [["bar", "baz"]])
    end

    it "raises error if filter is invalid" do
      expect {
        Machinery::Filter.parse_filter_definitions("abc")
      }.to raise_error(Machinery::Errors::InvalidFilter, "Invalid filter: 'abc'")
    end

    it "raises error if filter is invalid and has whitespaces" do
      expect {
        Machinery::Filter.parse_filter_definitions("/ abc")
      }.to raise_error(Machinery::Errors::InvalidFilter, "Invalid filter: '/ abc'")
    end

    it "parses definition with 'equals not' operator" do
      element_filter = Machinery::Filter.parse_filter_definitions("/foo!=bar,baz")
      expect(element_filter.keys.length).to eq(1)
      expect(element_filter["/foo"].matchers).
        to eq(Machinery::Filter::OPERATOR_EQUALS_NOT => [["bar", "baz"]])
    end

    it "handles escaped commas" do
      element_filter = Machinery::Filter.parse_filter_definitions("/foo=bar,baz\\,qux")
      expect(element_filter.keys.length).to eq(1)
      expect(element_filter["/foo"].matchers).
        to eq(Machinery::Filter::OPERATOR_EQUALS => [["bar", "baz,qux"]])
    end

    it "fails on unknown operators" do
      expect {
        Machinery::Filter.parse_filter_definitions("/foo<=bar")
      }.to raise_error(Machinery::Errors::InvalidFilter)

      expect {
        Machinery::Filter.parse_filter_definitions("/foo<!=bar")
      }.to raise_error(Machinery::Errors::InvalidFilter)
    end
  end

  describe "#initialize" do
    it "creates Filter" do
      filter = Machinery::Filter.new
      expect(filter).to be_a(Machinery::Filter)
    end

    it "parses the filter definition" do
      filters = Machinery::Filter.new("/unmanaged_files/name=/home/alfred").element_filters

      expect(filters.keys.length).to eq(1)
      expect(filters["/unmanaged_files/name"].path).to eq("/unmanaged_files/name")
      expect(filters["/unmanaged_files/name"].matchers).
        to eq(Machinery::Filter::OPERATOR_EQUALS => ["/home/alfred"])
    end
  end

  describe "#add_element_filter_from_definition" do
    it "adds definitions" do
      filter = Machinery::Filter.new("foo=bar,baz")
      filter.add_element_filter_from_definition("bar=baz")

      element_filters = filter.element_filters
      expect(element_filters["foo"].matchers).
        to eq(Machinery::Filter::OPERATOR_EQUALS => [["bar", "baz"]])
      expect(element_filters["bar"].matchers).
        to eq(Machinery::Filter::OPERATOR_EQUALS => ["baz"])
    end

    it "merges new definitions with existing element filter" do
      filter = Machinery::Filter.new("foo=bar,baz")
      filter.add_element_filter_from_definition("foo=qux")

      element_filters = filter.element_filters
      expect(element_filters["foo"].matchers).
        to eq(Machinery::Filter::OPERATOR_EQUALS => [["bar", "baz"], "qux"])
    end
  end

  describe "#to_array" do
    it "returns the element filter definitions as a string array" do
      filter = Machinery::Filter.new(["foo=bar,baz", "foo=qux", "scope=matcher", "equals!=not"])
      expect(filter.to_array).to eq([
                                      "foo=bar,baz", "foo=qux", "scope=matcher", "equals!=not"
      ])
    end
  end

  describe "#filter_for" do
    it "returns the correct filter" do
      filter = Machinery::Filter.new(
        [
          "/unmanaged_files/name=/home/alfred",
          "/unmanaged_files/name=/var/cache",
          "/changed_managed_files/changes=md5,size"
        ]
      )

      element_filter = filter.element_filter_for("/unmanaged_files/name")
      expect(element_filter.path).to eq("/unmanaged_files/name")
      expect(element_filter.matchers).
        to eq(Machinery::Filter::OPERATOR_EQUALS => ["/home/alfred", "/var/cache"])

      element_filter = filter.element_filter_for("/changed_managed_files/changes")
      expect(element_filter.path).to eq("/changed_managed_files/changes")
      expect(element_filter.matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => [["md5", "size"]])
    end
  end

  describe "#element_filters_for_scope" do
    it "returns the relevant element filters" do
      filter = Machinery::Filter.new(
        [
          "/groups/name=root",
          "/unmanaged_files/name=/home/alfred",
          "/unmanaged_files/name=/var/cache",
          "/unmanaged_files/changes=md5,size",
          "/changed_managed_files/changes=md5,size"
        ]
      )

      expected = [
        Machinery::ElementFilter.new("/unmanaged_files/name", Machinery::Filter::OPERATOR_EQUALS,
          ["/home/alfred", "/var/cache"]),
        Machinery::ElementFilter.new("/unmanaged_files/changes", Machinery::Filter::OPERATOR_EQUALS,
          [["md5", "size"]])
      ]
      expect(filter.element_filters_for_scope("unmanaged_files")).to eq(expected)
    end
  end

  describe "#set_element_filters_for_scope" do
    it "replaces existing element filters" do
      filter = Machinery::Filter.new(
        [
          "/groups/name=root",
          "/unmanaged_files/name=/foo",
          "/unmanaged_files/name=/bar",
          "/unmanaged_files/changes=foo",
          "/changed_managed_files/changes=md5,size"
        ]
      )

      expected = [
        Machinery::ElementFilter.new("/unmanaged_files/name", Machinery::Filter::OPERATOR_EQUALS,
          ["/home/alfred", "/var/cache"]),
        Machinery::ElementFilter.new("/unmanaged_files/changes", Machinery::Filter::OPERATOR_EQUALS,
          [["md5", "size"]])
      ]
      filter.set_element_filters_for_scope("unmanaged_files", expected)

      expect(filter.element_filters_for_scope("unmanaged_files")).to eq(expected)
    end
  end

  describe "#matches?" do
    let(:filter) {
      Machinery::Filter.new([
                   "/unmanaged_files/name=/home/alfred",
                   "/unmanaged_files/name=/var/cache",
                   "/changed_managed_files/changes=md5,size"
      ])
    }

    it "returns false when no filter is set" do
      expect(filter.matches?("/some/path", "some_value")).to be(false)
    end

    it "asks the proper filter if it matches" do
      expect(filter.matches?("/unmanaged_files/name", "/var/cache")).to be(true)
      expect(filter.matches?("/changed_managed_files/name", "/var/cache")).to be(false)
    end
  end

  describe "#apply!" do
    let(:description) {
      create_test_description(scopes: ["unmanaged_files", "changed_managed_files"])
    }

    def expect_file_scope_filter_change(scope, filter, before, after)
      expect(description[scope].map(&:name)).to match_array(before)

      filter.apply!(description)

      expect(description[scope].map(&:name)).to match_array(after)
    end

    it "filters simple elements" do
      expect_file_scope_filter_change(
        "unmanaged_files",
        Machinery::Filter.new("/unmanaged_files/name=/etc/unmanaged-file"),
        [
          "/etc/unmanaged-file",
          "/etc/tarball with spaces/",
          "/etc/another-unmanaged-file"
        ],
        [
          "/etc/tarball with spaces/",
          "/etc/another-unmanaged-file"
        ]
      )
    end

    it "filters by array matches" do
      expect_file_scope_filter_change(
        "changed_managed_files",
        Machinery::Filter.new("/changed_managed_files/changes=md5,size"),
        [
          "/etc/cron.d",
          "/etc/deleted changed managed",
          "/etc/cron.daily/cleanup",
          "/etc/cron.daily/logrotate", # has changed 'md5' and 'size' and should be filtered,
          "/usr/bin/replaced_by_link"
        ],
        [
          "/etc/cron.d",
          "/etc/deleted changed managed",
          "/etc/cron.daily/cleanup",
          "/usr/bin/replaced_by_link"
        ]
      )
    end

    it "removes multiple items when a wildcard is used" do
      expect_file_scope_filter_change(
        "changed_managed_files",
        Machinery::Filter.new("/changed_managed_files/name=/etc/c*"),
        [
          "/etc/cron.d",
          "/etc/deleted changed managed",
          "/etc/cron.daily/cleanup",
          "/etc/cron.daily/logrotate",
          "/usr/bin/replaced_by_link"
        ],
        [
          "/etc/deleted changed managed",
          "/usr/bin/replaced_by_link"
        ]
      )
    end

    it "does not choke on non-existing elements" do
      expect {
        expect_file_scope_filter_change(
          "changed_managed_files",
          Machinery::Filter.new(["/does/not/exist=/foo", "/changed_managed_files/name=/etc/c*"]),
          [
            "/etc/cron.d",
            "/etc/deleted changed managed",
            "/etc/cron.daily/cleanup",
            "/etc/cron.daily/logrotate",
            "/usr/bin/replaced_by_link"
          ],
          [
            "/etc/deleted changed managed",
            "/usr/bin/replaced_by_link"
          ]
        )
      }.to_not raise_error
    end

    it "handles type mismatches" do
      expect {
        expect_file_scope_filter_change(
          "changed_managed_files",
          Machinery::Filter.new(["/changed_managed_files/name=element_a,element_b"]),
          [
            "/etc/deleted changed managed",
            "/etc/cron.d",
            "/etc/cron.daily/cleanup",
            "/etc/cron.daily/logrotate",
            "/usr/bin/replaced_by_link"
          ],
          [
            "/etc/deleted changed managed",
            "/etc/cron.d",
            "/etc/cron.daily/cleanup",
            "/etc/cron.daily/logrotate",
            "/usr/bin/replaced_by_link"
          ]
        )
      }.to_not raise_error
      expected_output = <<-EOF .chomp
Warning: Filter '/changed_managed_files/name=element_a,element_b' tries to match an array, but the according element is not an array.
EOF
      expect(captured_machinery_output).to include(expected_output)
    end
  end

  describe "#filter" do
    specify { expect(Machinery::Filter.new).to be_empty }
    specify { expect(Machinery::Filter.new("/foo=bar")).to_not be_empty }
  end
end
