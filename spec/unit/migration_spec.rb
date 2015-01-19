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

describe Migration do
  initialize_system_description_factory_store

  let(:store) { system_description_factory_store }

  before(:each) do
    stub_const(
      "Migrate1To2", Class.new(Migration) do
        desc "Migrate version 1 to 2"
        def migrate; end
      end
    )
    stub_const(
      "Migrate2To3", Class.new(Migration) do
        desc "Migrate version 2 to 3"
        def migrate; end
      end
    )
    stub_const(
      "Migrate3To4", Class.new(Migration) do
        # Bad migration, it does not describe its purpose.
        def migrate; end
      end
    )

    stub_const("SystemDescription::CURRENT_FORMAT_VERSION", 3)
    stub_const("Machinery::DEFAULT_CONFIG_DIR", store.base_path)
    [1, 2, 3].each do |version|
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

    stub_const("Migration::MIGRATIONS_DIR", migrations_dir)
    File.write(migration_path, <<-EOF)
     class MigrateFoo < Migration; end
    EOF
    create_test_description(store_on_disk: true)

    expect_any_instance_of(Kernel).to receive(:require).with(migration_path)

    Migration.migrate_description(store, "description")
  end

  describe ".migrate_system_description" do
    before(:each) do
      allow(Migration).to receive(:load_migrations)
    end

    it "migrates old descriptions" do
      expect_any_instance_of(Migrate1To2).to receive(:migrate)
      expect_any_instance_of(Migrate2To3).to receive(:migrate)

      Migration.migrate_description(store, "v1_description")
      description = SystemDescription.load("v1_description", store)
      expect(description.format_version).to eq(SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "only runs relevant migrations" do
      expect_any_instance_of(Migrate1To2).to_not receive(:migrate)
      expect_any_instance_of(Migrate2To3).to receive(:migrate)

      Migration.migrate_description(store, "v2_description")
      description = SystemDescription.load("v2_description", store)
      expect(description.format_version).to eq(SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "doesn't run migrations when there's nothing to do" do
      expect_any_instance_of(Migrate1To2).to_not receive(:migrate)
      expect_any_instance_of(Migrate2To3).to_not receive(:migrate)

      Migration.migrate_description(store, "v3_description")
      description = SystemDescription.load("v3_description", store)
      expect(description.format_version).to eq(SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "makes the hash and path available as instance variables in the migrations" do
      manifest = Manifest.load("v2_description", store.manifest_path("v2_description"))
      validate_environment = ->(hash, path) {
        expect(hash).to eq(manifest.to_hash)
        expect(path).to eq(store.description_path("v2_description.backup"))
      }

      Migrate2To3.send(:define_method, :migrate) do
        validate_environment.call(@hash, @path)
      end

      Migration.migrate_description(store, "v2_description")
    end

    it "refuses to run migrations without a migration_desc" do
      stub_const("SystemDescription::CURRENT_FORMAT_VERSION", 4)
      expect {
        Migration.migrate_description(store, "v3_description")
      }.to raise_error(Machinery::Errors::MigrationError, /Invalid migration 'Migrate3To4'/)
    end
  end
end
