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


describe Machinery::Inspector do
  before :each do
    stub_const("Machinery::FooScope", Class.new do
      include Machinery::Scope
      def self.name; "Machinery::FooScope"; end
    end)
    stub_const("Machinery::FooInspector", Class.new(Machinery::Inspector) do
      def self.name; "Machinery::FooInspector"; end
      has_priority 2000
    end)

    stub_const("Machinery::BarBazScope", Class.new do
      include Machinery::Scope
      def self.name; "Machinery::BarBazScope"; end
    end)
    stub_const("Machinery::BarBazInspector", Class.new(Machinery::Inspector) do
      def self.name; "Machinery::BarBazInspector"; end
      has_priority 1500
    end)

    stub_const("Machinery::BarracudaScope", Class.new do
      include Machinery::Scope
      def self.name; "Machinery::BarracudaScope"; end
    end)
    stub_const("Machinery::BarracudaInspector", Class.new(Machinery::Inspector) do
      def self.name; "Machinery::BarracudaInspector"; end
      has_priority 1700
    end)
  end

  describe ".priority" do
    it "returns priority (default 1000)" do
      expect(Machinery::Inspector.priority).to eq(1000)
    end
  end

  describe ".has_priority" do
    it "sets a priority" do
      Machinery::Inspector.has_priority(10)
      expect(Machinery::Inspector.priority).to eq(10)
    end
  end

  describe ".for" do
    it "returns the requested Inspector" do
      expect(Machinery::Inspector.for("foo")).to eq(Machinery::FooInspector)
      expect(Machinery::Inspector.for("bar_baz")).to eq(Machinery::BarBazInspector)
    end
  end

  describe ".all" do
    it "returns all loaded Inspectors" do
      inspectors = Machinery::Inspector.all

      expect(inspectors).to include(Machinery::FooInspector)
      expect(inspectors).to include(Machinery::BarracudaInspector)
      expect(inspectors).to include(Machinery::BarBazInspector)
    end
  end

  describe ".all_scopes" do
    it "returns all available scopes" do
      all_scopes = Machinery::Inspector.all_scopes
      expect(all_scopes).to include("foo")
      expect(all_scopes).to include("bar_baz")
    end

    it "returns all scopes sorted by priority" do
      all_scopes = Machinery::Inspector.all_scopes
      expect(all_scopes[-1]).to eq("foo")
      expect(all_scopes[-2]).to eq("barracuda")
      expect(all_scopes[-3]).to eq("bar_baz")
    end
  end

  describe ".sort_scopes" do
    it "sorts the three given scopes" do
      expect(Machinery::Inspector.sort_scopes(["users", "os", "patterns"])).
        to eq(["os", "patterns", "users"])
    end

    it "sorts all scopes" do
      unsorted_list = [
        "services", "packages", "changed_managed_files", "os", "groups", "unmanaged_files",
        "changed_config_files", "patterns", "users", "repositories"
      ]

      expected_result = [
        "os", "packages", "patterns", "repositories", "users", "groups",
        "services", "changed_config_files", "changed_managed_files", "unmanaged_files"
      ]

      expect(Machinery::Inspector.sort_scopes(unsorted_list)).to eq(expected_result)
    end
  end

  describe "#scope" do
    it "returns the un-camelcased name" do
      expect(Machinery::BarBazInspector.new.scope).to eql("bar_baz")
    end
  end
end
