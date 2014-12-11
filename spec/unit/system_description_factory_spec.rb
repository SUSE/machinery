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

describe SystemDescriptionFactory do
  describe ".create_test_description" do
    it "sets the name" do
      description = create_test_description(name: "abc")
      expect(description.name).to eq("abc")
    end

    it "takes a given store" do
      store = SystemDescriptionStore.new
      description = create_test_description(store: store)
      expect(description.store).to be(store)
    end

    context "with factory store" do
      initialize_system_description_factory_store

      it "creates a store which writes to disk" do
        description = create_test_description(store_on_disk: true)
        path = description.store.description_path(description.name)
        expect(File.directory?(path)).to be(true)
      end
    end

    it "uses transient store by default" do
      description = create_test_description
      expect(description.store).to be_a(SystemDescriptionMemoryStore)
    end

    it "creates minimal description from JSON" do
      description = create_test_description(json: <<-EOT
        {
          "packages": [
            {
              "name": "foo"
            }
          ]
        }
        EOT
      )

      expect(description.packages.first.name).to eq("foo")
    end

    it "creates description with example scope" do
      description = create_test_description(scopes: ["os"])

      expect(description.os.name).to eq("openSUSE 13.1 (Bottle)")
    end
  end
end
