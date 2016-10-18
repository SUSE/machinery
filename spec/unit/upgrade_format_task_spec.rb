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

describe Machinery::UpgradeFormatTask do
  capture_machinery_output
  initialize_system_description_factory_store

  let(:outdated_json) {<<-EOF
    {
      "meta": {
        "format_version": 1
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
        Machinery::SystemDescription.load("description1", system_description_factory_store)
      }.to raise_error(Machinery::Errors::SystemDescriptionError)

      Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, "description1")
      allow(captured_machinery_output)
      expect(captured_machinery_output).to match(/upgraded/)


      migrated_description = Machinery::SystemDescription.load(
        "description1", system_description_factory_store
      )
      expect(migrated_description.format_version).
        to eq(Machinery::SystemDescription::CURRENT_FORMAT_VERSION)

      # description2 should still be in the old format
      expect {
        Machinery::SystemDescription.load("descriptions2",
          system_description_factory_store)
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
    end

    it "doesn't upgrade an up to date system description" do
      Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, "description1")
      Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, "description1")
      expect(captured_machinery_output).to include("No upgrade necessary")
    end

    it "upgrades all system descriptions when the --all switch is given" do
      expect {
        Machinery::SystemDescription.load("descriptions2", system_description_factory_store)
      }.to raise_error(Machinery::Errors::SystemDescriptionError)

      Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, nil, all: true)
      allow(captured_machinery_output)
      expect(captured_machinery_output).to include("Upgraded 2 system descriptions.")

      ["description1", "description2"].each do |description|
        migrated_description = Machinery::SystemDescription.load(description,
          system_description_factory_store)
        expect(migrated_description.format_version).
          to eq(Machinery::SystemDescription::CURRENT_FORMAT_VERSION)
      end
    end

    it "lists each system description and its status during upgrade" do
      expected_output = <<-EOF
Reading 'description1' ... Successfully upgraded from version 1 to #{Machinery::SystemDescription::CURRENT_FORMAT_VERSION}.
Reading 'description2' ... No upgrade necessary.
Upgraded 1 system description.
EOF
      Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, "description2")
      Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, nil, all: true)
      expect(captured_machinery_output).to include(expected_output)
    end

    it "lists each upgraded system description" do
      expect {
        Machinery::SystemDescription.load("descriptions2", system_description_factory_store)
      }.to raise_error(Machinery::Errors::SystemDescriptionError)

      expected_output = <<-EOF
Reading 'description1' ... Successfully upgraded from version 1 to #{Machinery::SystemDescription::CURRENT_FORMAT_VERSION}.
Reading 'description2' ... Successfully upgraded from version 1 to #{Machinery::SystemDescription::CURRENT_FORMAT_VERSION}.
Upgraded 2 system descriptions.
EOF
      Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, nil, all: true)
      expect(captured_machinery_output).to include(expected_output)
    end

    it "handles failed upgrades and continues" do
      stub_const("Migrate1To2", Class.new do
        def migrate; raise StandardError.new; end
      end)

      expect {
        Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, nil, all: true)
      }.to raise_error(
        Machinery::Errors::UpgradeFailed,
        /Upgrading description '.*' failed:\n.*\nUpgrading description '.*' failed:\n.*/i
      )
    end

    it "shows hint if migration fails" do
      stub_const("Migrate1To2", Class.new do
        def migrate; raise StandardError.new; end
      end)
      expect(Hint).to receive(:to_string).with(:upgrade_format_force, name: "description1")
      expect {
        Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, "description1")
      }.to raise_error
    end

    it "shows hint if upgrade-format --all fails" do
      stub_const("Migrate1To2", Class.new do
        def migrate; raise StandardError.new; end
      end)
      expect(Hint).to receive(:to_string).with(:upgrade_format_force, name: "--all")
      expect {
        Machinery::UpgradeFormatTask.new.upgrade(system_description_factory_store, nil, all: true)
      }.to raise_error
    end
  end
end
