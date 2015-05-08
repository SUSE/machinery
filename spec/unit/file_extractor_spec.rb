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

describe FileExtractor do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  let(:system) { double }
  let(:scope_file_store) {
    store = ScopeFileStore.new(given_directory, "scope")
    store.create

    store
  }
  subject { FileExtractor.new(system, scope_file_store) }

  describe "extract_files" do
    it "creates a files tarball in the scope file store" do
      expect(system).to receive(:create_archive) do |_files, archive_path, _excluded|
        FileUtils.touch(archive_path)
      end

      subject.extract_files(["/foo", "/bar"], ["/exclude"])
      expect(File.exists?(File.join(scope_file_store.path, "files.tgz"))).to be(true)
    end

    it "create tree tarballs in the scope file store" do
      expect(system).to receive(:create_archive) do |_files, archive_path, _excluded|
        FileUtils.touch(archive_path)
      end.at_least(:once)

      subject.extract_trees(["/opt", "/foo/bar"], ["/exclude"])
      expect(File.exists?(File.join(scope_file_store.path, "trees", "opt.tgz"))).to be(true)
      expect(File.exists?(File.join(scope_file_store.path, "trees", "foo/bar.tgz"))).to be(true)
    end
  end
end
