# frozen_string_literal: true
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

describe StaticHtml do
  capture_machinery_output
  initialize_system_description_factory_store

  around(:each) do |test|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = tmp_dir
      test.run
    end
  end

  let(:description) {
    create_test_description(
      store_on_disk: true,
      extracted_scopes: [
        "changed_config_files",
        "changed_managed_files",
        "unmanaged_files"
      ],
      scopes: [
        "os",
        "packages",
        "patterns",
        "repositories",
        "users_with_passwords",
        "groups",
        "services"
      ],
      with_diffs: true
    )
  }

  describe "#initialize" do
    it "initializes without error" do
      expect { StaticHtml.new(description, "/tmp") }.not_to raise_error
    end
  end

  describe "#write" do
    it "renders an HTML report" do
      static_html = StaticHtml.new(description, @tmp_dir)
      static_html.write
      index_file = File.join(@tmp_dir, "index.html")
      expect(File.readable?(index_file)).to be_truthy
      expect(File.read(index_file)).to include("<html", "openSUSE")
      expect(File.read(index_file)).to include("diff-toggle")
      expect(File.read(index_file)).not_to include(
        "modal-footer",
        "description-selector-label",
        "open-description-selector",
        "file-download"
      )
    end

    it "copies the assets over" do
      StaticHtml.new(description, @tmp_dir).write
      expect(Dir.exist?(File.join(@tmp_dir, "assets"))).to be(true)
    end

    it "does not copy the compare asset over" do
      StaticHtml.new(description, @tmp_dir).write
      expect(Dir.exist?(File.join(@tmp_dir, "assets", "compare"))).to be(false)
    end
  end

  describe "#create_directory" do
    it "raises an exception if dir exists and not forcing" do
      static_html = StaticHtml.new(description, @tmp_dir)
      expect {
        static_html.create_directory(false)
      }.to raise_error(Machinery::Errors::ExportFailed)
    end

    it "removes directory and creates new one if forcing" do
      static_html = StaticHtml.new(description, @tmp_dir)
      existing_file = File.join(@tmp_dir, "test")
      FileUtils.touch(existing_file)
      expect {
        static_html.create_directory(true)
      }.not_to raise_error
      expect(File.readable?(existing_file)).to be_falsy
    end

    it "creates a new directory" do
      static_html = StaticHtml.new(description, @tmp_dir)
      Dir.rmdir(@tmp_dir)
      static_html.create_directory(false)
      expect(File.directory?(@tmp_dir)).to be_truthy
    end
  end
end
