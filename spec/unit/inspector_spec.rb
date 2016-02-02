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


describe Inspector do
  before :each do
    stub_const("FooScope", Class.new do
      include Machinery::Scope
      def self.name; "FooScope"; end
    end)
    stub_const("FooInspector", Class.new(Inspector) do
      def self.name; "FooInspector"; end
      has_priority 2000
    end)

    stub_const("BarBazScope", Class.new do
      include Machinery::Scope
      def self.name; "BarBazScope"; end
    end)
    stub_const("BarBazInspector", Class.new(Inspector) do
      def self.name; "BarBazInspector"; end
      has_priority 1500
    end)

    stub_const("BarracudaScope", Class.new do
      include Machinery::Scope
      def self.name; "BarracudaScope"; end
    end)
    stub_const("BarracudaInspector", Class.new(Inspector) do
      def self.name; "BarracudaInspector"; end
      has_priority 1700
    end)
  end

  describe ".priority" do
    it "returns priority (default 1000)" do
      expect(Inspector.priority).to eq(1000)
    end
  end

  describe ".has_priority" do
    it "sets a priority" do
      Inspector.has_priority(10)
      expect(Inspector.priority).to eq(10)
    end
  end

  describe ".for" do
    it "returns the requested Inspector" do
      expect(Inspector.for("foo")).to eq(FooInspector)
      expect(Inspector.for("bar_baz")).to eq(BarBazInspector)
    end
  end

  describe ".all" do
    it "returns all loaded Inspectors" do
      inspectors = Inspector.all

      expect(inspectors).to include(FooInspector)
      expect(inspectors).to include(BarracudaInspector)
      expect(inspectors).to include(BarBazInspector)
    end
  end

  describe ".all_scopes" do
    it "returns all available scopes" do
      all_scopes = Inspector.all_scopes
      expect(all_scopes).to include("foo")
      expect(all_scopes).to include("bar_baz")
    end

    it "returns all scopes sorted by priority" do
      all_scopes = Inspector.all_scopes
      expect(all_scopes[-1]).to eq("foo")
      expect(all_scopes[-2]).to eq("barracuda")
      expect(all_scopes[-3]).to eq("bar_baz")
    end
  end

  describe ".sort_scopes" do
    it "sorts the three given scopes" do
      expect(Inspector.sort_scopes(["users", "os", "patterns"])).to eq(["os", "patterns", "users"])
    end

    it "sorts all scopes" do
      unsorted_list = [
        "services", "packages", "changed_managed_files", "os", "groups", "unmanaged_files",
        "config_files", "patterns", "users", "repositories"
      ]

      expected_result = [
        "os", "packages", "patterns", "repositories", "users", "groups",
        "services", "config_files", "changed_managed_files", "unmanaged_files"
      ]

      expect(Inspector.sort_scopes(unsorted_list)).to eq(expected_result)
    end
  end

  describe "#scope" do
    it "returns the un-camelcased name" do
      expect(BarBazInspector.new.scope).to eql("bar_baz")
    end
  end
end
