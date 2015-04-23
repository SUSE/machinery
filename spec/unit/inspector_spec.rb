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


describe Inspector do
  before :each do
    class FooInspector < Inspector
    end

    class BarBazInspector < Inspector
    end

    class BarracudaInspector < Inspector
    end
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
  end

  describe "#scope" do
    it "returns the un-camelcased name" do
      expect(BarBazInspector.new.scope).to eql("bar_baz")
    end
  end
end
