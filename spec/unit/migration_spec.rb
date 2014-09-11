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

describe Migration do
  initialize_system_description_factory_store

  class Migrate1To2 < Migration; def migrate; end; end
  class Migrate2To3 < Migration; def migrate; end; end

  let(:store) { system_description_factory_store }

  before(:each) do
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

  describe ".migrate_system_description" do
    it "migrates old descriptions" do
      expect_any_instance_of(Migrate1To2).to receive(:migrate)
      expect_any_instance_of(Migrate2To3).to receive(:migrate)

      Migration.migrate_description(store, "v1_description")
      description = store.load("v1_description")
      expect(description.format_version).to eq(SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "only runs relevant migrations" do
      expect_any_instance_of(Migrate1To2).to_not receive(:migrate)
      expect_any_instance_of(Migrate2To3).to receive(:migrate)

      Migration.migrate_description(store, "v2_description")
      description = store.load("v2_description")
      expect(description.format_version).to eq(SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "doesn't run migrations when there's nothing to do" do
      expect_any_instance_of(Migrate1To2).to_not receive(:migrate)
      expect_any_instance_of(Migrate2To3).to_not receive(:migrate)

      Migration.migrate_description(store, "v3_description")
      description = store.load("v3_description")
      expect(description.format_version).to eq(SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "makes the hash and path available as instance variables in the migrations" do
      validate_environment = ->(hash, path) {
        expect(hash).to eq(JSON.parse(store.load_json("v2_description")))
        expect(path).to eq(store.description_path("v2_description"))
      }

      Migrate2To3.send(:define_method, :migrate) do
        validate_environment.call(@hash, @path)
      end

      Migration.migrate_description(store, "v2_description")
    end
  end
end
