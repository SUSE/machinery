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

# See os_scope_spec.rb for an explanation of the intention and scope of these
# tests.

describe PackagesScope do

  it "keeps values" do
    packages_scope = PackagesScope.new
    packages_scope << Package.new(name: "PACK1", version: "1.0")
    packages_scope << Package.new(name: "PACK2", version: "2.1")

    expect(packages_scope.size).to eq(2)
    expect(packages_scope[0].name).to eq("PACK1")
    expect(packages_scope[0].version).to eq("1.0")
    expect(packages_scope[1].name).to eq("PACK2")
    expect(packages_scope[1].version).to eq("2.1")
  end

  it "keeps meta data" do
    date = DateTime.now
    packages_scope = PackagesScope.new
    packages_scope.set_metadata(date, "SOMEHOST")

    expect(packages_scope.meta.modified).to eq(date)
    expect(packages_scope.meta.hostname).to eq("SOMEHOST")
  end

  describe "compares" do
    before(:each) do
      @package1 = Package.new(name: "PACK1", version: "1.0")
      @package2 = Package.new(name: "PACK2", version: "2.1")
      @package3 = Package.new(name: "PACK3", version: "4.5.6")

      @packages_scope1 = PackagesScope.new
      @packages_scope1 << @package1 << @package2

      @packages_scope2 = PackagesScope.new
      @packages_scope2 << @package1 << @package2

      @packages_scope3 = PackagesScope.new
      @packages_scope3 << @package1 << @package3
    end

    it "equal objects" do
      expect(@packages_scope1 == @packages_scope2).to be(true)
      expect(@packages_scope1.eql?(@packages_scope2)).to be(true)

      only_in_scope1, only_in_scope2, common = @packages_scope1.compare_with(@packages_scope2)

      expect(only_in_scope1).to be(nil)
      expect(only_in_scope2).to be(nil)

      expect(common.size).to eq(2)
      expect(common[0]).to eq(@package1)
      expect(common[1]).to eq(@package2)
    end

    it "unequal objects" do
      expect(@packages_scope1 == @packages_scope3).to be(false)
      expect(@packages_scope1.eql?(@packages_scope3)).to be(false)

      only_in_scope1, only_in_scope2, common = @packages_scope1.compare_with(@packages_scope3)

      expect(only_in_scope1.size).to eq(1)
      expect(only_in_scope1[0]).to eq(@package2)

      expect(only_in_scope2.size).to eq(1)
      expect(only_in_scope2[0]).to eq(@package3)

      expect(common.size).to eq(1)
      expect(common[0]).to eq(@package1)
    end
  end

end
