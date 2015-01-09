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

# These tests exercise a representative part of the public API of the scope
# class in order to make sure that the scope object is constructed correctly
# and the API works as expected. They are not meant to exhaustively test the
# implementation of the underlying classes providing the API.
#
# These tests are supposed to not change much when the implementation of the
# scopes is changed, so they can serve as documentation of the API and basic
# expectations towards the API.
#
# Testing on this concrete level makes it easier to see that the scopes work
# in general. Only testing this on the more abstract level of the classes used
# to implement the scopes bears the risk of missing cases or only exposing them
# implicitly in other tests where they are harder to diagnose. This helps
# especially when refactoring the implementation of the scopes.

describe Os do

  it "keeps values" do
    os_scope = Os.new
    os_scope.name = "OS NAME"
    os_scope.version = "x.y"

    expect(os_scope.name).to eq("OS NAME")
    expect(os_scope.version).to eq("x.y")
  end

  it "keeps meta data" do
    date = DateTime.now
    os_scope = Os.new
    os_scope.set_metadata(date, "SOMEHOST")

    expect(os_scope.meta.modified).to eq(date)
    expect(os_scope.meta.hostname).to eq("SOMEHOST")
  end

  describe "compares" do
    before(:each) do
      @os_scope1 = Os.new
      @os_scope1.name = "OS1"
      @os_scope1.version = "x"

      @os_scope2 = Os.new
      @os_scope2.name = "OS1"
      @os_scope2.version = "x"

      @os_scope3 = Os.new
      @os_scope3.name = "OS2"
      @os_scope3.version = "y"
    end

    it "equal objects" do
      expect(@os_scope1 == @os_scope2).to be(true)
      expect(@os_scope1.eql?(@os_scope2)).to be(true)
      expect(@os_scope1.compare_with(@os_scope2)).to eq([nil, nil, @os_scope1])
    end

    it "unequal objects" do
      expect(@os_scope1 == @os_scope3).to be(false)
      expect(@os_scope1.eql?(@os_scope3)).to be(false)
      expect(@os_scope1.compare_with(@os_scope3)).to eq([@os_scope1, @os_scope3, nil])
    end
  end

end
