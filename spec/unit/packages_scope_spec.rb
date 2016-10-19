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

# See os_scope_spec.rb for an explanation of the intention and scope of these
# tests.

describe Machinery::PackagesScope do

  it "keeps values" do
    packages_scope = Machinery::PackagesScope.new
    packages_scope << Machinery::Package.new(name: "PACK1", version: "1.0")
    packages_scope << Machinery::Package.new(name: "PACK2", version: "2.1")

    expect(packages_scope.size).to eq(2)
    expect(packages_scope[0].name).to eq("PACK1")
    expect(packages_scope[0].version).to eq("1.0")
    expect(packages_scope[1].name).to eq("PACK2")
    expect(packages_scope[1].version).to eq("2.1")
  end

  it "keeps meta data" do
    date = DateTime.now
    packages_scope = Machinery::PackagesScope.new
    packages_scope.set_metadata(date, "SOMEHOST")

    expect(packages_scope.meta.modified).to eq(date)
    expect(packages_scope.meta.hostname).to eq("SOMEHOST")
  end

  describe "compares" do
    before(:each) do
      @package1 = Machinery::Package.new(name: "PACK1", version: "1.0")
      @package2 = Machinery::Package.new(name: "PACK2", version: "2.1")
      @package3 = Machinery::Package.new(name: "PACK3", version: "4.5.6")
      @package4_1 = Machinery::Package.new(name: "PACK4", version: "4.5.6")
      @package4_2 = Machinery::Package.new(name: "PACK4", version: "4.5.7")

      @packages_scope1 = Machinery::PackagesScope.new
      @packages_scope1 << @package1 << @package2 << @package4_1

      @packages_scope2 = Machinery::PackagesScope.new
      @packages_scope2 << @package1 << @package2 << @package4_1

      @packages_scope3 = Machinery::PackagesScope.new
      @packages_scope3 << @package1 << @package3 << @package4_2
    end

    it "equal objects" do
      expect(@packages_scope1 == @packages_scope2).to be(true)
      expect(@packages_scope1.eql?(@packages_scope2)).to be(true)

      only_scope1, only_scope2, changed, common = @packages_scope1.compare_with(@packages_scope2)

      expect(only_scope1).to be(nil)
      expect(only_scope2).to be(nil)
      expect(changed).to be(nil)

      expect(common.size).to eq(3)
      expect(common[0]).to eq(@package1)
      expect(common[1]).to eq(@package2)
      expect(common[2]).to eq(@package4_1)
    end

    it "unequal objects" do
      expect(@packages_scope1 == @packages_scope3).to be(false)
      expect(@packages_scope1.eql?(@packages_scope3)).to be(false)

      only_scope1, only_scope2, changed, common = @packages_scope1.compare_with(@packages_scope3)

      expect(only_scope1.size).to eq(1)
      expect(only_scope1[0]).to eq(@package2)

      expect(only_scope2.size).to eq(1)
      expect(only_scope2[0]).to eq(@package3)

      expect(common.size).to eq(1)
      expect(common[0]).to eq(@package1)

      expect(changed.size).to eq(1)
      expect(changed[0][0]).to eq(@package4_1)
      expect(changed[0][1]).to eq(@package4_2)
    end
  end

end
