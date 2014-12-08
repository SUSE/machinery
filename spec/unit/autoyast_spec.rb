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

describe Autoyast do
  initialize_system_description_factory_store

  let(:expected_profile) {
    File.read(File.join(Machinery::ROOT, "spec/data/autoyast/simple.xml"))
  }
  let(:description) {
    description = create_test_description(
      store_on_disk: true,
      extracted_scopes: [
        "config_files",
        "changed_managed_files",
        "unmanaged_files"
      ],
      scopes: [
        "packages",
        "patterns",
        "repositories",
        "users_with_passwords",
        "groups",
        "services"
      ]
    )

    description
  }

  describe "#profile" do
    it "creates the expected profile" do
      autoyast = Autoyast.new(description)

      expect(autoyast.profile).to eq(expected_profile)
    end
  end

  describe "#write" do
    around(:each) do |example|
      autoyast = Autoyast.new(description)
      Dir.mktmpdir("autoyast_export_test") do |dir|
        @output_dir = dir
        autoyast.write(@output_dir)

        example.run
      end
    end

    it "copies over the system description" do
      expect(File.exists?(File.join(@output_dir, "manifest.json"))).to be(true)
    end

    it "adds the autoinst.xml" do
      expect(File.exists?(File.join(@output_dir, "autoinst.xml"))).to be(true)
    end
  end
end
