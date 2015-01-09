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

describe Os do

  it "returns list of Os sub classes it can build" do
    buildable = OsSles12.buildable_systems

    expect(buildable).to be_a(Array)
    buildable.each do |target_os|
      expect(target_os < Os).to be true
    end
  end

  it "SLES 12 can build SLES 12" do
    expect(OsSles12.buildable_systems).to include OsSles12
  end

  it "returns if SLES 12 can run machinery from class" do
    expect(OsSles12.can_run_machinery?).to be(true)
  end

  it "returns if SLES 12 can run machinery from object" do
    expect(OsSles12.new.can_run_machinery?).to be(true)
  end

  it "returns if SLES 12 can build SLES 11 and SLES 12" do
    os = OsSles12.new(architecture: "x86_64")

    expect(os.can_build?(OsSles12.new(architecture: "x86_64"))).to be(true)
    expect(os.can_build?(OsSles11.new(architecture: "x86_64"))).to be(false)
    expect(os.can_build?(OsSles12.new(architecture: "i586"))).to be(false)
  end

  it "returns if SLES 11 can build SLES 11 and SLES 12" do
    os = OsSles11.new(architecture: "x86_64")

    expect(os.can_build?(OsSles12.new(architecture: "x86_64"))).to be(false)
    expect(os.can_build?(OsSles12.new(architecture: "x86_64"))).to be(false)
    expect(os.can_build?(OsSles12.new(architecture: "i586"))).to be(false)
  end

  it "returns a display name from the class" do
    expect(OsSles12.canonical_name).to eq "SUSE Linux Enterprise Server 12"
  end

  it "returns a display name from the object" do
    expect(OsSles12.new.canonical_name).to eq "SUSE Linux Enterprise Server 12"
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

  describe ".supported_host_systems" do
    it "provides classes of all operating systems which are supported" do
      expect(Os.supported_host_systems).to match_array(
        [OsSles12, OsOpenSuse13_1, OsOpenSuse13_2]
      )
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
    expect(Os.for("unknown OS name")).to be_a(OsUnknown)
  end

  it "initializes name with canonical name" do
    os_name = "SUSE Linux Enterprise Server 12"
    expect(Os.for(os_name).name).to eq os_name
  end
end
