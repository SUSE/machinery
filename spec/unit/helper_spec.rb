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

describe Machinery do
  describe ".check_package" do
    it "raises an Machinery::Errors::MissingRequirementsError error if the rpm-package isn't found" do
      allow_any_instance_of(SystemDescription).to receive(:os_object).and_return(Os.new)
      package = "does_not_exist"
      expect { Machinery::check_package(package) }.to raise_error(Machinery::Errors::MissingRequirement, /#{package}/)
    end

    it "doesn't raise an error if the package exists" do
      expect { Machinery::check_package("bash") }.not_to raise_error
    end

    it "explains how to install a missing package from a module on SLES12" do
      allow(LocalSystem).to receive(:os_object).and_return(OsSles12.new)
      allow(Cheetah).to receive(:run).and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      expect {
        Machinery::check_package("python-glanceclient")
      }.to raise_error(Machinery::Errors::MissingRequirement, /Public Cloud Module/)
     end
  end

  describe ".check_build_compatible_host" do
    before(:each) do
      allow(LocalSystem).to receive(:os_object).and_return(OsSles12.new)
    end

    # let us build a sles11 system which is unsupported on sle12 host
    let(:system_description) {
      create_test_description(<<-EOF)
      {
        "os": {
        "name": "SUSE Linux Enterprise Server 11"
        }
      }
      EOF
    }

    it "raises an Machinery::UnsupportedHostForImageError error if the host for image build combination is unsupported" do
      expect { Machinery::check_build_compatible_host(system_description) }.to raise_error(Machinery::Errors::BuildFailed, /#{system_description.os.name}/)
    end

    it "doesn't raise if host and image builds a valid combination" do
      # let us build a sles12 system which is supported on sle12 host
      system_description.os.name = "SUSE Linux Enterprise Server 12"
      expect { Machinery::check_build_compatible_host(system_description) }.not_to raise_error
    end
  end

  describe ".is_int?" do
    it "returns true if the string only consists numbers" do
      expect(Machinery::is_int?("12345")).to be(true)
      expect(Machinery::is_int?("1")).to be(true)
    end

    it "returns false if the string consist any chars than numbers" do
      expect(Machinery::is_int?(" 12345")).to be(false)
      expect(Machinery::is_int?("12456 ")).to be(false)
      expect(Machinery::is_int?("1a2")).to be(false)
      expect(Machinery::is_int?("1 ")).to be(false)
      expect(Machinery::is_int?(" 1")).to be(false)
      expect(Machinery::is_int?("")).to be(false)
    end

  end
end
