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

describe UpgradeFormatTask do
  initialize_system_description_factory_store
  silence_machinery_output

  let(:outdated_json) {<<-EOF
    {
      "meta": {
        "format_version": 0
      }
   }
   EOF
  }

  class Migrate0To1 < Migration
    desc "Dummy migration migrating our dummy descriptions to version 1"
    def migrate; end
  end

  describe "#upgrade" do
    before(:each) do
      store_raw_description("description1", outdated_json)
      store_raw_description("description2", outdated_json)
    end

    it "upgrades a specific system description" do
      expect {
        system_description_factory_store.load("description1")
      }.to raise_error(Machinery::Errors::SystemDescriptionError)

      UpgradeFormatTask.new.upgrade(system_description_factory_store, "description1")

      migrated_description = system_description_factory_store.load("description1")
      expect(migrated_description.format_version).to eq(SystemDescription::CURRENT_FORMAT_VERSION)

      # description2 should still be in the old format
      expect {
        system_description_factory_store.load("description2")
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
    end

    it "upgrades all system descriptions when the --all switch is given" do
      expect {
        system_description_factory_store.load("description2")
      }.to raise_error(Machinery::Errors::SystemDescriptionError)

      UpgradeFormatTask.new.upgrade(system_description_factory_store, nil, :all => true)

      ["description1", "description2"].each do |description|
        migrated_description = system_description_factory_store.load(description)
        expect(migrated_description.format_version).to eq(SystemDescription::CURRENT_FORMAT_VERSION)
      end
    end
  end
end
