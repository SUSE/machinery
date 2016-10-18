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

describe Machinery::Migration do
  initialize_system_description_factory_store

  let(:store) { system_description_factory_store }

  before(:each) do
    stub_const(
      "Machinery::Migrate1To2", Class.new(Machinery::Migration) do
        desc "Migrate version 1 to 2"
        def migrate; end
      end
    )
    stub_const(
      "Machinery::Migrate2To3", Class.new(Machinery::Migration) do
        desc "Migrate version 2 to 3"
        def migrate; end
      end
    )
    stub_const(
      "Machinery::Migrate3To4", Class.new(Machinery::Migration) do
        desc "Migrate version 3 to 4"
        def migrate; end
      end
    )
    stub_const(
      "Machinery::Migrate4To5", Class.new(Machinery::Migration) do
        desc "Migrate version 4 to 5"
        def migrate; end
      end
    )
    stub_const(
      "Machinery::Migrate5To6", Class.new(Machinery::Migration) do
        desc "Migrate version 5 to 6"
        def migrate; end
      end
    )
    stub_const(
      "Machinery::Migrate6To7", Class.new(Machinery::Migration) do
        desc "Migrate version 6 to 7"
        def migrate; end
      end
    )
    stub_const(
      "Machinery::Migrate7To8", Class.new(Machinery::Migration) do
        # Bad migration, it does not describe its purpose.
        def migrate; end
      end
    )

    stub_const("Machinery::SystemDescription::CURRENT_FORMAT_VERSION", 7)
    stub_const("Machinery::DEFAULT_CONFIG_DIR", store.base_path)
    1.upto(Machinery::SystemDescription::CURRENT_FORMAT_VERSION).each do |version|
      store_raw_description("v#{version}_description", <<-EOF)
        {
          "meta": {
            "format_version": #{version}
          }
        }
      EOF
    end
  end

  it "loads migration definitions" do
    migrations_dir = given_directory
    migration_path = File.join(migrations_dir, "migratefoo.rb")

    stub_const("Machinery::Migration::MIGRATIONS_DIR", migrations_dir)
    File.write(migration_path, <<-EOF)
     class MigrateFoo < Machinery::Migration; end
    EOF
    create_test_description(store_on_disk: true)

    expect_any_instance_of(Kernel).to receive(:require).with(migration_path)

    Machinery::Migration.migrate_description(store, "description")
  end

  describe ".migrate_system_description" do
    capture_machinery_output
    before(:each) do
      allow(Machinery::Migration).to receive(:load_migrations)
    end

    it "migrates old descriptions" do
      expect_any_instance_of(Machinery::Migrate1To2).to receive(:migrate)
      expect_any_instance_of(Machinery::Migrate2To3).to receive(:migrate)

      Machinery::Migration.migrate_description(store, "v1_description")
      description = Machinery::SystemDescription.load("v1_description", store)
      expect(description.format_version).to eq(Machinery::SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "only runs relevant migrations" do
      expect_any_instance_of(Machinery::Migrate1To2).to_not receive(:migrate)
      expect_any_instance_of(Machinery::Migrate2To3).to receive(:migrate)

      Machinery::Migration.migrate_description(store, "v2_description")
      description = Machinery::SystemDescription.load("v2_description", store)
      expect(description.format_version).to eq(Machinery::SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "doesn't run migrations when there's nothing to do" do
      expect_any_instance_of(Machinery::Migrate1To2).to_not receive(:migrate)
      expect_any_instance_of(Machinery::Migrate2To3).to_not receive(:migrate)
      expect_any_instance_of(Machinery::Migrate3To4).to_not receive(:migrate)
      expect_any_instance_of(Machinery::Migrate4To5).to_not receive(:migrate)
      expect_any_instance_of(Machinery::Migrate5To6).to_not receive(:migrate)
      expect_any_instance_of(Machinery::Migrate6To7).to_not receive(:migrate)

      Machinery::Migration.migrate_description(store, "v7_description")
      description = Machinery::SystemDescription.load("v7_description", store)
      expect(description.format_version).to eq(Machinery::SystemDescription::CURRENT_FORMAT_VERSION)
      expect(captured_machinery_output).to include("No upgrade necessary")
    end

    it "makes the hash and path available as instance variables in the migrations" do
      manifest = Manifest.load("v2_description", store.manifest_path("v2_description"))
      validate_environment = ->(hash, path) {
        expect(hash).to eq(manifest.to_hash)
        expect(path).to eq(store.description_path("v2_description.backup"))
      }

      Machinery::Migrate2To3.send(:define_method, :migrate) do
        validate_environment.call(@hash, @path)
      end

      Machinery::Migration.migrate_description(store, "v2_description")
    end

    it "refuses to run migrations without a migration_desc" do
      stub_const("Machinery::SystemDescription::CURRENT_FORMAT_VERSION", 8)
      expect {
        Machinery::Migration.migrate_description(store, "v7_description")
      }.to raise_error(
        Machinery::Errors::MigrationError,
        /Invalid migration 'Machinery::Migrate7To8'/
      )
    end

    it "deletes the backup if the migration failed" do
      allow(Machinery::SystemDescription).
        to receive(:load!).and_raise(Machinery::Errors::SystemDescriptionError)

      expect {
        Machinery::Migration.migrate_description(store, "v1_description")
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
      expect(Dir.entries(store.base_path)).not_to include("v1_description.backup")
    end

    it "keeps the backup if --force option is enabled" do
      expect(Dir.entries(store.base_path)).to_not include("v1_description.backup")


      Machinery::Migration.migrate_description(store, "v1_description", force: :true)
      expect(Dir.entries(store.base_path)).to include("v1_description.backup")
      expect(captured_machinery_output).to match(/Saved backup to .*\/v1_description.backup/)
    end

    it "keeps the orginal description if the migration failed without --force option" do
      manifest_hash = Manifest.load(
        "v2_description", store.manifest_path("v2_description")
      ).to_hash

      allow(Machinery::SystemDescription).
        to receive(:load!).and_raise(Machinery::Errors::SystemDescriptionError)

      expect {
        Machinery::Migration.migrate_description(store, "v2_description")
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
      expect(manifest_hash).to eq(
        Manifest.load("v2_description", store.manifest_path("v2_description")).to_hash
      )
    end

    context "validation" do

      it "raises an error if validation fails when --force is not set" do
        expect_any_instance_of(Machinery::JsonValidator).to receive(:validate).
          and_return(["json error"])
        expect_any_instance_of(Machinery::FileValidator).to receive(:validate).
          and_return(["file error"])
        expect {
          Machinery::Migration.migrate_description(store, "v1_description")
        }.to raise_error(Machinery::Errors::SystemDescriptionError, /json error.*file error/m)
      end

      it "only reports validation warnings when --force is set" do
        expected_output = <<-EOF.chomp
Warning: System Description validation errors:
json error, file error
Saved backup to /tmp/given_filesystem/
EOF
        expect_any_instance_of(Machinery::JsonValidator).to receive(:validate).
          and_return(["json error"])
        expect_any_instance_of(Machinery::FileValidator).to receive(:validate).
          and_return(["file error"])
        expect {
          Machinery::Migration.migrate_description(store, "v1_description", force: true)
        }.to_not raise_error

        expect(captured_machinery_output).to include(expected_output)
      end
    end
  end
end
