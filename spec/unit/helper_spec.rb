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
  before(:all) do
    # simulate a sles12 host
    class OsInspector
      alias orig_inspect inspect
      def inspect(system, description, options = {})
        json = <<-EOF
        {
          "os": {
          "name": "SUSE Linux Enterprise Server 12"
          }
        }
        EOF
        system_description = SystemDescription.from_json("localhost", json)
        description.os = system_description.os
      end
    end
  end

  after(:all) do
    class OsInspector
      alias inspect orig_inspect
      remove_method(:orig_inspect)
    end
  end

  describe ".check_package" do
    it "raises an Machinery::Errors::MissingRequirementsError error if the rpm-package isn't found" do
      package = "does_not_exist"
      expect { Machinery::check_package(package) }.to raise_error(Machinery::Errors::MissingRequirement, /#{package}/)
    end

    it "doesn't raise an error if the package exists" do
      expect { Machinery::check_package("bash") }.not_to raise_error
    end
  end

  describe ".check_build_compatible_host" do
    # let us build a sles11 system which is unsupported on sle12 host
    let(:system_description) {
      json = <<-EOF
      {
        "os": {
        "name": "SUSE Linux Enterprise Server 11"
        }
      }
      EOF
      system_description = SystemDescription.from_json("localhost", json)
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
end
