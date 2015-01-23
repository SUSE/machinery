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

describe SystemDescriptionStore do
  include_context "machinery test directory"

  describe "#initialize" do
    it "sets base_path to ~/.machinery if no parameter is provided" do
      default_path = File.join(ENV['HOME'], ".machinery")
      store = SystemDescriptionStore.new
      expect(store.base_path).to eq(default_path)
    end

    it "sets base_path if parameter is provided" do
      custom_path = "/var/cache/.machinery"
      store = SystemDescriptionStore.new(custom_path)
      expect(store.base_path).to eq(custom_path)
    end

    it "creates the directory with correct permissions if it doesn't exist" do
      expect(Dir.exists?(File.join(ENV['HOME'], ".machinery"))).to be(false)
      store = SystemDescriptionStore.new

      expect(Dir.exists?(store.base_path)).to be(true)
      expect(File.stat(store.base_path).mode & 0777).to eq(0700)
    end

    it "keeps directory permissions if base dir already exists" do
      store = SystemDescriptionStore.new
      alfdir = store.base_path
      File.chmod(0755, alfdir)
      store = SystemDescriptionStore.new

      expect(Dir.exists?(store.base_path)).to be(true)
      expect(File.stat(store.base_path).mode & 0777).to eq(0755)
    end
  end

  describe "#load" do
    before(:each) do
      create_machinery_dir
      @store = SystemDescriptionStore.new(test_base_path)
    end

    it "loads a SystemDescription" do
      description = SystemDescription.load(test_name, @store)

      expect(description.to_json).to eq(test_manifest)
      expect(description.name).to eq(test_name)
    end

    it "validates that the system description is compatible" do
      expect_any_instance_of(SystemDescription).to receive(:validate_compatibility)

      SystemDescription.load(test_name, @store)
    end
  end

  describe "#description_path" do
    it "returns correct path" do
      name = "test"
      store = SystemDescriptionStore.new(test_base_path)
      expect(store.description_path(name)).to eq(File.join(test_base_path, name))
    end
  end

  describe "#manifest_path" do
    it "returns correct path" do
      name = "test"
      store = SystemDescriptionStore.new(test_base_path)
      expect(store.manifest_path(name)).to eq(
        File.join(store.description_path(name), "manifest.json"))
    end
  end

  describe "#html_path" do
    it "returns correct html path" do
      name = "test"
      store = SystemDescriptionStore.new(test_base_path)
      expect(store.html_path(name)).to eq(
        File.join(store.description_path(name), "index.html"))
    end
  end

  describe "#list" do
    it "returns list of existing system descriptions" do
      create_machinery_dir
      store = SystemDescriptionStore.new(test_base_path)
      expect(store.list).to eq([test_name])
    end

    it "returns empty list if no system descriptions are available" do
      store = SystemDescriptionStore.new
      expect(store.list).to eq([])
    end
  end

  describe "#remove" do
    it "removes an existing SystemDescription" do
      create_machinery_dir
      store = SystemDescriptionStore.new(test_base_path)
      expect(store.list).to eq([test_name])

      store.remove(test_name)
      expect(store.list).to be_empty
    end

    it "raises an error if an empty name was provided" do
      store = SystemDescriptionStore.new(test_base_path)
      expect {
        store.remove("")
      }.to raise_error(RuntimeError, /description has no name specified/)
    end
  end

  describe "#copy" do
    let(:store) { SystemDescriptionStore.new(test_base_path) }
    let(:new_name) { "description2" }

    before(:each) do
      create_machinery_dir
    end

    it "copies an existing SystemDescription" do
      expect(store.list).to eq([test_name])
      store.copy(test_name, new_name)
      expect(store.list).to eq([test_name, new_name])
    end

    it "throws an error when the to be copied SystemDescription does not exist" do
      expect {
        store.copy("foo_bar_does_not_exist", new_name)
      }.to raise_error(Machinery::Errors::SystemDescriptionNotFound, /foo_bar_does_not_exist/)
    end

    it "throws an error when the new name already exists" do
      store.copy(test_name, new_name)
      expect(store.list).to include(new_name)
      expect {
        store.copy(test_name, new_name)
      }.to raise_error(Machinery::Errors::SystemDescriptionError, /#{new_name}/)
    end
  end

  describe "#directory_for" do
    it "creates sub directory for system description" do
      path = "/tmp/test_dir"
      store = SystemDescriptionStore.new(path)
      name = "my_description"

      dir = store.directory_for(name)

      expect(dir).to eq(File.join(path, name))
      expect(File.exist?(dir)).to be(true)
      expect(File.stat(dir).mode).to eq 0100700
    end
  end

  describe "#backup" do
    let(:store) { SystemDescriptionStore.new(test_base_path) }

    before(:each) do
      create_machinery_dir
    end

    it "backups an existing SystemDescription" do
      expect(store.list).to eq([test_name])
      store.backup(test_name)
      expect(store.list).to match_array([test_name, test_name + ".backup"])
    end

    it "it raises the backup number if a backup already exists" do
      expect(store.list).to eq([test_name])
      3.times do
        store.backup(test_name)
      end
      expect(store.list).to match_array(
        [test_name, test_name + ".backup", test_name + ".backup.1", test_name + ".backup.2"]
      )
    end

    it "returns the backup name" do
      expect(store.backup(test_name)).to eq(test_name + ".backup")
    end
  end

  describe "#rename" do
    let(:store) { SystemDescriptionStore.new(test_base_path) }
    let(:new_name) { "description2" }

    before(:each) do
      create_machinery_dir
    end

    it "renames an existing system description" do
      expect(store.list).to eq([test_name])
      store.rename(test_name, new_name)
      expect(store.list).to eq([new_name])
    end

    it "throws an error when the to be renamed system description does not exist" do
      expect {
        store.rename("foo_bar_does_not_exist", new_name)
      }.to raise_error(Machinery::Errors::SystemDescriptionNotFound, /foo_bar_does_not_exist/)
    end

    it "throws an error when the new name already exists" do
      store.copy(test_name, new_name)
      expect(store.list).to include(new_name)
      expect {
        store.rename(test_name, new_name)
      }.to raise_error(Machinery::Errors::SystemDescriptionError, /#{new_name}/)
    end
  end

  describe "#swap" do
    let(:store) { SystemDescriptionStore.new(test_base_path) }
    let(:test_name_2) { "description2" }

    before(:each) do
      create_machinery_dir

      FileUtils.mkdir_p(File.join(test_base_path, test_name_2))
      File.write(
        File.join(test_base_path, test_name_2, "manifest.json"),
        create_test_description(scopes: ["packages", "patterns"]).to_json
      )
    end

    it "swaps two existing SystemDescriptions" do
      expect(
        Dir.entries(File.join(test_base_path, test_name))
      ).to match_array([".", "..", "manifest.json"])
      description = SystemDescription.load(test_name, store)
      expect(description.scopes).to match_array(["packages"])

      expect(
        Dir.entries(File.join(test_base_path, test_name_2))
      ).to match_array([".", "..", "manifest.json"])
      description = SystemDescription.load(test_name_2, store)
      expect(description.scopes).to match_array(["packages", "patterns"])

      store.swap(test_name, test_name_2)

      expect(
        Dir.entries(File.join(test_base_path, test_name))
      ).to match_array([".", "..", "manifest.json"])
      description = SystemDescription.load(test_name, store)
      expect(description.scopes).to match_array(["packages", "patterns"])

      expect(
        Dir.entries(File.join(test_base_path, test_name_2))
      ).to match_array([".", "..", "manifest.json"])
      description = SystemDescription.load(test_name_2, store)
      expect(description.scopes).to match_array(["packages"])
    end

    it "throws an error when the system descriptions does not exist" do
      expect {
        store.swap("foo_bar_does_not_exist", test_name_2)
      }.to raise_error(Machinery::Errors::SystemDescriptionNotFound, /foo_bar_does_not_exist/)

      expect {
        store.swap(test_name, "foo_bar_does_not_exist")
      }.to raise_error(Machinery::Errors::SystemDescriptionNotFound, /foo_bar_does_not_exist/)
    end
  end
end
