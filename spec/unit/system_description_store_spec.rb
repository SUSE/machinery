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
    it "loads a SystemDescription" do
      create_machinery_dir
      store = SystemDescriptionStore.new(test_base_path)
      description = store.load(test_name)
      expect(description.to_json).to eq(test_manifest)
      expect(description.name).to eq(test_name)
    end

    it "raises Errors::SystemDescriptionNotFound if the manifest file doesn't exist" do
      store = SystemDescriptionStore.new
      expect { store.load("not_existing") }.to raise_error(Machinery::Errors::SystemDescriptionNotFound)
    end
  end

  describe "#save" do
    it "saves a SystemDescription" do
      store = SystemDescriptionStore.new(test_base_path)
      store.save(SystemDescription.from_json(test_name, test_manifest))
      descr_dir = store.description_path(test_name)
      manifest = store.manifest_path(test_name)
      expect(File.stat(descr_dir).mode & 0777).to eq(0700)
      expect(File.stat(manifest).mode & 0777).to eq(0600)
      content = File.read(manifest)
      expect(content).to eq(test_manifest)
    end

    it "keeps permissions for existing files during save" do
      store = SystemDescriptionStore.new(test_base_path)
      store.save(SystemDescription.from_json(test_name, test_manifest))

      descr_dir = store.description_path(test_name)
      File.chmod(0755,descr_dir)
      manifest = store.manifest_path(test_name)
      File.chmod(0644,manifest)

      store = SystemDescriptionStore.new(test_base_path)
      store.save(SystemDescription.from_json(test_name, test_manifest))
      expect(File.stat(descr_dir).mode & 0777).to eq(0755)
      expect(File.stat(manifest).mode & 0777).to eq(0644)
    end

    it "raises Errors::SystemDescriptionInvalid if the system description name is invalid" do
      store = SystemDescriptionStore.new
      expect { store.save(SystemDescription.from_json("invalid/slash", test_manifest)) }.to raise_error(Machinery::Errors::SystemDescriptionError)
      expect { store.save(SystemDescription.from_json(".invalid_dot", test_manifest)) }.to raise_error(Machinery::Errors::SystemDescriptionError)
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
      expect{ store.remove("") }.to raise_error(RuntimeError, /description has no name specified/)
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

  describe "file store methods" do
    before(:each) do
      create_machinery_dir
    end

    let(:store) { SystemDescriptionStore.new(test_base_path) }
    let(:file_store_name) { "foo" }
    let(:file_store_path) {
      File.join(store.description_path(test_name), file_store_name)
    }

    describe "#initialize_file_store" do
      it "creates a directory in the description directory" do
        expect(Dir.exists?(file_store_path)).to be(false)
        store.initialize_file_store(test_name, file_store_name)
        expect(Dir.exists?(file_store_path)).to be(true)
      end

      it "creates a directory with the parent directory  permissions" do
        expect(File.stat(File.dirname(file_store_path)).mode & 0777).to eq(0700)
        store.initialize_file_store(test_name, file_store_name)
        expect(File.stat(file_store_path).mode & 0777).to eq(0700)

        store.remove_file_store(test_name, file_store_name)
        File.chmod(0755, store.description_path(test_name))
        store.initialize_file_store(test_name, file_store_name)
        expect(File.stat(file_store_path).mode & 0777).to eq(0755)
      end
    end

    describe "#remove_file_store" do
      it "removes the file store dir" do
        store.initialize_file_store(test_name, file_store_name)
        expect(Dir.exists?(file_store_path)).to be(true)
        store.remove_file_store(test_name, file_store_name)
        expect(Dir.exists?(file_store_path)).to be(false)
      end

      it "doesn't throw an error if the dir doesn't exist" do
        expect(Dir.exists?(file_store_path)).to be(false)
        expect { store.remove_file_store(test_name, file_store_name) }.not_to raise_error
      end
    end

    describe "#file_store" do
      it "returns the path to the file store dir" do
        store.initialize_file_store(test_name, file_store_name)
        expect(store.file_store(test_name, file_store_name)).to eq(file_store_path)
      end

      it "returns nil if the file store does not exist" do
        expect(store.file_store(test_name, file_store_name)).to be_nil
      end
    end

    describe "#create_file_store_sub_dir" do
      let(:sub_dir) { "foo/bar" }
      let(:sub_dir_path) { File.join(file_store_path, sub_dir) }

      it "creates a directory in the file store" do
        store.initialize_file_store(test_name, file_store_name)
        expect(Dir.exists?(sub_dir_path)).to be(false)
        store.create_file_store_sub_dir(test_name, file_store_name, sub_dir)
        expect(Dir.exists?(sub_dir_path)).to be(true)
      end

      it "preserves the parent directory permissions" do
        store.initialize_file_store(test_name, file_store_name)
        store.create_file_store_sub_dir(test_name, file_store_name, sub_dir)
        expect(File.stat(sub_dir_path).mode & 0777).to eq(0700)

        store.remove_file_store(test_name, file_store_name)
        File.chmod(0755, store.description_path(test_name))
        store.initialize_file_store(test_name, file_store_name)
        store.create_file_store_sub_dir(test_name, file_store_name, sub_dir)
        expect(File.stat(sub_dir_path).mode & 0777).to eq(0755)
      end
    end

    describe "#new_dir_mode" do
      it "returns the mode of the system description directory" do
        expect(store.new_dir_mode(test_name)).to eq(0700)

        File.chmod(0755, store.description_path(test_name))
        expect(store.new_dir_mode(test_name)).to eq(0755)
      end

      it "returns the default of 0700 if the description directory is missing" do
        store.remove(test_name)
        expect(Dir.exists?(store.description_path(test_name))).to be(false)
        expect(store.new_dir_mode(test_name)).to eq(0700)
      end
    end
  end
end
