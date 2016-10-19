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

describe Machinery::Os do
  it "returns if SLES 12 can run machinery from class" do
    expect(Machinery::OsSles12.can_run_machinery?).to be(true)
  end

  it "returns if SLES 12 can run machinery from object" do
    expect(Machinery::OsSles12.new.can_run_machinery?).to be(true)
  end

  it "returns a canonical name from the object" do
    expect(Machinery::OsSles12.new.canonical_name).to eq "SUSE Linux Enterprise Server 12"
  end

  it "returns a canoncial name for every Os class" do
    ObjectSpace.each_object(::Class).select { |klass| klass < Machinery::Os }.each do |klass|
      expect { klass.canonical_name }.not_to raise_error
    end
  end

  describe "#module_required_by_package" do
    it "returns the module's name for a package" do
      os = Machinery::OsSles12.new
      expect(os.module_required_by_package("python-glanceclient")).to eq("Public Cloud Module")
    end

    it "returns nil if no module is required for a package" do
      os = Machinery::OsSles11.new
      expect(os.module_required_by_package("python-glanceclient")).to eq(nil)
    end
  end

  it "returns list of subclasses" do
    expect(Machinery::Os.descendants).to be_a(Array)
    expect(Machinery::Os.descendants.count).to be >= 3
    expect(Machinery::Os.descendants).to include Machinery::OsSles12
    expect(Machinery::Os.descendants).to include Machinery::OsOpenSuse13_1
    expect(Machinery::Os.descendants).to_not include Machinery::OsOpenSuse # We only want leaves
  end

  it "returns os object for os name string" do
    expect(Machinery::Os.for("SUSE Linux Enterprise Server 12")).to be_a(Machinery::OsSles12)
    expect(Machinery::Os.for("openSUSE 13.1 (Bottle)")).to be_a(Machinery::OsOpenSuse13_1)
    expect(Machinery::Os.for("unknown OS name")).to be_a(Machinery::OsUnknown)
  end

  it "initializes name with canonical name" do
    os_name = "SUSE Linux Enterprise Server 12"
    expect(Machinery::Os.for(os_name).name).to eq os_name
  end

  describe "#display_name" do
    it "returns display name for SLES 12" do
      os = Machinery::Os.for("SUSE Linux Enterprise Server 12")
      os.version = "12"
      os.architecture = "x86_64"
      expect(os.display_name).to eq("SUSE Linux Enterprise Server 12 (x86_64)")
    end

    it "returns display name for SLES 11" do
      os = Machinery::Os.for("SUSE Linux Enterprise Server 11")
      os.version = "11 SP3"
      os.architecture = "x86_64"
      expect(os.display_name).to eq("SUSE Linux Enterprise Server 11 SP3 (x86_64)")
    end

    describe "openSUSE" do
      it "returns display name for 13.1" do
        os = Machinery::Os.for("openSUSE 13.1 (Bottle)")
        os.version = "13.1 (Bottle)"
        os.architecture = "x86_64"
        expect(os.display_name).to eq("openSUSE 13.1 (x86_64)")
      end

      it "returns display name for 13.2" do
        os = Machinery::Os.for("openSUSE 13.2 (Harlequin)")
        os.version = "13.2 (Harlequin)"
        os.architecture = "x86_64"
        expect(os.display_name).to eq("openSUSE 13.2 (x86_64)")
      end
    end

    it "returns display name for an unknown OS" do
      os = Machinery::Os.for("The OS which will never exist")
      os.version = "3.14"
      os.architecture = "x87"
      expect(os.display_name).to eq("The OS which will never exist 3.14 (x87)")
    end
  end
end
