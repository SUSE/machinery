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

describe OsBuild do
  before(:each) do
    @osbuild = OsBuild.new([:OsSLE12], :OsSLE12)
    @os12build = OsSLE12.new(:OsSLE12)
  end

  describe "#can_build?" do
    it "returns true" do
      expect(@osbuild.can_build?).to be(true)
    end
  end

  describe "#self.instance_for" do
    it "returns OsSLE12 instance for SUSE Linux Enterprise Server 12 buildhost" do
      expect(OsBuild.instance_for("SUSE Linux Enterprise Server 12", "openSUSE 13.1 (Bottle)")).to be_a(OsSLE12)
    end
  end

  describe "#self.supported_buildhost?" do
    it "returns true for SUSE Linux Enterprise Server 12" do
      expect(OsBuild.supported_buildhost?("SUSE Linux Enterprise Server 12")).to be(true)
    end
  end

  describe "#can_build" do
    it "returns SUSE Linux Enterprise Server 12" do
      expect(@osbuild.can_build).to eq("SUSE Linux Enterprise Server 12")
    end
  end

  describe "#os_name" do
    it "returns SUSE Linux Enterprise Server 12" do
      expect(@os12build.os_name).to eq("SUSE Linux Enterprise Server 12")
    end
  end

  describe "#self.supported_buildhost" do
    it "returns list of supported build host systems" do
      expect(OsBuild.supported_buildhost).to eq("SUSE Linux Enterprise Server 12,openSUSE 13.1 (Bottle)")
    end
  end

  describe "#self.os_to_sym" do
    it "returns :OsSLE12" do
      expect(OsBuild.os_to_sym("SUSE Linux Enterprise Server 12")).to eq(:OsSLE12)
    end
  end

  describe "#self.sym_to_os" do
    it "returns SUSE Linux Enterprise Server 12" do
      expect(OsBuild.sym_to_os(:OsSLE12)).to eq("SUSE Linux Enterprise Server 12")
    end
  end
end
