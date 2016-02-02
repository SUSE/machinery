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

describe ScopeFileStore do
  include GivenFilesystemSpecHelpers

  use_given_filesystem

  before(:each) do
    @base_path = given_directory
    File.chmod(0700, @base_path)
    @store_name = "bar"
    @file_store_path = File.join(@base_path, @store_name)
    @store = ScopeFileStore.new(@base_path, @store_name)
  end

  let(:store) { SystemDescriptionStore.new(test_base_path) }
  let(:file_store_name) { "foo" }
  let(:file_store_path) {
    File.join(store.description_path(test_name), file_store_name)
  }

  describe "#create" do
    it "creates a directory in the description directory" do
      expect(Dir.exists?(@file_store_path)).to be(false)
      @store.create
      expect(Dir.exists?(@file_store_path)).to be(true)
    end

    it "creates a directory with the parent directory  permissions" do
      expect(File.stat(File.dirname(@file_store_path)).mode & 0777).to eq(0700)
      @store.create
      expect(File.stat(@file_store_path).mode & 0777).to eq(0700)

      @store.remove
      File.chmod(0755, @base_path)
      @store.create
      expect(File.stat(@file_store_path).mode & 0777).to eq(0755)
    end
  end

  describe "#remove" do
    it "removes the file store dir" do
      @store.create
      expect(Dir.exists?(@file_store_path)).to be(true)

      @store.remove
      expect(Dir.exists?(@file_store_path)).to be(false)
    end

    it "doesn't throw an error if the dir doesn't exist" do
      expect(Dir.exists?(@file_store_path)).to be(false)
      expect {
        @store.remove
      }.not_to raise_error
    end
  end

  describe "#rename" do
    it "renames the file store dir" do
      file_store_name_new = "foo"
      file_store_path_new =
        File.join(@base_path, file_store_name_new)

      @store.create
      expect(Dir.exists?(@file_store_path)).to be(true)
      expect(Dir.exists?(file_store_path_new)).to be(false)

      @store.rename(file_store_name_new)
      expect(Dir.exists?(@file_store_path)).to be(false)
      expect(Dir.exists?(file_store_path_new)).to be(true)
    end
  end

  describe "#path" do
    it "returns the path to the file store dir" do
      @store.create
      expect(@store.path).to eq(@file_store_path)
    end

    it "returns nil if the file store does not exist" do
      expect(Dir.exists?(@file_store_path)).to be(false)
      expect(@store.path).to be_nil
    end
  end

  describe "#create_sub_directory" do
    let(:sub_dir) { "foo/bar" }
    let(:sub_dir_path) { File.join(@file_store_path, sub_dir) }

    it "creates a directory in the file store" do
      @store.create
      expect(Dir.exists?(sub_dir_path)).to be(false)

      @store.create_sub_directory(sub_dir)
      expect(Dir.exists?(sub_dir_path)).to be(true)
    end

    it "preserves the parent directory permissions" do
      @store.create
      @store.create_sub_directory(sub_dir)
      expect(File.stat(sub_dir_path).mode & 0777).to eq(0700)

      @store.remove
      File.chmod(0755, @base_path)
      @store.create
      @store.create_sub_directory(sub_dir)
      expect(File.stat(sub_dir_path).mode & 0777).to eq(0755)
    end
  end

  describe "#new_dir_mode" do
    it "returns the mode of the system description directory" do
      expect(@store.new_dir_mode).to eq(0700)

      File.chmod(0755, @base_path)
      expect(@store.new_dir_mode).to eq(0755)
    end

    it "returns the default of 0700 if the description directory is missing" do
      @store.remove
      expect(Dir.exists?(@file_store_path)).to be(false)
      expect(@store.new_dir_mode).to eq(0700)
    end
  end

  describe "#list_content" do
    it "returns a list of files and dirs in the file store" do
      @store.create
      @store.create_sub_directory("foo/bar")
      @store.create_sub_directory("foo/.qux")
      FileUtils.touch(File.join(@file_store_path, "foo", "baz"))
      FileUtils.touch(File.join(@file_store_path, "foo", ".baz"))
      FileUtils.touch(File.join(@file_store_path, "foo", ".qux", "quux"))

      expect(@store.list_content).to match_array(
        [
          File.join(@file_store_path, "foo", "bar"),
          File.join(@file_store_path, "foo", "baz"),
          File.join(@file_store_path, "foo", ".baz"),
          File.join(@file_store_path, "foo", ".qux", "quux")
        ]
      )
    end
  end
end
