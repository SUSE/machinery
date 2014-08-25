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

describe Os do

  it "returns list of Os sub classes it can build" do
    os = OsSles12.new

    expect(os.can_build).to be_a(Array)
    os.can_build.each do |target_os|
      expect(target_os < Os).to be true
    end
  end

  it "SLES 12 can build SLES 12" do
    os = OsSles12.new

    expect(os.can_build).to include OsSles12
  end

  it "returns if it can build an Os given as class" do
    os = OsSles12.new

    expect(os.can_build?(OsSles12)).to be true
    expect(os.can_build?(OsSles11)).to be false
  end

  it "returns if it can build an Os given as instance" do
    os = OsSles12.new

    expect(os.can_build?(OsSles12.new)).to be true
    expect(os.can_build?(OsSles11.new)).to be false
  end

  it "returns a display name" do
    expect(OsSles12.new.name).to eq "SUSE Linux Enterprise Server 12"
  end

  describe "#module_required_by_package" do
    it "returns the module's name for a package" do
      os = OsSles12.new
      expect(os.module_required_by_package("python-glanceclient")).to eq("Public Cloud Module")
    end

    it "returns nil if no module is required for a package" do
      os = OsSles11.new
      expect(os.module_required_by_package("python-glanceclient")).to eq(nil)
    end
  end

  it "returns list of subclasses" do
    expect(Os.descendants).to be_a(Array)
    expect(Os.descendants.count).to be >= 3
    expect(Os.descendants).to include OsSles12
    expect(Os.descendants).to include OsOpenSuse13_1
  end

  it "returns os object for os name string" do
    expect(Os.for("SUSE Linux Enterprise Server 12")).to be_a(OsSles12)
    expect(Os.for("openSUSE 13.1 (Bottle)")).to be_a(OsOpenSuse13_1)
    expect {
      Os.for("unknow OS name")
    }.to raise_error(Machinery::Errors::UnknownOs)
  end

end
