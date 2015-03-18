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

describe Filter do
  describe ".parse_filter_definitions" do
    it "parses array of definitions" do
      element_filter = Filter.parse_filter_definitions(["/foo=bar", "/baz=qux"])
      expect(element_filter.keys.length).to eq(2)
      expect(element_filter["/foo"].matchers).
        to eq(["bar"])
      expect(element_filter["/baz"].matchers).
        to eq(["qux"])
    end

    it "parses definition with multiple matcher" do
      element_filter = Filter.parse_filter_definitions("/foo=bar,baz")
      expect(element_filter.keys.length).to eq(1)
      expect(element_filter["/foo"].matchers).
        to eq([["bar", "baz"]])
    end

    it "handles escaped commas" do
      element_filter = Filter.parse_filter_definitions("/foo=bar,baz\\,qux")
      expect(element_filter.keys.length).to eq(1)
      expect(element_filter["/foo"].matchers).
        to eq([["bar", "baz,qux"]])
    end
  end

  describe "#initialize" do
    it "creates Filter" do
      filter = Filter.new
      expect(filter).to be_a(Filter)
    end

    it "parses the filter definition" do
      filters = Filter.new("/unmanaged_files/files/name=/home/alfred").element_filters

      expect(filters.keys.length).to eq(1)
      expect(filters["/unmanaged_files/files/name"].path).to eq("/unmanaged_files/files/name")
      expect(filters["/unmanaged_files/files/name"].matchers).to eq(["/home/alfred"])
    end
  end

  describe "#add_filter_definition" do
    it "adds definitions" do
      filter = Filter.new("foo=bar,baz")
      filter.add_element_filter_from_definition("bar=baz")

      element_filters = filter.element_filters
      expect(element_filters["foo"].matchers).to eq([["bar", "baz"]])
      expect(element_filters["bar"].matchers).to eq(["baz"])
    end

    it "merges new definitions with existing element filter" do
      filter = Filter.new("foo=bar,baz")
      filter.add_element_filter_from_definition("foo=qux")

      element_filters = filter.element_filters
      expect(element_filters["foo"].matchers).to eq([["bar", "baz"], "qux"])
    end
  end

  describe "#to_array" do
    it "returns the element filter definitions as a string array" do
      filter = Filter.new(["foo=bar,baz", "foo=qux", "scope=matcher"])
      expect(filter.to_array).to eq([
        "foo=bar,baz", "foo=qux", "scope=matcher"
      ])
    end
  end

  describe "#filter_for" do
    it "returns the correct filter" do
      filter = Filter.new([
        "/unmanaged_files/files/name=/home/alfred",
        "/unmanaged_files/files/name=/var/cache",
        "/changed_managed_files/files/changes=md5,size"
      ])

      element_filter = filter.element_filter_for("/unmanaged_files/files/name")
      expect(element_filter.path).to eq("/unmanaged_files/files/name")
      expect(element_filter.matchers).to eq(["/home/alfred", "/var/cache"])

      element_filter = filter.element_filter_for("/changed_managed_files/files/changes")
      expect(element_filter.path).to eq("/changed_managed_files/files/changes")
      expect(element_filter.matchers).to eq([["md5", "size"]])
    end
  end

  describe "#matches?" do
    let(:filter) {
      Filter.new([
          "/unmanaged_files/files/name=/home/alfred",
          "/unmanaged_files/files/name=/var/cache",
          "/changed_managed_files/files/changes=md5,size"
      ])
    }

    it "returns false when no filter is set" do
      expect(filter.matches?("/some/path", "some_value")).to be(false)
    end

    it "asks the proper filter if it matches" do
      expect(filter.matches?("/unmanaged_files/files/name", "/var/cache")).to be(true)
      expect(filter.matches?("/changed_managed_files/files/name", "/var/cache")).to be(false)
    end
  end

  describe "#apply!" do
    let(:description) {
      create_test_description(scopes: ["unmanaged_files", "changed_managed_files"])
    }

    def expect_file_scope_filter_change(scope, filter, before, after)
      expect(description[scope].files.map(&:name)).to match_array(before)

      filter.apply!(description)

      expect(description[scope].files.map(&:name)).to match_array(after)
    end

    it "filters simple elements" do
      expect_file_scope_filter_change(
        "unmanaged_files",
        Filter.new("/unmanaged_files/files/name=/etc/unmanaged-file"),
        [
          "/etc/unmanaged-file",
          "/etc/another-unmanaged-file"
        ],
        [
          "/etc/another-unmanaged-file"
        ]
      )
    end

    it "filters by array matches" do
      expect_file_scope_filter_change(
        "changed_managed_files",
        Filter.new("/changed_managed_files/files/changes=md5,size"),
        [
          "/etc/deleted changed managed",
          "/etc/cron.daily/cleanup",
          "/etc/cron.daily/logrotate" # has changed 'md5' and 'size' and should be filtered
        ],
        [
          "/etc/deleted changed managed",
          "/etc/cron.daily/cleanup"
        ]
      )
    end

    it "removes multiple items when a wildcard is used" do
      expect_file_scope_filter_change(
        "changed_managed_files",
        Filter.new("/changed_managed_files/files/name=/etc/c*"),
        [
          "/etc/deleted changed managed",
          "/etc/cron.daily/cleanup",
          "/etc/cron.daily/logrotate"
        ],
        [
          "/etc/deleted changed managed"
        ]
      )
    end

    it "does not choke on non-existing elements" do
      expect {
        expect_file_scope_filter_change(
          "changed_managed_files",
          Filter.new(["/does/not/exist=/foo", "/changed_managed_files/files/name=/etc/c*"]),
          [
            "/etc/deleted changed managed",
            "/etc/cron.daily/cleanup",
            "/etc/cron.daily/logrotate"
          ],
          [
            "/etc/deleted changed managed"
          ]
        )
      }.to_not raise_error
    end

    it "handles type mismatches" do
      expect(Machinery::Ui).to receive(:warn).with(/WARNING.*not an array/)
      expect {
        expect_file_scope_filter_change(
          "changed_managed_files",
          Filter.new(["/changed_managed_files/files/name=element_a,element_b"]),
          [
            "/etc/deleted changed managed",
            "/etc/cron.daily/cleanup",
            "/etc/cron.daily/logrotate"
          ],
          [
            "/etc/deleted changed managed",
            "/etc/cron.daily/cleanup",
            "/etc/cron.daily/logrotate"
          ]
        )
      }.to_not raise_error
    end
  end
end
